// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WsignSigning",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "WsignSigning", targets: ["WsignSigning"])
    ],
    targets: [
        .target(
            name: "WsignSigning",
            path: "Sources/WsignSigning",
            resources: [
                .copy("Resources/PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "WsignSigningTests",
            dependencies: ["WsignSigning"],
            path: "Tests/WsignSigningTests"
        )
    ]
)
