import Foundation

/// An in-memory buffer.
public struct BinaryBuffer {

  /// The contents of the buffer.
  private var contents: [UInt8]

  /// Creates an empty buffer.
  public init() {
    self.contents = []
  }

  /// Writes the contents of this buffer to `target`.
  public func write(into target: URL) throws {
    try contents.withUnsafeBytes({ (bytes) in
      let d = Data(
        bytesNoCopy: .init(mutating: bytes.baseAddress!),
        count: bytes.count,
        deallocator: .none)
      try d.write(to: target)
    })
  }

}

extension BinaryBuffer: Hashable {}

extension BinaryBuffer: BinaryOutputStream {

  /// Appends the given byte to the stream.
  public mutating func write(_ byte: UInt8) {
    contents.append(byte)
  }

}

extension BinaryBuffer: Collection {

  public typealias Element = UInt8

  public typealias Index = Int

  public var startIndex: Int { 0 }

  public var endIndex: Int { contents.count }

  public func index(after i: Int) -> Int { i + 1 }

  public subscript(i: Int) -> UInt8 { contents[i] }

}

extension BinaryBuffer: LosslessStringConvertible {

  /// Creates an instance with the contents `hex`, which is a sequence of hexadecimal bytes.
  public init?(_ hex: String) {
    self.init()
    var input = hex[...]
    while !input.isEmpty {
      if let (h, t) = input.split(after: 2), let b = UInt8(h, radix: 16) {
        contents.append(b)
        input = t
      } else {
        return nil
      }
    }
  }

  public var description: String {
    contents.lazy.map(Self.hex(_:)).joined()
  }

  private static func hex(_ b: UInt8) -> String {
    let h = String(b, radix: 16)
    return h.count == 2 ? h : ("0" + h)
  }

}

extension StringProtocol {

  /// Returns `self` split after `n` elements or `nil` if the length of `self` is shorter than `n`.
  fileprivate func split(after n: Int) -> (head: Self.SubSequence, tail: Self.SubSequence)? {
    var i = startIndex
    if i == endIndex { return nil }
    i = index(after: i)
    if i == endIndex { return nil }
    i = index(after: i)
    return (head: self[..<i], tail: self[i...])
  }

}
