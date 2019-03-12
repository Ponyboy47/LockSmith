import XCTest
import TrailBlazer
@testable import LockSmith

class LSLockTests: XCTestCase {
    lazy var runDir: DirectoryPath = {
        return DirectoryPath("/tmp/\(self.name)")!
    }()

    func create() {
    }

    static var allTests = [
        ("create", create)
    ]
}

