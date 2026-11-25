// swift-tools-version: 6.0

import PackageDescription

// exposes TaxiwayCore to url consumers
let package = Package(
    name: "Taxiway",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "TaxiwayCore", targets: ["TaxiwayCore"]),
    ],
    targets: [
        .target(
            name: "TaxiwayCore",
            path: "TaxiwayCore/Sources/TaxiwayCore"
        ),
    ]
)
