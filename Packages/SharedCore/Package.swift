// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SharedCore",
    defaultLocalization: "zh-Hant",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SharedCore", targets: ["SharedCore"]),
        .library(name: "AIKit", targets: ["AIKit"]),
        .library(name: "RAGKit", targets: ["RAGKit"]),
        .library(name: "PersistenceKit", targets: ["PersistenceKit"]),
        .library(name: "ExportKit", targets: ["ExportKit"]),
        .library(name: "PaywallKit", targets: ["PaywallKit"]),
        .library(name: "NotificationKit", targets: ["NotificationKit"]),
        .library(name: "APIClientKit", targets: ["APIClientKit"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"])
    ],
    targets: [
        .target(name: "AIKit"),
        .target(name: "RAGKit"),
        .target(name: "PersistenceKit"),
        .target(name: "ExportKit"),
        .target(name: "PaywallKit"),
        .target(name: "NotificationKit"),
        .target(name: "APIClientKit"),
        .target(name: "DesignSystem"),
        .target(name: "SharedCore", dependencies: ["AIKit", "RAGKit", "PersistenceKit", "ExportKit", "PaywallKit", "NotificationKit", "APIClientKit", "DesignSystem"])
    ]
)
