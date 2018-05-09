import XCTest
import PathKit
@testable import LockSmith

class LockSmithTests: XCTestCase {
    lazy var runDir: Path = {
        return Path("/tmp/\(self.name)")
    }()

    func singletonTest() {
        XCTAssertNoThrow(try runDir.mkpath())

        guard runDir.isDirectory else { return }

        var singleton = LockSmith(runDir)

        if singleton == nil {
            XCTFail("Process is already locked")
        }

        singleton = nil
        try? runDir.delete()
    }

    func manyTest() {
        let firstRunDir = runDir + "first"
        let secondRunDir = runDir + "second"

        XCTAssertNoThrow(try firstRunDir.mkpath())
        XCTAssertNoThrow(try secondRunDir.mkpath())

        guard firstRunDir.isDirectory, secondRunDir.isDirectory else { return }

        var first = LockSmith(firstRunDir)
        var second = LockSmith(secondRunDir)
        let third = LockSmith(secondRunDir)

        XCTAssertNotNil(first)
        XCTAssertNotNil(second)
        XCTAssertNil(third)

        first = nil
        second = nil
        try? runDir.delete()
    }

    static var allTests = [
        ("singletonTest", singletonTest),
        ("manyTest", manyTest),
    ]
}
