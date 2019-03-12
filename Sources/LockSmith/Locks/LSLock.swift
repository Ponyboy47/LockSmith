public protocol Lockable: CustomStringConvertible {
    var isLocked: Bool { get }
    func lock() throws
    func unlock() throws
}

open class LSLock<LockType: Lockable>: Lockable {
    private let toLock: LockType

    public var isLocked: Bool { return toLock.isLocked }

    public var description: String {
        return "\(type(of: self))(\(toLock.description))"
    }

    public init(_ toLock: LockType) {
        self.toLock = toLock
    }

    deinit { try? unlock() }

    public func lock() throws { try toLock.lock() }

    public func unlock() throws { try toLock.unlock() }
}

extension LSLock: Equatable where LockType: Equatable {
    public static func == (lhs: LSLock, rhs: LSLock) -> Bool {
        return lhs.toLock == rhs.toLock
    }
}

extension LSLock: Hashable where LockType: Hashable {
    public var hashValue: Int { return toLock.hashValue }
}
