// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "aoc-2025",
  products: [
    .library(name: "Core", targets: ["Core"]),

    .executable(name: "Day1", targets: ["Day1"]),
    .executable(name: "Day2", targets: ["Day2"]),
    .executable(name: "Day3", targets: ["Day3"]),
    .executable(name: "Day4", targets: ["Day4"]),
    .executable(name: "Day5", targets: ["Day5"]),
    .executable(name: "Day6", targets: ["Day6"]),
    .executable(name: "Day7", targets: ["Day7"]),
    .executable(name: "Day8", targets: ["Day8"]),
    .executable(name: "Day9", targets: ["Day9"]),
    .executable(name: "Day10", targets: ["Day10"]),

    .executable(name: "SandBox", targets: ["SandBox"]),
    .executable(name: "Skeleton", targets: ["Skeleton"]),
    .executable(name: "LoadIntoStruct", targets: ["LoadIntoStruct"]),
    .executable(name: "LoadFromEntire", targets: ["LoadFromEntire"]),
  ],
  dependencies: [
    // .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
    .package(url: "https://github.com/apple/swift-collections", from: "1.0.0")
  ],
  targets: [
    .target(name: "Core"),

    .executableTarget(name: "Day1", dependencies: ["Core"], exclude: ["Files/"]),
    .executableTarget(name: "Day2", dependencies: ["Core"], exclude: ["Files/"]),
    .executableTarget(name: "Day3", dependencies: ["Core"], exclude: ["Files/"]),
    .executableTarget(name: "Day4", dependencies: ["Core"], exclude: ["Files/"]),
    .executableTarget(name: "Day5", dependencies: ["Core"], exclude: ["Files/"]),
    .executableTarget(name: "Day6", dependencies: ["Core"], exclude: ["Files/"]),
    .executableTarget(name: "Day7", dependencies: ["Core"], exclude: ["Files/"]),
    .executableTarget(name: "Day8", dependencies: ["Core"], exclude: ["Files/"]),
    .executableTarget(name: "Day9", dependencies: ["Core"], exclude: ["Files/"]),
    .executableTarget(name: "Day10", dependencies: ["Core"], exclude: [
      "Files/",
      "requirements.txt",
      "main.py",
    ]),

    .executableTarget(name: "SandBox", dependencies: [
      "Core",
      .product(name: "Collections", package: "swift-collections")
    ], exclude: ["Files/"]),
    .executableTarget(name: "Skeleton", dependencies: ["Core"], exclude: ["Files/"]),
    .executableTarget(name: "LoadIntoStruct", dependencies: ["Core"], exclude: ["Files/"]),
    .executableTarget(name: "LoadFromEntire", dependencies: ["Core"], exclude: ["Files/"]),

    .testTarget(name: "CoreTests", dependencies: ["Core"], exclude: ["Files/"]),
  ]
)
