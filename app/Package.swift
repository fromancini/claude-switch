// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeSwitchMenuBar",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "ClaudeSwitchMenuBar"),
        .testTarget(
            name: "ClaudeSwitchMenuBarTests",
            dependencies: ["ClaudeSwitchMenuBar"]
        ),
    ]
)
