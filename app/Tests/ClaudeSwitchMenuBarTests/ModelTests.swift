import XCTest
@testable import ClaudeSwitchMenuBar

final class ModelTests: XCTestCase {
    func testDecodeList() throws {
        let json = #"{"active":"work","profiles":[{"name":"work","email":"a@b.com","active":true},{"name":"personal","email":"c@d.com","active":false}]}"#
        let r = try JSONDecoder().decode(ListResult.self, from: Data(json.utf8))
        XCTAssertEqual(r.active, "work")
        XCTAssertEqual(r.profiles.count, 2)
        XCTAssertEqual(r.profiles[0].name, "work")
        XCTAssertTrue(r.profiles[0].active)
        XCTAssertEqual(r.profiles[1].email, "c@d.com")
        XCTAssertFalse(r.profiles[1].active)
    }

    func testDecodeNullActive() throws {
        let json = #"{"active":null,"profiles":[]}"#
        let r = try JSONDecoder().decode(ListResult.self, from: Data(json.utf8))
        XCTAssertNil(r.active)
        XCTAssertTrue(r.profiles.isEmpty)
    }

    func testDecodeWhoAmI() throws {
        let r = try JSONDecoder().decode(WhoAmI.self, from: Data(#"{"email":"a@b.com"}"#.utf8))
        XCTAssertEqual(r.email, "a@b.com")
        let n = try JSONDecoder().decode(WhoAmI.self, from: Data(#"{"email":null}"#.utf8))
        XCTAssertNil(n.email)
    }
}
