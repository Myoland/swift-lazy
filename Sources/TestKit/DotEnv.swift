import SwiftDotenv
import Foundation

extension Dotenv {
    /// NOTICE: If you run tests in Xcode, MUST run tests on executable, and Working Directory in scheme,
    ///         or FileMananger will inital `currentDirectoryPath` correctly.
    public static func make() throws {
        if ProcessInfo.processInfo.isTesting {
            try self.configure(atPath: ".env.test")
        } else {
            try self.configure()
        }
    }
}

extension ProcessInfo {

    // "/Applications/Xcode-16.0.0.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/libexec/swift/pm/swiftpm-testing-helper",
    // "--test-bundle-path", "/Users/afuture/Developer/08-Myoland/dify-forward/.build/arm64-apple-macosx/debug/dify-forwardPackageTests.xctest/Contents/MacOS/dify-forwardPackageTests",
    // "-q",
    // "--filter", "testLLMNodeRun",
    // "/Users/afuture/Developer/08-Myoland/dify-forward/.build/arm64-apple-macosx/debug/dify-forwardPackageTests.xctest/Contents/MacOS/dify-forwardPackageTests",
    // "--testing-library", "swift-testing"
    fileprivate var isTesting: Bool {
        if environment.keys.contains("XCTestBundlePath") { return true }
        if environment.keys.contains("XCTestConfigurationFilePath") { return true }
        if environment.keys.contains("XCTestSessionIdentifier") { return true }

        return arguments.contains { argument in
            let path = URL(fileURLWithPath: argument)
            return path.lastPathComponent == "swiftpm-testing-helper"
                || argument == "--testing-library"
                || path.lastPathComponent == "xctest"
                || path.pathExtension == "xctest"
        }
    }
}
