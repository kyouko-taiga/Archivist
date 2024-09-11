extension Bool: Archivable {

  /// Reads `self` from `archive`.
  public init<T>(from archive: inout ReadableArchive<T>, in _: inout Any) throws {
    switch try archive.readByte() {
    case 0: self = false
    case 1: self = true
    default: throw ArchiveError.invalidInput
    }
  }

  /// Writes `self` to `archive`.
  public func write<T>(to archive: inout WriteableArchive<T>, in _: inout Any) {
    archive.write(byte: self ? 1 : 0)
  }

}

extension FixedWidthInteger where Self: UnsignedInteger {

  /// Reads `self` from `archive` as a LEB128 integer.
  public init<T>(from archive: inout ReadableArchive<T>, in _: inout Any) throws {
    self = try archive.readUnsignedLEB128(as: Self.self)
  }

  /// Writes `self` to `archive` as a LEB128 integer.
  public func write<T>(to archive: inout WriteableArchive<T>, in _: inout Any) throws {
    archive.write(unsignedLEB128: self)
  }

}

extension FixedWidthInteger where Self: SignedInteger {

  /// Reads `self` from `archive` as a LEB128 integer.
  public init<T>(from archive: inout ReadableArchive<T>, in _: inout Any) throws {
    self = try archive.readSignedLEB128(as: Self.self)
  }

  /// Writes `self` to `archive` as a LEB128 integer.
  public func write<T>(to archive: inout WriteableArchive<T>, in _: inout Any) throws {
    archive.write(signedLEB128: self)
  }

}

extension Int8: Archivable {}
extension UInt8: Archivable {}
extension Int16: Archivable {}
extension UInt16: Archivable {}
extension Int32: Archivable {}
extension UInt32: Archivable {}
extension Int64: Archivable {}
extension UInt64: Archivable {}
extension Int: Archivable {}
extension UInt: Archivable {}

extension BinaryFloatingPoint {

  /// Reads `self` from `archive`, assuming a little-endian representation.
  public init<T>(from archive: inout ReadableArchive<T>, in _: inout Any) throws {
    self = try archive.read(Self.self, endianness: .little)
  }

  /// Writes `self` to `archive` in little endian.
  public func write<T>(to archive: inout WriteableArchive<T>, in _: inout Any) throws {
    archive.write(self, endianness: .little)
  }

}

extension Float16: Archivable {}
extension Float32: Archivable {}
extension Float64: Archivable {}

extension String: Archivable {

  /// Reads `self` from `archive`.
  public init<T>(from archive: inout ReadableArchive<T>, in _: inout Any) throws {
    let c = try Int(archive.readUnsignedLEB128())
    let s = try withUnsafeTemporaryAllocation(
      byteCount: c, alignment: 1, { (utf8) in try Self.read(from: &archive, to: utf8) })
    self = s
  }

  /// Writes `self` to `archive`.
  public func write<T>(to archive: inout WriteableArchive<T>, in _: inout Any) throws {
    archive.write(unsignedLEB128: UInt(utf8.count))
    for b in utf8 { archive.write(byte: b) }
  }

  /// Copy `utf8.count` bytes from `archive` to `utf8`.
  private static func read<T>(
    from archive: inout ReadableArchive<T>, to utf8: UnsafeMutableRawBufferPointer
  ) throws -> String {
    var n = 0
    while n < utf8.count {
      utf8[n] = try archive.readByte()
      n += 1
    }
    if let s = String(bytes: utf8, encoding: .utf8) {
      return s
    } else {
      throw ArchiveError.invalidInput
    }
  }

}

extension Optional: Archivable where Wrapped: Archivable {

  /// Reads `self` from `archive`, updating `context` with the deserialization state.
  public init<T>(from archive: inout ReadableArchive<T>, in context: inout Any) throws {
    self = try archive.read(Bool.self) ? Wrapped(from: &archive, in: &context) : nil
  }

  /// Writes `self` to `archive`, updating `context` with the serialization state.
  public func write<T>(to archive: inout WriteableArchive<T>, in context: inout Any) throws {
    if let w = self {
      try archive.write(true, in: &context)
      try archive.write(w, in: &context)
    } else {
      try archive.write(false, in: &context)
    }
  }

}

extension Collection {

  /// Writes `self` to `archive`.
  public func write<T>(
    to archive: inout WriteableArchive<T>,
    writingElementsWith writeElement: (Element, inout WriteableArchive<T>) throws -> Void
  ) rethrows {
    archive.write(unsignedLEB128: UInt(count))
    for e in self {
      try writeElement(e, &archive)
    }
  }

}

extension Array: Archivable where Element: Archivable {

  /// Reads `self` from `archive`, updating `context` with the deserialization state.
  public init<T>(from archive: inout ReadableArchive<T>, in context: inout Any) throws {
    let count = try Int(archive.readUnsignedLEB128())
    self.init()
    reserveCapacity(count)
    while self.count < count {
      try append(Element(from: &archive, in: &context))
    }
  }

  /// Writes `self` to `archive`, updating `context` with the serialization state.
  public func write<T>(to archive: inout WriteableArchive<T>, in context: inout Any) throws {
    try write(to: &archive, writingElementsWith: { (e, a) in try e.write(to: &a, in: &context) })
  }

}

extension Dictionary: Archivable where Key: Archivable, Value: Archivable {

  /// Reads `self` from `archive`, updating `context` with the deserialization state.
  public init<T>(from archive: inout ReadableArchive<T>, in context: inout Any) throws {
    let count = try Int(archive.readUnsignedLEB128())
    self.init()
    reserveCapacity(count)
    while self.count < count {
      let k = try Key(from: &archive, in: &context)
      let v = try Value(from: &archive, in: &context)
      self[k] = v
    }
  }

  /// Writes `self` to `archive`, updating `context` with the serialization state.
  public func write<T>(to archive: inout WriteableArchive<T>, in context: inout Any) throws {
    try write(to: &archive) { (e, a) in
      try e.key.write(to: &a, in: &context)
      try e.value.write(to: &a, in: &context)
    }
  }

}

extension Set: Archivable where Element: Archivable {

  /// Reads `self` from `archive`, updating `context` with the deserialization state.
  public init<T>(from archive: inout ReadableArchive<T>, in context: inout Any) throws {
    let count = try Int(archive.readUnsignedLEB128())
    self.init()
    reserveCapacity(count)
    while self.count < count {
      try insert(Element(from: &archive, in: &context))
    }
  }

  /// Writes `self` to `archive`, updating `context` with the serialization state.
  public func write<T>(to archive: inout WriteableArchive<T>, in context: inout Any) throws {
    try write(to: &archive, writingElementsWith: { (e, a) in try e.write(to: &a, in: &context) })
  }

}
