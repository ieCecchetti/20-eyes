// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ChillyCore",
    platforms: [.macOS(.v14)],
    products: [.library(name: "ChillyCore", targets: ["ChillyCore"])],
    targets: [
        .target(name: "ChillyCore"),
        .testTarget(name: "ChillyCoreTests", dependencies: ["ChillyCore"]),
    ]
)
