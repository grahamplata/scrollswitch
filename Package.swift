// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ScrollSwitch",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "ScrollSwitch", path: "Sources/ScrollSwitch")
    ]
)
