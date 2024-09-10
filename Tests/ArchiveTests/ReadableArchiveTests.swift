import Archivist
import XCTest

final class ReadableArchiveTests: XCTestCase {

  func testRawRepresentable() {
    enum S: String, RawRepresentable { case a, b }
    var r = ReadableArchive(BinaryBuffer("01610162")!)
    XCTAssertEqual(r.read(rawValueOf: S.self), S.a)
    XCTAssertEqual(r.read(rawValueOf: S.self), S.b)
    XCTAssertNil(r.readByte())
  }

  func testByte() {
    var r = ReadableArchive(BinaryBuffer("abcd")!)
    XCTAssertEqual(r.readByte(), 0xab)
    XCTAssertEqual(r.readByte(), 0xcd)
    XCTAssertNil(r.readByte())
  }

  func testInteger() {
    var r = ReadableArchive(BinaryBuffer("ff0000ff")!)
    XCTAssertEqual(r.read(UInt16.self, endianness: .little), 0xff)
    XCTAssertEqual(r.read(UInt16.self, endianness: .big), 0xff)
    XCTAssertNil(r.readByte())
  }

  func testFloatingPoint() {
    var r = ReadableArchive(BinaryBuffer("cdcccccccccc10404010cccccccccccd")!)
    XCTAssertEqual(r.read(Double.self, endianness: .little), 4.2)
    XCTAssertEqual(r.read(Double.self, endianness: .big), 4.2)
    XCTAssertNil(r.readByte())
  }

  func testSignedLEB128() {
    var r = ReadableArchive(BinaryBuffer("2a7e8001")!)
    XCTAssertEqual(r.readSignedLEB128(), 42)
    XCTAssertEqual(r.readSignedLEB128(), -2)
    XCTAssertEqual(r.readSignedLEB128(), 128)
    XCTAssertNil(r.readByte())
  }

  func testUnsignedLEB128() {
    var r = ReadableArchive(BinaryBuffer("2a028001")!)
    XCTAssertEqual(r.readUnsignedLEB128(), 42)
    XCTAssertEqual(r.readUnsignedLEB128(), 2)
    XCTAssertEqual(r.readUnsignedLEB128(), 128)
    XCTAssertNil(r.readByte())
  }

}
