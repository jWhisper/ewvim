// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "ewvim",
  platforms: [
    .macOS(.v13)
  ],
  products: [
    .executable(
      name: "ewvim",
      targets: ["ewvim"]
    )
  ],
  dependencies: [],
  targets: [
    .executableTarget(
      name: "ewvim",
      dependencies: [],
      path: "Sources/ewvim",
      resources: [
        .process("Resources")
      ]
    )
  ]
)