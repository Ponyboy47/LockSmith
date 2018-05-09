import XCTest
import PathKit
@testable import LockSmith

class LSFileLockTests: XCTestCase {
    lazy var runDir: Path = {
        return Path("/tmp/\(self.name)")
    }()

    func lockAndUnlockOneTest() {
        XCTAssertNoThrow(try runDir.mkpath())

        var singleton = LockSmith(runDir)

        let testFile = runDir + "testFile.txt"
        XCTAssertNoThrow(try testFile.write(""))

        XCTAssertNotNil(singleton)

        XCTAssertTrue(testFile.lock())
        XCTAssertTrue(testFile.isLocked)
        XCTAssertTrue(testFile.unlock())
        XCTAssertFalse(testFile.isLocked)

        singleton = nil
        try? runDir.delete()
    }

    func lockAndUnlockManyTest() {
        XCTAssertNoThrow(try runDir.mkpath())

        let file1 = runDir + "testFile1.txt"
        let file2 = runDir + "testFile2.txt"
        let file3 = runDir + "testFile3.txt"

        let toLock = [file1, file2, file3]

        XCTAssertTrue(LockSmith.lock(toLock).isEmpty)
        XCTAssertTrue(toLock.reduce(true, { guard $0 else { return $0 }; return $1.isLocked }))
        XCTAssertTrue(LockSmith.lock(toLock).isEmpty)
        XCTAssertFalse(toLock.reduce(false, { guard !$0 else { return $0 }; return $1.isLocked }))

        try? runDir.delete()
    }

    static var allTests = [
        ("lockAndUnlockOneTest", lockAndUnlockOneTest),
        ("lockAndUnlockManyTest", lockAndUnlockManyTest),
    ]
}


