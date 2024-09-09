/// The order in which bytes should be read from or written to a binary archive.
public enum Endianness {

  /// Most significant byte is first.
  case little

  /// Most significant byte is last.
  case big

  /// The endianness of the host.
  public static var host: Endianness {
    (0xff.littleEndian == 0xff) ? .little : .big
  }

}
