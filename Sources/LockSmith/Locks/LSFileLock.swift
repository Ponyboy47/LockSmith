import Foundation
import PathKit

public typealias LSFileLock = LSLock<Path>

extension Path: Lockable {
    private static var lockContents: String = {
        "\(ProcessInfo.processInfo.processIdentifier) \(ProcessInfo.processInfo.processName)"
    }()

    var lockFile: Path { return Path(self.string + ".lock") }
    public var isLocked: Bool { return isFile && lockExists }
    private var lockExists: Bool { return lockFile.exists }

    @discardableResult public func lock() -> Bool {
        guard !isLocked else { return checkLockOwner() }

        guard (try? lockFile.write(Path.lockContents)) != nil else { return false }

        return isLocked && checkLockOwner()
    }

    /// Returns whether the lock is owned by the current process
    private func checkLockOwner() -> Bool {
        guard let contents: String = try? lockFile.read() else { return false }

        return contents == Path.lockContents
    }

    @discardableResult public func unlock() -> Bool {
        guard isLocked else { return true }
        guard checkLockOwner() else { return false }

        return (try? lockFile.delete()) != nil
    }
}
