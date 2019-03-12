import XCTest
import TrailBlazer
@testable import LockSmith

class LockSmithTests: XCTestCase {
    lazy var runDir: DirectoryPath = {
        return DirectoryPath("/tmp/\(self.name)")!
    }()

    func singletonTest() {
        XCTAssertNoThrow(try runDir.create(options: .createIntermediates))

        XCTAssertNoThrow(try LockSmith(runDir))

        try? runDir.recursiveDelete()
    }

    func manyTest() {
        var firstRunDir = runDir + DirectoryPath("first")!
        var secondRunDir = runDir + DirectoryPath("second")!

        XCTAssertNoThrow(try firstRunDir.create(options: .createIntermediates))
        XCTAssertNoThrow(try secondRunDir.create())

        XCTAssertNoThrow(try LockSmith(firstRunDir))
        do {
            let _ = try LockSmith(secondRunDir)
            do {
                let _ = try LockSmith(secondRunDir)
                XCTFail("Should have failed to lock twice in \(secondRunDir)")
            } catch {}
        } catch {
            XCTFail("Failed to lock process in run dir: \(secondRunDir)")
            return
        }
        try? runDir.recursiveDelete()
    }

    static var allTests = [
        ("singletonTest", singletonTest),
        ("manyTest", manyTest),
    ]
}
