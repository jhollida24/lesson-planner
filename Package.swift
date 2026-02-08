// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LessonPlanner",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "lesson-planner", targets: ["lesson-planner"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "lesson-planner",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/LessonPlanner"
        ),
    ]
)
