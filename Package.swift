// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "PKTabbedSplitViewController",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "PKTabbedSplitViewController",
            type: .dynamic,
            targets: [
                "PKTabbedSplitViewController"
            ]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PKTabbedSplitViewController",
            dependencies: []
        ),
    ],
    swiftLanguageModes: [.v5]
)
