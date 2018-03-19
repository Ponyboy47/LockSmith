import Foundation
import PathKit

final class LSFileLock: LSLock {
    private var lockFile: Path { return file! + ".lock" }
    private static var lockContents: String = {
        "\(ProcessInfo.processInfo.processIdentifier) \(ProcessInfo.processInfo.processName)"
    }()

    override public var isLocked: Bool { return file != nil && lockFile.isFile }

    convenience init(_ file: Path) {
        self.init(.file(file))
    }

    @discardableResult override func lock() -> Bool {
        guard file != nil else { return false }
        guard !lockFile.isFile else { return validateLock() }

        do {
            try lockFile.write(LSFileLock.lockContents)
        } catch { return false }

        return validateLock()
    }

    private func validateLock() -> Bool {
        guard file != nil else { return false }
        guard lockFile.isFile else { return false }

        do {
            return try lockFile.read() == LSFileLock.lockContents
        } catch { return false }
    }

    @discardableResult override func unlock() -> Bool {
        guard validateLock() else { return false }

        do {
            try lockFile.delete()
        } catch { return false }

        return true
    }

    public static func check(_ filepath: Path) -> Bool {
        return LSFileLock(filepath).isLocked
    }
}

extension LockSmith {
    @discardableResult public func lock(paths filepaths: [Path]) -> Bool {
        return lock(filepaths.map { .file($0) })
    }

    @discardableResult public func lock(_ filepaths: Path...) -> Bool {
        return lock(paths: filepaths)
    }

    @discardableResult public func unlock(paths filepaths: [Path]) -> Bool {
        return unlock(filepaths.map { .file($0) })
    }

    @discardableResult public func unlock(_ filepaths: Path...) -> Bool {
        return unlock(paths: filepaths)
    }
}
