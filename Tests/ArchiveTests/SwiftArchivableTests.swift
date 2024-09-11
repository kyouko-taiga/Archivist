import Archivist
import XCTest

final class SwiftArchivableTests: XCTestCase {

  func testBool() throws {
    var w = WriteableArchive(BinaryBuffer())
    try w.write(false)
    try w.write(true)

    var r = ReadableArchive(w.finalize())
    XCTAssertEqual(try r.read(Bool.self), false)
    XCTAssertEqual(try r.read(Bool.self), true)
    XCTAssertThrowsError(try r.readByte())
  }

  func testInteger() throws {
    var w = WriteableArchive(BinaryBuffer())
    try w.write(11 as UInt32)
    try w.write(-8 as Int16)

    var r = ReadableArchive(w.finalize())
    XCTAssertEqual(try r.read(UInt32.self), 11)
    XCTAssertEqual(try r.read(Int16.self), -8)
    XCTAssertThrowsError(try r.readByte())
  }

  func testFloatingPoint() throws {
    var w = WriteableArchive(BinaryBuffer())
    try w.write(4.2 as Double)
    try w.write(2.4 as Float)

    var r = ReadableArchive(w.finalize())
    XCTAssertEqual(try r.read(Double.self), 4.2)
    XCTAssertEqual(try r.read(Float.self), 2.4)
    XCTAssertThrowsError(try r.readByte())
  }

  func testString() throws {
    var w = WriteableArchive(BinaryBuffer())
    try w.write("Hello, World!")
    try w.write("\u{3042}")

    var r = ReadableArchive(w.finalize())
    XCTAssertEqual(try r.read(String.self), "Hello, World!")
    XCTAssertEqual(try r.read(String.self), "\u{3042}")
    XCTAssertThrowsError(try r.readByte())
  }

  func testOptional() throws {
    var w = WriteableArchive(BinaryBuffer())
    try w.write(123 as Int?)
    try w.write(nil as Int?)

    var r = ReadableArchive(w.finalize())
    XCTAssertEqual(try r.read(Int?.self), 123)
    XCTAssertEqual(try r.read(Int?.self), nil)
    XCTAssertThrowsError(try r.readByte())
  }

  func testArray() throws {
    var w = WriteableArchive(BinaryBuffer())
    try w.write([Int]())
    try w.write(["ab", "cd", "ef"])

    var r = ReadableArchive(w.finalize())
    XCTAssertEqual(try r.read([Int].self), [])
    XCTAssertEqual(try r.read([String].self), ["ab", "cd", "ef"])
    XCTAssertThrowsError(try r.readByte())
  }

  func testDictionary() throws {
    var w = WriteableArchive(BinaryBuffer())
    try w.write([Int: String]())
    try w.write([1: "ab", 2: "cd", 3: "ef"])

    var r = ReadableArchive(w.finalize())
    XCTAssertEqual(try r.read([Int: String].self), [:])
    XCTAssertEqual(try r.read([Int: String].self), [1: "ab", 2: "cd", 3: "ef"])
    XCTAssertThrowsError(try r.readByte())
  }

  func testSet() throws {
    var w = WriteableArchive(BinaryBuffer())
    try w.write(Set<Int>())
    try w.write(Set(["ab", "cd", "ef"]))

    var r = ReadableArchive(w.finalize())
    XCTAssertEqual(try r.read(Set<Int>.self), [])
    XCTAssertEqual(try r.read(Set<String>.self), ["ab", "cd", "ef"])
    XCTAssertThrowsError(try r.readByte())
  }

}
