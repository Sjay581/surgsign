// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SurgSign",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SurgSign",
            targets: ["SurgSign"]
        )
    ],
    targets: [
        .target(
            name: "SurgSign",
            path: "Sources/SurgSign"
        ),
        .testTarget(
            name: "SurgSignTests",
            dependencies: ["SurgSign"],
            path: "Tests/SurgSignTests"
        )
    ]
)
