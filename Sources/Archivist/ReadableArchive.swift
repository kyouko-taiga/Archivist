/// A general-purpose adapter to read data from a binary archive.
public struct ReadableArchive<Archive: Sequence<UInt8>> {

  /// The stream to which data is written.
  private var archive: Archive.Iterator

  /// Creates an instance reading data from `archive`.
  public init(_ archive: Archive) {
    self.archive = archive.makeIterator()
  }

  /// Reads an instance of `T` from the archive, updating `context` with the deserialization state.
  public mutating func read<T: Archivable>(_: T.Type, in context: inout Any) throws -> T {
    try T(from: &self, in: &context)
  }

  /// Reads an instance of `T` from the archive without any context.
  public mutating func read<T: Archivable>(_ result: T.Type) throws -> T {
    var empty: Any = ()
    return try read(result, in: &empty)
  }

  /// Reads an instance of `T` from the archive, updating `context` with the deserialization state.
  public mutating func read<T: RawRepresentable>(
    rawValueOf _: T.Type, in context: inout Any
  ) throws -> T? where T.RawValue: Archivable {
    let raw = try T.RawValue(from: &self, in: &context)
    return T(rawValue: raw)
  }

  /// Reads an instance of `T` from the archive without any context.
  public mutating func read<T: RawRepresentable>(
    rawValueOf _: T.Type
  ) throws -> T? where T.RawValue: Archivable {
    var empty: Any = ()
    return try read(rawValueOf: T.self, in: &empty)
  }

  /// Reads a byte from the archive.
  public mutating func readByte() throws -> UInt8 {
    if let b = archive.next() { b } else { throw ArchiveError.emptyInput }
  }

  /// Reads an integer from the archive with the given `endianness`.
  public mutating func read<T: FixedWidthInteger>(
    _: T.Type, endianness: Endianness = .little
  ) throws -> T {
    try withUnsafeBytes(of: T.self, withEndianness: endianness, { (bytes) in bytes.pointee })
  }

  /// Reads a floating-point number from the archive with the given `endianness`.
  public mutating func read<T: BinaryFloatingPoint>(
    _: T.Type, endianness: Endianness = .little
  ) throws -> T {
    try withUnsafeBytes(of: T.self, withEndianness: endianness, { (bytes) in bytes.pointee })
  }

  /// Reads an unsigned integer encoded as a LEB128 value from the archive.
  public mutating func readUnsignedLEB128<T: FixedWidthInteger & UnsignedInteger>(
    as: T.Type = UInt.self
  ) throws -> T {
    var r = T.zero
    var s = T.zero
    while true {
      let b = try readByte()
      let slice = T(b) & 0x7f

      if
        (s == (T.bitWidth - 1) && ((slice << s) >> s) != slice) ||
        (s >= T.bitWidth && slice != 0)
      { throw ArchiveError.invalidInput }

      r += slice << s
      if (b >> 7) == 0 { return r }
      s += 7
    }
  }

  /// Appends a signed integer encoded as a LEB128 value to the archive.
  public mutating func readSignedLEB128<T: FixedWidthInteger & SignedInteger>(
    as: T.Type = Int.self
  ) throws -> T {
    var r = T.zero
    var s = T.zero
    while true {
      let b = try readByte()
      let slice = T(b) & 0x7f

      if
        (s == (T.bitWidth - 1) && slice != 0 && slice != 0x7f) ||
        (s >= T.bitWidth && slice != (r < 0 ? 0x7f : 0x00))
      { throw ArchiveError.invalidInput }

      r |= slice << s
      s += 7

      if (b & 0x80) == 0 {
        if (s < T.bitWidth) && ((b & 0x40) != 0) {
          return r | (~0 << s)
        } else {
          return r
        }
      }
    }
  }

  /// Returns the result of `action` applied on a buffer containing the bytes of an instance of `T`
  /// read from the archive or `nil` if the archive does not contain enough bytes.
  public mutating func withUnsafeBytes<T, U>(
    of _: T.Type, withEndianness endianness: Endianness,
    _ action: (UnsafeMutablePointer<T>) throws -> U
  ) throws -> U {
    try withUnsafeTemporaryAllocation(of: T.self, capacity: 1) { (alloca) in
      try alloca.withMemoryRebound(to: UInt8.self) { (target) throws -> Void in
        for n in 0 ..< target.count {
          let b = try readByte()
          if endianness == .host {
            target[n] = b
          } else {
            target[target.count - n - 1] = b
          }
        }
      }
      return try action(alloca.baseAddress!)
    }
  }

}
