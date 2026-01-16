// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CappitolianHttpLocalServer",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "CappitolianHttpLocalServer",
            targets: ["HttpLocalServerPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "HttpLocalServerPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/HttpLocalServerPlugin"),
        .testTarget(
            name: "HttpLocalServerPluginTests",
            dependencies: ["HttpLocalServerPlugin"],
            path: "ios/Tests/HttpLocalServerPluginTests")
    ]
)