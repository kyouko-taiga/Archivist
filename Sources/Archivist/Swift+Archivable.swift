extension Bool: Archivable {

  /// Reads `self` from `archive`.
  public init?<T>(from archive: inout ReadableArchive<T>, in _: inout Any) {
    switch archive.readByte() {
    case .some(0): self = false
    case .some(1): self = true
    default: return nil
    }
  }

  /// Writes `self` to `archive`.
  public func write<T>(to archive: inout WriteableArchive<T>, in _: inout Any) {
    archive.write(byte: self ? 1 : 0)
  }

}

extension FixedWidthInteger where Self: UnsignedInteger {

  /// Reads `self` from `archive` as a LEB128 integer.
  public init?<T>(from archive: inout ReadableArchive<T>, in _: inout Any) {
    guard let v = archive.readUnsignedLEB128(as: Self.self) else { return nil }
    self = v
  }

  /// Writes `self` to `archive` as a LEB128 integer.
  public func write<T>(to archive: inout WriteableArchive<T>, in _: inout Any) {
    archive.write(unsignedLEB128: self)
  }

}

extension FixedWidthInteger where Self: SignedInteger {

  /// Reads `self` from `archive` as a LEB128 integer.
  public init?<T>(from archive: inout ReadableArchive<T>, in _: inout Any) {
    guard let v = archive.readSignedLEB128(as: Self.self) else { return nil }
    self = v
  }

  /// Writes `self` to `archive` as a LEB128 integer.
  public func write<T>(to archive: inout WriteableArchive<T>, in _: inout Any) {
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
  public init?<T>(from archive: inout ReadableArchive<T>, in _: inout Any) {
    guard let v = archive.read(Self.self, endianness: .little) else { return nil }
    self = v
  }

  /// Writes `self` to `archive` in little endian.
  public func write<T>(to archive: inout WriteableArchive<T>, in _: inout Any) {
    archive.write(self, endianness: .little)
  }

}

extension Float16: Archivable {}
extension Float32: Archivable {}
extension Float64: Archivable {}

extension String: Archivable {

  /// Reads `self` from `archive`.
  public init?<T>(from archive: inout ReadableArchive<T>, in _: inout Any) {
    guard
      let count = archive.readUnsignedLEB128().map(Int.init(_:)),
      let s = withUnsafeTemporaryAllocation(
        byteCount: count, alignment: 1, { (ut8) in Self.read(from: &archive, to: ut8) })
    else { return nil }
    self = s
  }

  /// Writes `self` to `archive`.
  public func write<T>(to archive: inout WriteableArchive<T>, in _: inout Any) {
    archive.write(unsignedLEB128: UInt(utf8.count))
    for b in utf8 { archive.write(byte: b) }
  }

  /// Copy `utf8.count` bytes from `archive` to `utf8`.
  private static func read<T>(
    from archive: inout ReadableArchive<T>, to utf8: UnsafeMutableRawBufferPointer
  ) -> String? {
    var n = 0
    while n < utf8.count {
      guard let b = archive.readByte() else { return nil }
      utf8[n] = b
      n += 1
    }
    return String(bytes: utf8, encoding: .utf8)
  }

}

extension Optional: Archivable where Wrapped: Archivable {

  /// Reads `self` from `archive`, updating `context` with the deserialization state.
  public init?<T>(from archive: inout ReadableArchive<T>, in context: inout Any) {
    guard let present = archive.read(Bool.self) else { return nil }
    if present {
      guard let w = Wrapped(from: &archive, in: &context) else { return nil }
      self = w
    } else {
      self = nil
    }
  }

  /// Writes `self` to `archive`, updating `context` with the serialization state.
  public func write<T>(to archive: inout WriteableArchive<T>, in context: inout Any) {
    if let w = self {
      archive.write(true, in: &context)
      archive.write(w, in: &context)
    } else {
      archive.write(false, in: &context)
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
  public init?<T>(from archive: inout ReadableArchive<T>, in context: inout Any) {
    guard let count = archive.readUnsignedLEB128().map(Int.init(_:)) else { return nil }
    self.init()
    reserveCapacity(count)
    while self.count < count {
      guard let e = Element(from: &archive, in: &context) else { return nil }
      append(e)
    }
  }

  /// Writes `self` to `archive`, updating `context` with the serialization state.
  public func write<T>(to archive: inout WriteableArchive<T>, in context: inout Any) {
    write(to: &archive, writingElementsWith: { (e, a) in e.write(to: &a, in: &context) })
  }

}

extension Dictionary: Archivable where Key: Archivable, Value: Archivable {

  /// Reads `self` from `archive`, updating `context` with the deserialization state.
  public init?<T>(from archive: inout ReadableArchive<T>, in context: inout Any) {
    guard let count = archive.readUnsignedLEB128().map(Int.init(_:)) else { return nil }
    self.init()
    reserveCapacity(count)
    while self.count < count {
      guard
        let k = Key(from: &archive, in: &context),
        let v = Value(from: &archive, in: &context)
      else { return nil }
      self[k] = v
    }
  }

  /// Writes `self` to `archive`, updating `context` with the serialization state.
  public func write<T>(to archive: inout WriteableArchive<T>, in context: inout Any) {
    write(to: &archive) { (e, a) in
      e.key.write(to: &a, in: &context)
      e.value.write(to: &a, in: &context)
    }
  }

}

extension Set: Archivable where Element: Archivable {

  /// Reads `self` from `archive`, updating `context` with the deserialization state.
  public init?<T>(from archive: inout ReadableArchive<T>, in context: inout Any) {
    guard let count = archive.readUnsignedLEB128().map(Int.init(_:)) else { return nil }
    self.init()
    reserveCapacity(count)
    while self.count < count {
      guard let e = Element(from: &archive, in: &context) else { return nil }
      insert(e)
    }
  }

  /// Writes `self` to `archive`, updating `context` with the serialization state.
  public func write<T>(to archive: inout WriteableArchive<T>, in context: inout Any) {
    write(to: &archive, writingElementsWith: { (e, a) in e.write(to: &a, in: &context) })
  }

}
