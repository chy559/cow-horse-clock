// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CowHorseClock",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "CowHorseClock", targets: ["CowHorseClock"])
    ],
    targets: [
        .executableTarget(name: "CowHorseClock")
    ]
)
