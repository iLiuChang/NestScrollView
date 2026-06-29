// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "NestScrollView",
    platforms: [.iOS(.v11)],
    products: [
        .library(name: "NestScrollView", targets: ["NestScrollView"])
    ],
    targets: [
        .target(
            name: "NestScrollView",
            path: "Sources",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        )
    ]
)
