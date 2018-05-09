import XCTest
import PathKit
@testable import LockSmith

class LSLockTests: XCTestCase {
    lazy var runDir: Path = {
        return Path("/tmp/\(self.name)")
    }()

    func create() {
    }

    static var allTests = [
        ("create", create)
    ]
}

