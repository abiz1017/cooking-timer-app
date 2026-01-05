// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CookingTimerApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "CookingTimerApp",
            targets: ["CookingTimerApp"]
        )
    ],
    dependencies: [
        // SwiftSoup for HTML parsing
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0")
    ],
    targets: [
        .executableTarget(
            name: "CookingTimerApp",
            dependencies: ["SwiftSoup"],
            path: "CookingTimerApp"
        )
    ]
)
