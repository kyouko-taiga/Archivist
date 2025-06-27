// swift-tools-version:6.0
import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "Archivist",
  platforms: [.macOS(.v11)],
  products: [
    .library(name: "Archivist", targets: ["Archivist"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-syntax", from: "601.0.1"),
  ],
  targets: [
    .target(
      name: "Archivist",
      dependencies: [
        .target(name: "ArchivistMacros"),
      ]),
    .macro(
      name: "ArchivistMacros",
      dependencies: [
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
      ]),
    .testTarget(
      name: "ArchivistTests",
      dependencies: [
        .target(name: "Archivist"),
      ]),
  ])
