// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WaterTracker",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "WaterTrackerShared", targets: ["WaterTrackerShared"]),
    ],
    dependencies: [
        .package(url: "https://github.com/typelift/SwiftCheck.git", exact: "0.12.0"),
    ],
    targets: [
        .target(
            name: "WaterTrackerShared",
            path: "Shared"
        ),
        .testTarget(
            name: "WaterTrackerTests",
            dependencies: [
                "WaterTrackerShared",
                .product(name: "SwiftCheck", package: "SwiftCheck"),
            ],
            path: "WaterTrackerTests"
        ),
    ]
)
