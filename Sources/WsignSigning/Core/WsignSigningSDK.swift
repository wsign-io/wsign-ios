import Foundation

/// Version information for the Wsign signing SDK.
public enum WsignSigningSDK {
    /// The SDK version (Semantic Versioning).
    public static let version = "1.0.0"

    /// The Wsign API version this release was built against.
    public static let apiVersion = "2026-07-01"

    /// The hosts that serve Wsign signing pages. Add your custom signing domain to
    /// `WsignSigningConfiguration.allowedHosts` when your account uses one.
    public static let platformHosts: Set<String> = ["wsign.io", "www.wsign.io"]
}
