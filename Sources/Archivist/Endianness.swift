/// The order in which bytes should be read from or written to a binary archive.
public enum Endianness {

  /// Least significant byte is first.
  case lsbFirst

  /// Most significant byte is first.
  case msbFirst

  /// The endianness of the host.
  public static var host: Endianness {
    (0xff.littleEndian == 0xff) ? .lsbFirst : .msbFirst
  }

}
