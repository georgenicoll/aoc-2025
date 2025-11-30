// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "aoc-2025",
  products: [
    .library(name: "Core", targets: ["Core"]),

    .executable(name: "Day1", targets: ["Day1"]),

    .executable(name: "SandBox", targets: ["SandBox"]),
    .executable(name: "Skeleton", targets: ["Skeleton"]),
    .executable(name: "LoadIntoStruct", targets: ["LoadIntoStruct"]),
    .executable(name: "LoadFromEntire", targets: ["LoadFromEntire"]),
  ],
  targets: [
    .target(name: "Core"),

    .executableTarget(name: "Day1", dependencies: ["Core"], exclude: ["Files/"]),

    .executableTarget(name: "SandBox", dependencies: ["Core"], exclude: ["Files/"]),
    .executableTarget(name: "Skeleton", dependencies: ["Core"], exclude: ["Files/"]),
    .executableTarget(name: "LoadIntoStruct", dependencies: ["Core"], exclude: ["Files/"]),
    .executableTarget(name: "LoadFromEntire", dependencies: ["Core"], exclude: ["Files/"]),

    .testTarget(name: "CoreTests", dependencies: ["Core"], exclude: ["Files/"]),
  ]
)
