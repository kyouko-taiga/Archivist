/// A type that can be target of binary-streaming operations.
public protocol BinaryOutputStream {

  /// Appends the given byte to the stream.
  mutating func write(_ byte: UInt8)

}
