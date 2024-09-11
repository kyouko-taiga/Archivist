/// An error that occurred during serialization or deserialization.
public enum ArchiveError: Error {

  /// An error caused by an attempt to read data from an empty stream.
  case emptyInput

  /// An error cause by an invalid input.
  case invalidInput

}
