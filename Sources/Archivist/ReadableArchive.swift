/// A general-purpose adapter to read data from a binary archive.
public struct ReadableArchive<Archive: Sequence<UInt8>> {

  /// The stream to which data is written.
  private var archive: Archive.Iterator

  /// Creates an instance reading data from `archive`.
  public init(_ archive: Archive) {
    self.archive = archive.makeIterator()
  }

  /// Reads an instance of `T` from the archive, updating `context` with the deserialization state.
  public mutating func read<T: Archivable>(_: T.Type, in context: inout Any) -> T? {
    T.init(from: &self, in: &context)
  }

  /// Reads an instance of `T` from the archive without any context.
  public mutating func read<T: Archivable>(_ result: T.Type) -> T? {
    var empty: Any = ()
    return read(result, in: &empty)
  }

  /// Reads a byte from the archive.
  public mutating func readByte() -> UInt8? {
    archive.next()
  }

  /// Reads an integer from the archive with the given `endianness`.
  public mutating func read<T: FixedWidthInteger>(
    _: T.Type, endianness: Endianness = .little
  ) -> T? {
    withUnsafeBytes(of: T.self, withEndianness: endianness, { (bytes) in bytes.pointee })
  }

  /// Reads a floating-point number from the archive with the given `endianness`.
  public mutating func read<T: BinaryFloatingPoint>(
    _: T.Type, endianness: Endianness = .little
  ) -> T? {
    withUnsafeBytes(of: T.self, withEndianness: endianness, { (bytes) in bytes.pointee })
  }

  /// Reads an unsigned integer encoded as a LEB128 value from the archive.
  public mutating func readUnsignedLEB128<T: FixedWidthInteger & UnsignedInteger>(
    as: T.Type = UInt.self
  ) -> T? {
    var r = T.zero
    var s = T.zero
    while true {
      guard let b = archive.next() else { return nil }
      let slice = T(b) & 0x7f

      if
        (s == (T.bitWidth - 1) && ((slice << s) >> s) != slice) ||
        (s >= T.bitWidth && slice != 0)
      { return nil }

      r += slice << s
      if (b >> 7) == 0 { return r }
      s += 7
    }
  }

  /// Appends a signed integer encoded as a LEB128 value to the archive.
  public mutating func readSignedLEB128<T: FixedWidthInteger & SignedInteger>(
    as: T.Type = Int.self
  ) -> T? {
    var r = T.zero
    var s = T.zero
    while true {
      guard let b = archive.next() else { return nil }
      let slice = T(b) & 0x7f

      if
        (s == (T.bitWidth - 1) && slice != 0 && slice != 0x7f) ||
        (s >= T.bitWidth && slice != (r < 0 ? 0x7f : 0x00))
      { return nil }

      r |= slice << s
      s += 7

      if ((b & 0x80) >> 7) == 0 {
        if (s < 64) && ((b & 0x40) != 0) {
          return r | -(1 << s)
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
    _ action: (UnsafeMutablePointer<T>) -> U
  ) -> U? {
    withUnsafeTemporaryAllocation(of: T.self, capacity: 1) { (alloca) in
      let initialized = alloca.withMemoryRebound(to: UInt8.self) { (target) -> Bool in
        for n in 0 ..< target.count {
          guard let b = archive.next() else { return false }
          if endianness == .host {
            target[n] = b
          } else {
            target[target.count - n - 1] = b
          }
        }
        return true
      }
      return initialized ? action(alloca.baseAddress!) : nil
    }
  }

}
