// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpatialHome",
    platforms: [
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "SpatialHome",
            targets: ["SpatialHome"]),
    ],
    targets: [
        .target(
            name: "SpatialHome",
            path: "SpatialHome"
        ),
        .testTarget(
            name: "SpatialHomeTests",
            dependencies: ["SpatialHome"],
            path: "SpatialHomeTests"
        ),
    ]
)
