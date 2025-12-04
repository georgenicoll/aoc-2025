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

    .executable(name: "SandBox", targets: ["SandBox"]),
    .executable(name: "Skeleton", targets: ["Skeleton"]),
    .executable(name: "LoadIntoStruct", targets: ["LoadIntoStruct"]),
    .executable(name: "LoadFromEntire", targets: ["LoadFromEntire"]),
  ],
  targets: [
    .target(name: "Core"),

    .executableTarget(name: "Day1", dependencies: ["Core"], exclude: ["Files/"]),
    .executableTarget(name: "Day2", dependencies: ["Core"], exclude: ["Files/"]),
    .executableTarget(name: "Day3", dependencies: ["Core"], exclude: ["Files/"]),
    .executableTarget(name: "Day4", dependencies: ["Core"], exclude: ["Files/"]),
    .executableTarget(name: "Day5", dependencies: ["Core"], exclude: ["Files/"]),

    .executableTarget(name: "SandBox", dependencies: ["Core"], exclude: ["Files/"]),
    .executableTarget(name: "Skeleton", dependencies: ["Core"], exclude: ["Files/"]),
    .executableTarget(name: "LoadIntoStruct", dependencies: ["Core"], exclude: ["Files/"]),
    .executableTarget(name: "LoadFromEntire", dependencies: ["Core"], exclude: ["Files/"]),

    .testTarget(name: "CoreTests", dependencies: ["Core"], exclude: ["Files/"]),
  ]
)
