// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SupabaseChat",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "SupabaseChat",
            targets: ["SupabaseChat"]),
    ],
    dependencies: [
        // Supabase Swift SDK
        .package(url: "https://github.com/supabase-community/supabase-swift", from: "0.3.0"),
    ],
    targets: [
        .target(
            name: "SupabaseChat",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "SupabaseChatTests",
            dependencies: ["SupabaseChat"],
            path: "Tests"
        ),
    ]
)