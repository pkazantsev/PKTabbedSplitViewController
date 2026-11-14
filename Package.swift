// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "PKTabbedSplitViewController",
    platforms: [
        .iOS(.v14)
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
            dependencies: [],
            path: "Sources/TabbedSplitViewController"
        ),
        .testTarget(
            name: "PKTabbedSplitViewControllerTests",
            dependencies: ["PKTabbedSplitViewController"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
