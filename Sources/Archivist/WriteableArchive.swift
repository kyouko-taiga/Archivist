/// A general-purpose adapter to write data to a binary archive.
public struct WriteableArchive<Archive: BinaryOutputStream> {

  /// The stream to which data is written.
  private var archive: Archive

  /// Creates an instance writing data to `archive`.
  public init(_ archive: Archive) {
    self.archive = archive
  }

  /// Releases the archive to which data has been written.
  public consuming func finalize() -> Archive {
    self.archive
  }

  /// Writes `value` to the archive, updating `context` with the serialization state.
  public mutating func write<T: Archivable>(_ value: T, in context: inout Any) {
    value.write(to: &self, in: &context)
  }

  /// Writes `value` to the archive without any context.
  public mutating func write<T: Archivable>(_ value: T) {
    var empty: Any = ()
    write(value, in: &empty)
  }

  /// Writes a byte to the archive.
  public mutating func write(byte value: UInt8) {
    archive.write(value)
  }

  /// Writes an integer to the archive with the given `endianness`.
  public mutating func write<T: FixedWidthInteger>(
    _ value: T, endianness: Endianness = .little
  ) {
    switch endianness {
    case .little:
      write(bytesOf: value.littleEndian)
    case .big:
      write(bytesOf: value.bigEndian)
    }
  }

  /// Writes a floating-point number to the archive with the given `endianness`.
  public mutating func write<T: BinaryFloatingPoint>(
    _ value: T, endianness: Endianness = .little
  ) {
    write(bytesOf: value, endianness: endianness)
  }

  /// Writes an unsigned integer encoded as a LEB128 value to the archive.
  public mutating func write<T: FixedWidthInteger>(unsignedLEB128 value: T) {
    precondition(value >= 0)
    var i = value
    repeat {
      var b = UInt8(i & 0x7f)
      i >>= 7
      if i != 0 { b |= 0x80 }
      archive.write(b)
    } while i != 0
  }

  /// Writes a signed integer encoded as a LEB128 value to the archive.
  public mutating func write<T: FixedWidthInteger>(signedLEB128 value: T) {
    var i = value
    while true {
      let b = UInt8(i & 0x7f)
      i >>= 7  // arithmetic shift
      if (((i == 0) && ((b & 0x40) == 0)) || ((i == -1) && ((b & 0x40) != 0))) {
        archive.write(b)
        return
      } else {
        archive.write(b | 0x80)
      }
    }
  }

  /// Writes the byte representation of `value` to the archive with the given `endianness`.
  public mutating func write<T>(bytesOf value: T, endianness: Endianness = .little) {
    withUnsafeBytes(of: value) { (bytes) in
      if endianness == .host {
        for b in bytes { archive.write(b) }
      } else {
        for b in bytes.reversed() { archive.write(b) }
      }
    }
  }

}
