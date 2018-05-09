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
    /// The username that ran the current swift process
    public lazy var username: String = { return process.username }()

    /**
    Initializes the LockSmith

    - Parameters:
        - runDirectory: The directory where you wish to store and check for process .pid and .lock files
                        default: /var/run

                        NOTE: macOS still uses /var/run by default, most linux distros just use /run now, but they symlink /var/run to /run, so /var/run should be cross-system compatible
    */
    public init?(_ runDirectory: Path = "/var/run") {
        if runDirectory == "/var/run" && geteuid() != 0 { return nil }
        process = LSProcess(runDirectory)
        guard process.processLock.lock() else { return nil }
    }

    /**
    Lock the provided LSLocks

    - Parameter locks: An Array of LSLocks that should be locked
    - Returns: The locks that were not locked
    */
    @discardableResult public func lock<L>(_ locks: [LSLock<L>]) -> [LSLock<L>] {
        return LockSmith.lock(locks)
    }
    /**
    Lock the provided LSLocks

    - Parameter locks: An Array of LSLocks that should be locked
    - Returns: Whether or not all of the locks were successfully locked
    */
    @discardableResult public static func lock<L>(_ locks: [LSLock<L>]) -> [LSLock<L>] {
        return locks.filter() { !$0.lock() }
    }

    /**
    Lock the provided Lockables

    - Parameter locks: An Array of Lockable objects that should be locked
    - Returns: Whether or not all of the locks were successfully locked
    */
    @discardableResult public func lock<L: Lockable>(_ items: [L]) -> [L] {
        return LockSmith.lock(items)
    }
    /**
    Lock the provided Lockables

    - Parameter locks: An Array of Lockable objects that should be locked
    - Returns: Whether or not all of the locks were successfully locked
    */
    @discardableResult public static func lock<L: Lockable>(_ items: [L]) -> [L] {
        return items.filter() { !$0.lock() }
    }

    /**
    Unlock the provided LSLocks

    - Parameter locks: An Array of LSLocks that should be unlocked
    - Returns: Whether or not all of the locks were successfully unlocked
    */
    @discardableResult public func unlock<L>(_ locks: [LSLock<L>]) -> [LSLock<L>] {
        return LockSmith.unlock(locks)
    }
    /**
    Unlock the provided LSLocks

    - Parameter locks: An Array of LSLocks that should be unlocked
    - Returns: Whether or not all of the locks were successfully unlocked
    */
    @discardableResult public static func unlock<L>(_ locks: [LSLock<L>]) -> [LSLock<L>] {
        return locks.filter() { !$0.unlock() }
    }

    /**
    Unlock the provided Lockables

    - Parameter locks: An Array of Lockable objects that should be unlocked
    - Returns: Whether or not all of the locks were successfully unlocked
    */
    @discardableResult public func unlock<L: Lockable>(_ items: [L]) -> [L] {
        return LockSmith.unlock(items)
    }
    /**
    Unlock the provided Lockables

    - Parameter locks: An Array of Lockable objects that should be unlocked
    - Returns: Whether or not all of the locks were successfully unlocked
    */
    @discardableResult public static func unlock<L: Lockable>(_ items: [L]) -> [L] {
        return items.filter() { !$0.unlock() }
    }
}
