// swift-tools-version: 5.9

import PackageDescription

let llamaVersion = "b5836"

// MARK: - Package Dependencies

var packageDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMinor(from: "1.4.0")),
    .package(url: "https://github.com/johnmai-dev/Jinja", .upToNextMinor(from: "1.1.0")),
]

#if os(iOS) || os(macOS)
packageDependencies.append(contentsOf: [
    .package(url: "https://github.com/huggingface/swift-transformers", .upToNextMinor(from: "0.1.21")),
    .package(url: "https://github.com/ml-explore/mlx-swift-examples", branch: "main"),
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.0")
])
#endif

// MARK: - Package Products

var packageProducts: [Product] = [
    .library(name: "LocalLLMClient", targets: ["LocalLLMClient"])
]

#if os(iOS) || os(macOS)
packageProducts.append(contentsOf: [
    .executable(name: "localllm", targets: ["LocalLLMCLI"]),
    .library(name: "LocalLLMClientLlama", targets: ["LocalLLMClientLlama"]),
    .library(name: "LocalLLMClientMLX", targets: ["LocalLLMClientMLX"]),
    .library(name: "LocalLLMClientFoundationModels", targets: ["LocalLLMClientFoundationModels"]),
])
#elseif os(Linux)
packageProducts.append(contentsOf: [
    .executable(name: "localllm", targets: ["LocalLLMCLI"]),
    .library(name: "LocalLLMClientLlama", targets: ["LocalLLMClientLlama"]),
])
#endif

// MARK: - Package Targets

var packageTargets: [Target] = [
    .target(name: "LocalLLMClient", dependencies: ["LocalLLMClientUtility"]),
    .target(name: "LocalLLMClientUtility"),
]

#if os(iOS) || os(macOS)
packageTargets.append(contentsOf: [
    .executableTarget(
        name: "LocalLLMCLI",
        dependencies: [
            "LocalLLMClientLlama",
            "LocalLLMClientMLX",
            "LocalLLMClientFoundationModels",
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ],
        swiftSettings: [
            .interoperabilityMode(.Cxx)
        ],
        linkerSettings: [
            .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path"])
        ]
    ),

    .target(
        name: "LocalLLMClientLlama",
        dependencies: [
            "LocalLLMClient",
            "LocalLLMClientLlamaC",
            .product(name: "Jinja", package: "Jinja")
        ],
        resources: [.process("Resources")],
        swiftSettings: (Context.environment["BUILD_DOCC"] == nil ? [] : [
            .define("BUILD_DOCC")
        ]) + [
            .interoperabilityMode(.Cxx)
        ]
    ),
    .testTarget(
        name: "LocalLLMClientLlamaTests",
        dependencies: ["LocalLLMClientLlama"],
        swiftSettings: [
            .interoperabilityMode(.Cxx)
        ]
    ),

    .target(
        name: "LocalLLMClientMLX",
        dependencies: [
            "LocalLLMClient",
            .product(name: "MLXLLM", package: "mlx-swift-examples"),
            .product(name: "MLXVLM", package: "mlx-swift-examples"),
        ],
    ),
    .testTarget(
        name: "LocalLLMClientMLXTests",
        dependencies: ["LocalLLMClientMLX"]
    ),
    .target(
        name: "LocalLLMClientFoundationModels",
        dependencies: ["LocalLLMClient"]
    ),
    .testTarget(
        name: "LocalLLMClientFoundationModelsTests",
        dependencies: ["LocalLLMClientFoundationModels"]
    ),

    .binaryTarget(
        name: "LocalLLMClientLlamaFramework",
        url:
            "https://github.com/ggml-org/llama.cpp/releases/download/\(llamaVersion)/llama-\(llamaVersion)-xcframework.zip",
        checksum: "e2b8522f0aebe3e10a5662bece866295ec48fc1c9f9546be22c055a5f0373fd6"
    ),
    .target(
        name: "LocalLLMClientLlamaC",
        dependencies: ["LocalLLMClientLlamaFramework"],
        exclude: ["exclude"],
        cSettings: [
            .unsafeFlags(["-w"])
        ],
        swiftSettings: [
            .interoperabilityMode(.Cxx)
        ]
    ),

    .testTarget(
        name: "LocalLLMClientUtilityTests",
        dependencies: [
            "LocalLLMClientUtility",
            .product(name: "MLXLMCommon", package: "mlx-swift-examples")
        ]
    )
])
#elseif os(Linux)
packageTargets.append(contentsOf: [
    .executableTarget(
        name: "LocalLLMCLI",
        dependencies: [
            "LocalLLMClientLlama",
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ],
        swiftSettings: [
            .interoperabilityMode(.Cxx)
        ],
        linkerSettings: [
            .unsafeFlags([
                Context.environment["LDFLAGS", default: ""],
            ])
        ]
    ),

    .target(
        name: "LocalLLMClientLlama",
        dependencies: [
            "LocalLLMClient",
            "LocalLLMClientLlamaC",
            .product(name: "Jinja", package: "Jinja")
        ],
        resources: [.process("Resources")],
        swiftSettings: [
            .interoperabilityMode(.Cxx)
        ]
    ),
    .testTarget(
        name: "LocalLLMClientLlamaTests",
        dependencies: ["LocalLLMClientLlama"],
        swiftSettings: [
            .interoperabilityMode(.Cxx)
        ],
        linkerSettings: [
            .unsafeFlags([
                Context.environment["LDFLAGS", default: ""],
            ])
        ]
    ),

    .target(
        name: "LocalLLMClientLlamaC",
        exclude: ["exclude"],
        cSettings: [
            .unsafeFlags(["-w"])
        ],
        swiftSettings: [
            .interoperabilityMode(.Cxx)
        ],
        linkerSettings: [
            .unsafeFlags([
                 "-lggml-base", "-lggml", "-lllama", "-lmtmd"
            ])
        ]
    ),

    .testTarget(
        name: "LocalLLMClientUtilityTests",
        dependencies: ["LocalLLMClientUtility"]
    )
])
#endif

// MARK: - Package Definition

let package = Package(
    name: "LocalLLMClient",
    platforms: [.iOS(.v16), .macOS(.v14)],
    products: packageProducts,
    dependencies: packageDependencies,
    targets: packageTargets,
    cxxLanguageStandard: .cxx17
)
