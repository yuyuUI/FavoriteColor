// swift-tools-version:5.5

import Foundation
import PackageDescription

// MARK: - shared

var package = Package(
    name: "FavoriteColor",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
    ],
    products: [
        .library(name: "AppFeature", targets: ["AppFeature"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.28.0"),
        .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: "AppFeature",
            dependencies: [
                .product(name: "Tagged", package: "swift-tagged"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .testTarget(
            name: "AppFeatureTests",
            dependencies: [
                .product(name: "Tagged", package: "swift-tagged"),
                "AppFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
    ]
)


