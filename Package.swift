// swift-tools-version:5.3

import Foundation
import PackageDescription

var sources = ["src/parser.c"]
if FileManager.default.fileExists(atPath: "src/scanner.c") {
    sources.append("src/scanner.c")
}

let package = Package(
    name: "TreeSitterLang0",
    products: [
        .library(name: "TreeSitterLang0", targets: ["TreeSitterLang0"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tree-sitter/swift-tree-sitter", from: "0.8.0"),
    ],
    targets: [
        .target(
            name: "TreeSitterLang0",
            dependencies: [],
            path: ".",
            sources: sources,
            resources: [
                .copy("queries")
            ],
            publicHeadersPath: "bindings/swift",
            cSettings: [.headerSearchPath("src")]
        ),
        .testTarget(
            name: "TreeSitterLang0Tests",
            dependencies: [
                "SwiftTreeSitter",
                "TreeSitterLang0",
            ],
            path: "bindings/swift/TreeSitterLang0Tests"
        )
    ],
    cLanguageStandard: .c11
)
