import PathKit

public enum LSLockInfo: Hashable {
    case file(Path)
    case thread(ThreadID)
    case process(LSProcess)

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
        return false
    }
}

open class LSLock: Hashable {
    private let info: LSLockInfo
    internal var file: Path?
    internal var thread: ThreadID?
    internal var process: LSProcess?

    public var hashValue: Int {
        return info.hashValue
    }

    public var isLocked: Bool {
        fatalError("isLocked must be implemented in its subclasses")
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
        fatalError("lock() must be implemented in its subclasses")
    }

    @discardableResult func unlock() -> Bool {
        fatalError("unlock() must be implemented in its subclasses")
    }

    public static func == (lhs: LSLock, rhs: LSLock) -> Bool {
        return lhs.info == rhs.info
    }

    public static func check(_ lockInfo: LSLockInfo) -> Bool {
        return LSLock(lockInfo).isLocked
    }

    deinit {
        guard unlock() else {
            print("Could not unlock \(self)")
            return
        }
    }
}
