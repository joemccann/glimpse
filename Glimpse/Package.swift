// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Glimpse",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Glimpse", targets: ["Glimpse"])
    ],
    targets: [
        .executableTarget(
            name: "Glimpse",
            path: "Glimpse"
        ),
        .testTarget(
            name: "GlimpseTests",
            dependencies: ["Glimpse"],
            path: "GlimpseTests"
        )
    ]
)
