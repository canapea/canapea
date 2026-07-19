// swift-tools-version:5.3

import Foundation
import PackageDescription

var sources = ["src/parser.c"]
if FileManager.default.fileExists(atPath: "src/scanner.c") {
    sources.append("src/scanner.c")
}

let package = Package(
    name: "TreeSitterSol3",
    products: [
        .library(name: "TreeSitterSol3", targets: ["TreeSitterSol3"]),
    ],
    dependencies: [
        .package(name: "SwiftTreeSitter", url: "https://github.com/tree-sitter/swift-tree-sitter", from: "0.9.0"),
    ],
    targets: [
        .target(
            name: "TreeSitterSol3",
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
            name: "TreeSitterSol3Tests",
            dependencies: [
                "SwiftTreeSitter",
                "TreeSitterSol3",
            ],
            path: "bindings/swift/TreeSitterSol3Tests"
        )
    ],
    cLanguageStandard: .c11
)
