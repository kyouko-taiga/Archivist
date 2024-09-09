/// A type that can be serialized and deserialized to and from a binary archive.
public protocol Archivable {

  /// Reads `self` from `archive`, updating `context` with the deserialization state.
  init?<T>(from archive: inout ReadableArchive<T>, in context: inout Any)

  /// Writes `self` to `archive` updating `context` with the srialization state.
  func write<T>(to archive: inout WriteableArchive<T>, in context: inout Any)

}
