import struct TrailBlazer.DirectoryPath

#if os(Linux)
import struct Glibc.pid_t
import func Glibc.geteuid
public let systemRunDirectory = DirectoryPath("/run")!
#else
import struct Darwin.pid_t
import func Darwin.geteuid
public let systemRunDirectory = DirectoryPath("/var/run")!
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
    public static let singleton: LockSmith? = {
        return try? LockSmith()
    }()

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
                        default: /var/run on macOS or /run on Linux
    */
    public init(_ runDirectory: DirectoryPath? = nil) throws {
        if let runDir = runDirectory {
            process = LSProcess(runDir)
        } else if geteuid() == 0 {
            process = LSProcess(systemRunDirectory)
        } else { throw LockSmithError.unknownRunDirectory }
        try process.processLock.lock()
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
        return locks.filter() { (try? $0.lock()) == nil }
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
        return items.filter() { (try? $0.lock()) == nil }
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
        return locks.filter() { (try? $0.unlock()) == nil }
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
        return items.filter() { (try? $0.unlock()) == nil }
    }
}
