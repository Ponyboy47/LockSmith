import Foundation

public typealias PID = Int32

public enum LockSmithError: Error {
    case previousInstance(PID)
}

public final class LockSmith {
    public var pid: PID!

    public init(allowMultipleInstances multi: Bool = false) throws {
        let info = ProcessInfo.processInfo
    }
}
