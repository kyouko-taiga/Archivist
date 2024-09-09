import Archivist
import XCTest

final class SwiftArchivableTests: XCTestCase {

  func testBool() {
    var w = WriteableArchive(BinaryBuffer())
    w.write(false)
    w.write(true)

    var r = ReadableArchive(w.finalize())
    XCTAssertEqual(r.read(Bool.self), false)
    XCTAssertEqual(r.read(Bool.self), true)
    XCTAssertNil(r.readByte())
  }

  func testInteger() {
    var w = WriteableArchive(BinaryBuffer())
    w.write(11 as UInt32)
    w.write(-8 as Int16)

    var r = ReadableArchive(w.finalize())
    XCTAssertEqual(r.read(UInt32.self), 11)
    XCTAssertEqual(r.read(Int16.self), -8)
    XCTAssertNil(r.readByte())
  }

  func testFloatingPoint() {
    var w = WriteableArchive(BinaryBuffer())
    w.write(4.2 as Double)
    w.write(2.4 as Float)

    var r = ReadableArchive(w.finalize())
    XCTAssertEqual(r.read(Double.self), 4.2)
    XCTAssertEqual(r.read(Float.self), 2.4)
    XCTAssertNil(r.readByte())
  }

  func testString() {
    var w = WriteableArchive(BinaryBuffer())
    w.write("Hello, World!")
    w.write("\u{3042}")

    var r = ReadableArchive(w.finalize())
    XCTAssertEqual(r.read(String.self), "Hello, World!")
    XCTAssertEqual(r.read(String.self), "\u{3042}")
    XCTAssertNil(r.readByte())
  }

  func testOptional() {
    var w = WriteableArchive(BinaryBuffer())
    w.write(123 as Int?)
    w.write(nil as Int?)

    var r = ReadableArchive(w.finalize())
    XCTAssertEqual(r.read(Int?.self), .some(123))
    XCTAssertEqual(r.read(Int?.self), .some(nil))
    XCTAssertNil(r.readByte())
  }

  func testArray() {
    var w = WriteableArchive(BinaryBuffer())
    w.write([Int]())
    w.write(["ab", "cd", "ef"])

    var r = ReadableArchive(w.finalize())
    XCTAssertEqual(r.read([Int].self), [])
    XCTAssertEqual(r.read([String].self), ["ab", "cd", "ef"])
    XCTAssertNil(r.readByte())
  }

  func testDictionary() {
    var w = WriteableArchive(BinaryBuffer())
    w.write([Int: String]())
    w.write([1: "ab", 2: "cd", 3: "ef"])

    var r = ReadableArchive(w.finalize())
    XCTAssertEqual(r.read([Int: String].self), [:])
    XCTAssertEqual(r.read([Int: String].self), [1: "ab", 2: "cd", 3: "ef"])
    XCTAssertNil(r.readByte())
  }

  func testSet() {
    var w = WriteableArchive(BinaryBuffer())
    w.write(Set<Int>())
    w.write(Set(["ab", "cd", "ef"]))

    var r = ReadableArchive(w.finalize())
    XCTAssertEqual(r.read(Set<Int>.self), [])
    XCTAssertEqual(r.read(Set<String>.self), ["ab", "cd", "ef"])
    XCTAssertNil(r.readByte())
  }

}
