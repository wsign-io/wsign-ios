import XCTest
@testable import WsignSigning

final class HostMatcherTests: XCTestCase {
    func testNormalizeLowercasesTrimsAndDropsTrailingDots() {
        XCTAssertEqual(HostMatcher.normalize("  WSIGN.com.. "), "wsign.io")
        XCTAssertEqual(HostMatcher.normalize("[::1]"), "::1")
        XCTAssertEqual(HostMatcher.normalize(""), "")
        XCTAssertEqual(HostMatcher.normalize("."), "")
    }

    func testExactMatch() {
        let patterns: Set<String> = ["wsign.io", "www.wsign.io"]
        XCTAssertTrue(HostMatcher.matches("wsign.io", patterns: patterns))
        XCTAssertTrue(HostMatcher.matches("WWW.Wsign.Com", patterns: patterns))
        XCTAssertTrue(HostMatcher.matches("wsign.io.", patterns: patterns))
        XCTAssertFalse(HostMatcher.matches("sign.wsign.io", patterns: patterns))
        XCTAssertFalse(HostMatcher.matches("evilwsign.io", patterns: patterns))
        XCTAssertFalse(HostMatcher.matches("wsign.io.evil.example", patterns: patterns))
        XCTAssertFalse(HostMatcher.matches("", patterns: patterns))
    }

    func testWildcardMatchesSubdomainsButNotApex() {
        let patterns: Set<String> = ["*.example.com"]
        XCTAssertTrue(HostMatcher.matches("sign.example.com", patterns: patterns))
        XCTAssertTrue(HostMatcher.matches("a.b.example.com", patterns: patterns))
        XCTAssertFalse(HostMatcher.matches("example.com", patterns: patterns))
        XCTAssertFalse(HostMatcher.matches("badexample.com", patterns: patterns))
        XCTAssertFalse(HostMatcher.matches("example.com.evil", patterns: patterns))
    }

    func testDegenerateWildcardMatchesNothing() {
        XCTAssertFalse(HostMatcher.matches("example.com", patterns: ["*."]))
        XCTAssertFalse(HostMatcher.matches("example.com", patterns: [""]))
    }

    func testLocalDevelopmentHosts() {
        for host in ["localhost", "127.0.0.1", "::1", "developers.localhost", "wsign.test", "LOCALHOST."] {
            XCTAssertTrue(HostMatcher.isLocalDevelopmentHost(host), host)
        }
        for host in ["wsign.io", "localhost.example.com", "10.0.0.1", "test"] {
            XCTAssertFalse(HostMatcher.isLocalDevelopmentHost(host), host)
        }
    }
}
