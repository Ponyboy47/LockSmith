import XCTest
import TrailBlazer
@testable import LockSmith

class LSFileLockTests: XCTestCase {
    lazy var runDir: DirectoryPath = {
        return DirectoryPath("/tmp/\(self.name)")!
    }()

    func lockAndUnlockOneTest() {
        XCTAssertNoThrow(try runDir.create(options: .createIntermediates))
 
        var testFile = runDir + FilePath("testFile.txt")!
        XCTAssertNoThrow(try testFile.create())

        XCTAssertNoThrow(try testFile.lock())
        XCTAssertTrue(testFile.isLocked)
        XCTAssertNoThrow(try testFile.unlock())
        XCTAssertFalse(testFile.isLocked)

        try? runDir.recursiveDelete()
    }

    func lockAndUnlockManyTest() {
        XCTAssertNoThrow(try runDir.create(options: .createIntermediates))

        let file1 = runDir + FilePath("testFile1.txt")!
        let file2 = runDir + FilePath("testFile2.txt")!
        let file3 = runDir + FilePath("testFile3.txt")!

        let toLock = [file1, file2, file3]

        XCTAssertTrue(LockSmith.lock(toLock).isEmpty)
        XCTAssertTrue(toLock.reduce(true, { guard $0 else { return $0 }; return $1.isLocked }))
        XCTAssertTrue(LockSmith.lock(toLock).isEmpty)
        XCTAssertFalse(toLock.reduce(false, { guard !$0 else { return $0 }; return $1.isLocked }))

        try? runDir.recursiveDelete()
    }

    static var allTests = [
        ("lockAndUnlockOneTest", lockAndUnlockOneTest),
        ("lockAndUnlockManyTest", lockAndUnlockManyTest),
    ]
}


