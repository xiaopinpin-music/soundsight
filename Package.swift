// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SoundSight",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "SoundSight",
            targets: ["SoundSight"]
        )
    ],
    targets: [
        .executableTarget(
            name: "SoundSight",
            path: "Sources/SoundSight"
        )
    ]
)
