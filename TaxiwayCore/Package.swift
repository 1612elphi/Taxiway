// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TaxiwayCore",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "TaxiwayCore", targets: ["TaxiwayCore"]),
    ],
    targets: [
        .target(
            name: "TaxiwayCore",
            dependencies: []
        ),
        .testTarget(
            name: "TaxiwayCoreTests",
            dependencies: ["TaxiwayCore"]
        ),
    ]
)
