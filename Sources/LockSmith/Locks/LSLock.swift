import FileSmith

public enum LSLockInfo: Hashable {
    case file(FilePath)
    case thread(ThreadID)
    case process(LSProcess)
    case none

	public var hashValue: Int {
		switch self {
        case .file(let path): return path.hashValue
        case .thread(let id): return id.hashValue
        case .process(let process): return process.hashValue
        default: return 0
		}
    }

    public static func == (lhs: LSLockInfo, rhs: LSLockInfo) -> Bool {
        if case let .file(lpath) = lhs, case let .file(rpath) = rhs {
            return lpath == rpath
        } else if case let .thread(lid) = lhs, case let .thread(rid) = rhs {
            return lid == rid
        } else if case let .process(lprocess) = lhs, case let .process(rprocess) = rhs {
            return lprocess == rprocess
        }
        return lhs == .none && rhs == .none
    }
}

open class LSLock: Hashable {
    private let info: LSLockInfo
    internal var file: FilePath?
    internal var thread: ThreadID?
    internal var process: LSProcess?

    public var hashValue: Int {
        return info.hashValue
    }

    public init(_ info: LSLockInfo) {
        self.info = info
        switch info {
        case .file(let filepath): self.file = filepath
        case .thread(let thread): self.thread = thread
        case .process(let process): self.process = process
        default: return
        }
    }

    @discardableResult func lock() -> Bool {
        fatalError("lock() must be implemented in its subclass")
    }

    @discardableResult func unlock() -> Bool {
        fatalError("unlock() must be implemented in its subclass")
    }

    public static func == (lhs: LSLock, rhs: LSLock) -> Bool {
        return lhs.info == rhs.info
    }

    deinit {
        guard unlock() else {
            print("Could not unlock \(self)")
            return
        }
    }
}
