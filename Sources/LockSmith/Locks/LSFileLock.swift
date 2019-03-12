import class Foundation.ProcessInfo
import struct TrailBlazer.FilePath

public typealias LSFileLock = LSLock<FilePath>

extension FilePath: Lockable {
    private static var lockContents: String = {
        "\(ProcessInfo.processInfo.processIdentifier) \(ProcessInfo.processInfo.processName)"
    }()

    var lockFile: FilePath { return FilePath(string + ".lock")! }
    public var isLocked: Bool { return isFile && lockExists }
    private var lockExists: Bool { return lockFile.exists }

    public func lock() throws {
        guard !isLocked else {
            guard checkLockOwner() else {
                throw LockSmithError.unownedLock
            }
            return
        }

        try lockFile.write(FilePath.lockContents)
    }

    /// Returns whether the lock is owned by the current process
    private func checkLockOwner() -> Bool {
        guard let contents: String = (try? lockFile.read()) ?? nil else { return false }

        return contents == FilePath.lockContents
    }

    public func unlock() throws {
        guard isLocked else { return }
        guard checkLockOwner() else { throw LockSmithError.unownedLock }

        var locker = lockFile
        try locker.delete()
    }
}
