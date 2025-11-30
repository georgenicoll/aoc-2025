// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "aoc-2025",
  products: [
    .library(name: "Core", targets: ["Core"]),
    .executable(name: "SandBox", targets: ["SandBox"]),
  ],
  targets: [
    .target(name: "Core"),
    .executableTarget(name: "SandBox", dependencies: ["Core"], exclude: ["Files/"]),
    .testTarget(name: "CoreTests", dependencies: ["Core"], exclude: ["Files/"]),
  ]
)
