// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "SupabaseChat",
    platforms: [.macOS(.v10_15)],
    products: [
        .executable(name: "SupabaseChat", targets: ["SupabaseChat"])
    ],
    dependencies: [
        // No external dependencies to minimize issues in the Replit environment
    ],
    targets: [
        .executableTarget(
            name: "SupabaseChat",
            dependencies: [],
            path: "SupabaseChat"
        )
    ]
)