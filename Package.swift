// swift-tools-version:5.10
import PackageDescription

let package = Package(
  name: "Archivist",
  platforms: [.macOS(.v11)],
  products: [
    .library(name: "Archivist", targets: ["Archivist"]),
  ],
  targets: [
    .target(name: "Archivist", dependencies: []),
    .testTarget(
      name: "ArchivistTests",
      dependencies: [
        .target(name: "Archivist"),
      ]),
  ])
