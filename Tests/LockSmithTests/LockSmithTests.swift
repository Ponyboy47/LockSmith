import XCTest
@testable import LockSmith

class LockSmithTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(LockSmith().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
