// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EnergyTodo",
    platforms: [
        .iOS(.v17)
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: "7.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "EnergyTodo",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
            ]
        ),
        .testTarget(
            name: "EnergyTodoTests",
            dependencies: ["EnergyTodo"]
        ),
    ]
)
