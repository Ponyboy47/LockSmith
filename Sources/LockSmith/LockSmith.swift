import PathKit

#if os(Linux)
import Glibc
#else
import Darwin
#endif

/// The type for a process's identifier (Should just be Int32)
public typealias PID = pid_t
/// The type for a thread's identifier (I'm not doing anything with this yet, so this is subject to change)
public typealias ThreadID = Int32

/// A class that includes mechanisms for locking a swift process, files, or critical sections
public final class LockSmith {
    /**
    A LockSmith that uses the default /run/var directory. It's recommended
    that you always use this in your swift project, unless you need to allow
    multiple instances of your swift executable to run simultaneously. Then
    you have to specify different runDirectories for each process and track
    all of your different LockSmith instances. The nice thing about using
    singleton is that you can easily grab your LockSmith anywhere in you
    project by using singleton. No worrying about passing it around or making
    a global varialble
    */
    public static var singleton: LockSmith? {
        return LockSmith()
    }

    /// Contains information about the current swift process (a wrapper around
    /// ProcessInfo, formerly NSProcessInfo)
    private let process: LSProcess

    /// The PID of the current swift process
    public lazy var pid: PID = { return process.pid }()
    /// The name of the current swift process
    public lazy var name: String = { return process.name }()
    /// The arguments of the current swift process
    public lazy var arguments: [String]? = { return process.arguments }()

    /// The current items that are locked. Should always contain at least 1
    /// (since the current swift process is automatically locked during
    /// initialization)
    private var locks: Set<LSLock> = Set([])

    /**
    Initializes the LockSmit

    - Parameters:
        - runDirectory: The directory where you wish to store and check for process .pid and .lock files
                        default: /var/run

                        NOTE: macOS still uses /var/run by default, most linux distros just use /run now, but they symlink /var/run to /run, so /var/run should be cross-system compatible
    */
    public init?(_ runDirectory: Path = "/var/run") {
        process = LSProcess(runDirectory)
        guard lock(process.processLock) else { return nil }
    }

    /**
    Lock the provided LSLocks

    - Parameter locks: An Array of LSLocks that should be locked
    - Returns: Whether or not all of the locks were successfully locked
    */
    @discardableResult public func lock(_ locks: [LSLock]) -> Bool {
        for lock in locks {
            // Already locked
            guard !self.locks.contains(lock) else { continue }
            guard lock.lock() else { return false }

            self.locks.insert(lock)
        }

        return true
    }

    /**
    Lock the provided LSLock

    - Parameter lock: An LSLock that should be locked
    - Returns: Whether or not the lock was successfully locked
    */
    @discardableResult public func lock(_ lock: LSLock) -> Bool {
        return self.lock([lock])
    }

    /**
    Creates locks for each of the LSLockInfo objects and then locks them

    - Parameter locks: An Array of LSLockInfo objects that should be locked
    - Returns: Whether or not all of the locks were successfully locked
    */
    @discardableResult public func lock(_ lockInfos: [LSLockInfo]) -> Bool {
        return lock(lockInfos.map { LSLock($0) })
    }

    /**
    Creates a lock for the LSLockInfo object and then locks it

    - Parameter lock: An LSLockInfo object that should be locked
    - Returns: Whether or not all of the locks were successfully locked
    */
    @discardableResult public func lock(_ lockInfo: LSLockInfo) -> Bool {
        return lock([lockInfo])
    }

    /**
    Unlock the provided LSLocks

    - Parameter locks: An Array of LSLocks that should be unlocked
    - Returns: Whether or not all of the locks were successfully unlocked
    */
    @discardableResult public func unlock(_ locks: [LSLock]) -> Bool {
        for lock in locks {
            // Already unlocked
            guard !locks.contains(lock) else { continue }
            guard lock.unlock() else { return false }

            self.locks.remove(lock)
        }

        return true
    }

    /**
    Unlock the provided LSLock

    - Parameter lock: An LSLock that should be unlocked
    - Returns: Whether or not the lock was successfully unlocked
    */
    @discardableResult public func unlock(_ lock: LSLock) -> Bool {
        return unlock([lock])
    }

    /**
    Creates locks for each of the LSLockInfo objects and then unlocks them

    - Parameter locks: An Array of LSLockInfo objects that should be unlocked
    - Returns: Whether or not all of the locks were successfully unlocked
    */
    @discardableResult public func unlock(_ lockInfos: [LSLockInfo]) -> Bool {
        return unlock(lockInfos.map { LSLock($0) })
    }

    /**
    Creates a lock for the LSLockInfo object and then unlocks it

    - Parameter lock: An LSLockInfo object that should be unlocked
    - Returns: Whether or not the lock was successfully unlocked
    */
    @discardableResult public func unlock(_ lockInfo: LSLockInfo) -> Bool {
        return unlock([lockInfo])
    }

    deinit {
        for lock in locks {
            guard lock.unlock() else {
                print("Failed to unlock \(lock)")
                continue
            }
        }
    }
}
