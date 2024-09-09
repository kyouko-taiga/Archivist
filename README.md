# Archivist

Archivist is a tiny library to serialize and deserialize data structures.

## Usage

To serialize data, you first create an instance of `WriteableArchive`, which is an adapter around a `BinaryOutputStream` to encode data structures: 

```swift
var w = WriteableArchive(BinaryBuffer())
```

You then append data to the buffer by calling one of the `write` methods of the adapter:

```swift
w.write(unsignedLEB128: 42)
w.write(true)
w.write("Archivist")
```

Once your data has been written, you finally extract the buffer from the adapter using `finalize`:

```swift
let b = w.finalize()
print(b)
```

To deserialize data, you first create an instance of `ReadableArchive`, which is an adapter around any collection of bytes to serve as a buffer.
You then parse values from that buffer using the `read` methods of the adapter:

```swift
var r = ReadableArchive(someBuffer)
let u = r.readUnsignedLEB128()
let b = r.read(Bool.self)
let s = r.read(String.self)
```

### Serializing custom data

Instances of any type that conforms to `Archivable` can be passed to `WriteableArchive.write` or `ReadableArchive.read`.
`Archivable` comes with two requirements:

- `init?<T>(from: inout ReadableArchive<T>, in: inout Any)`, which deserializes a value:
- `write<T>(to: inout WriteableArchive<T>, in: inout Any)`, which serializes a value.

Both of these methods accept a parameter of type `Any` representing the context in which deserialization (respectively serialization) operates.
For instance, you may use this context to keep track of data that has already been serialized in the archive.
