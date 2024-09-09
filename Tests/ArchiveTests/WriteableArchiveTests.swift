import Archivist
import XCTest

final class WriteableArchiveTests: XCTestCase {

  func testByte() {
    var w = WriteableArchive(BinaryBuffer())
    w.write(byte: 0xab)
    w.write(byte: 0xcd)
    XCTAssertEqual(w.finalize().description, "abcd")
  }

  func testInteger() {
    var w = WriteableArchive(BinaryBuffer())
    w.write(0xff as Int16, endianness: .little)
    w.write(0xff as Int16, endianness: .big)
    XCTAssertEqual(w.finalize().description, "ff0000ff")
  }

  func testFloatingPoint() {
    var w = WriteableArchive(BinaryBuffer())
    w.write(4.2, endianness: .little)
    w.write(4.2, endianness: .big)
    XCTAssertEqual(w.finalize().description, "cdcccccccccc10404010cccccccccccd")
  }

  func testSignedLEB128() {
    var w = WriteableArchive(BinaryBuffer())
    w.write(signedLEB128: 42)
    w.write(signedLEB128: -2)
    w.write(signedLEB128: 128)
    XCTAssertEqual(w.finalize().description, "2a7e8001")
  }

  func testUnsignedLEB128() {
    var w = WriteableArchive(BinaryBuffer())
    w.write(unsignedLEB128: 42 as UInt)
    w.write(unsignedLEB128: 2 as UInt)
    w.write(unsignedLEB128: 128 as UInt)
    XCTAssertEqual(w.finalize().description, "2a028001")
  }

}
