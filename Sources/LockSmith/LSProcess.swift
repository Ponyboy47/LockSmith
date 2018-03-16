import Foundation
import FileSmith
import ErrNo

#if os(Linux)
import Glibc
#else
import Darwin
#endif

public final class LSProcess: Hashable {
    public internal(set) var pid: PID
    public internal(set) var arguments: [String]?
    public internal(set) var name: String

    // These have not been implemented on Linux yet
    #if !os(Linux)
    public internal(set) var username: String
    public internal(set) var fullUserName: String?
    #endif

    public var hashValue: Int {
        return pid.hashValue
    }

    internal var pidFile: FilePath
    internal var lockFile: FilePath

    internal lazy var processLock: LSProcessLock = {
        LSProcessLock(self)
    }()

    public var locked: Bool { return lockFile.exists() && isRunning }
    public var isRunning: Bool { return LSProcess.isRunning(pid) }

    static var argSeparator: String = "', '"
    #if !os(Linux)
    internal enum Keys: String {
        case pid
        case arguments
        case name
        case username
        case fullUserName
    }
    #else
    internal enum Keys: String {
        case pid
        case arguments
        case name
    }
    #endif

    public static func isRunning(_ pid: PID) -> Bool {
        guard kill(pid, 0) == 0 else {
            if let perror = lastError() {
                switch perror {
                case ESRCH: return false
                default: return true
                }
            }
            return false
        }
        return true
    }

    internal init(_ runDirectory: String) {
        let info = ProcessInfo.processInfo

        lockFile = DirectoryPath(runDirectory) + FilePath("\(info.processName).lock")
        pidFile = DirectoryPath(runDirectory) + FilePath("\(info.processName).pid")

        pid = info.processIdentifier
        arguments = info.arguments
        name = info.processName

        // These are not yet implemented on linux
        #if !os(Linux)
        username = info.userName
        fullUserName = info.fullUserName
        #endif
    }

    internal init(from filepath: FilePath) throws {
        guard filepath.exists() else {
            throw LockSmithError.LockError.doesNotExist(type: "process")
        }

        let current = Directory.current
        Directory.current = try filepath.parent().open()
        defer { Directory.current = current }

        lockFile = filepath

        // Set some defaults to ensure these get set while reading the file
        self.pid = -1
        self.name = ""
        #if !os(Linux)
        self.username = ""
        #endif

        let lock = try ReadableFile(open: lockFile)
        for line in lock.lines().filter({ !$0.isEmpty }) {
            var comps = line.components(separatedBy: " => ")
            guard comps.count >= 2 else {
                throw LockSmithError.LockError.corruptFile(location: filepath)
            }
            guard let key = Keys(rawValue: comps.remove(at: 0)) else {
                throw LockSmithError.LockError.corruptFileKey(location: filepath)
            }

            let value = comps.joined(separator: " => ")
            guard !value.isEmpty else {
                throw LockSmithError.LockError.corruptFileValue(location: filepath, key: key.rawValue, value: "")
            }

            #if !os(Linux)
            switch key {
            case .pid:
                guard let pid = PID(value) else {
                    throw LockSmithError.corruptLockFileValue(location: filepath, key: key.rawValue, value: value)
                }
                self.pid = pid
            case .arguments:
                let args = value.components(separatedBy: Process.argsSeparator)
                guard !args.isEmpty else {
                    throw LockSmithError.corruptLockFileValue(location: filepath, key: key.rawValue, value: value)
                }
                self.arguments = args
            case .name:
                self.name = value
            case .username:
                self.username = value
            case .fullUserName:
                self.fullUserName = value
            }
            #else
            switch key {
            case .pid:
                guard let pid = PID(value) else {
                    throw LockSmithError.LockError.corruptFileValue(location: filepath, key: key.rawValue, value: value)
                }
                self.pid = pid
            case .arguments:
                let args = value.components(separatedBy: "', '")
                guard !args.isEmpty else {
                    throw LockSmithError.LockError.corruptFileValue(location: filepath, key: key.rawValue, value: value)
                }
                self.arguments = args
            case .name:
                self.name = value
            }
            #endif
        }

        pidFile = FilePath(filepath.string.replacingOccurrences(of: ".lock", with: ".pid"))

        guard self.pid > 0 else {
            throw LockSmithError.LockError.corruptFileValue(location: filepath, key: Keys.pid.rawValue, value: "nil")
        }
        guard !self.name.isEmpty else {
            throw LockSmithError.LockError.corruptFileValue(location: filepath, key: Keys.name.rawValue, value: "nil")
        }
        #if !os(Linux)
        guard !self.username.isEmpty else {
            throw LockSmithError.LockError.corruptFileValue(location: filepath, key: Keys.username.rawValue, value: "nil")
        }
        #endif
    }

    internal func lock() -> Bool {
        let current = Directory.current
        guard let new = try? pidFile.parent().open() else { return false }
        Directory.current = new
        defer { Directory.current = current }

        let processFiles = Directory.current.files("\(name).{pid,lock}")
        for file in processFiles {
            if file.string.hasSuffix(".pid") {
                guard let pidFile = try? file.open() else { return false }

                guard let pid = PID(pidFile.read()) else { return false }

                guard !LSProcess.isRunning(pid) else { return false }
            } else {
                guard let existingProcess = try? LSProcess(from: file) else { return false }

                guard !existingProcess.isRunning else { return false }
            }

            do { try file.edit().delete() } catch { return false }
        }

        // Should only throw here if we lost a race-condition
        guard let openPIDFile = try? pidFile.create(ifExists: .throwError) else { return false }
        openPIDFile.write(String(pid))

        guard self.validate(pidFile, contents: pid) else { return false }

        var lockFileContents = "\(Keys.pid.rawValue) => \(pid)\n"
        lockFileContents += "\(Keys.name.rawValue) => \(name)\n"
        if !(arguments?.isEmpty ?? true) {
            lockFileContents += "\(Keys.arguments.rawValue) => \(arguments!.joined(separator: LSProcess.argSeparator))\n"
        }

        #if !os(Linux)
        lockFileContents += "\(Keys.username.rawValue) => \(username!)\n"
        lockFileContents += "\(Keys.fullUserName.rawValue) => \(fullUserName!)\n"
        #endif

        // Should only throw here if we lost a race-condition
        guard let writableLockFile = try? lockFile.create(ifExists: .throwError) else { return false }
        writableLockFile.write(lockFileContents)
        guard validate(lockFile, contents: lockFileContents) else { return false }

        return true
    }

    internal func unlock() -> Bool {
        let current = Directory.current
        guard let new = try? pidFile.parent().open() else { return false }
        Directory.current = new
        defer { Directory.current = current }

        do { try pidFile.create(ifExists: .open).delete() } catch { return false }
        do { try lockFile.create(ifExists: .open).delete() } catch { return false }

        return true
    }

    private func validate<C: Validatable>(_ filepath: FilePath, contents: C) -> Bool {
        guard let strValue = try? filepath.open().read() else { return false }
        guard let value = C(strValue) else { return false }
        return value == contents
    }

    public static func == (lhs: LSProcess, rhs: LSProcess) -> Bool {
        return lhs.pid == rhs.pid
    }
}

fileprivate protocol Validatable: Equatable, CustomStringConvertible {
    init?(_ string: String)
}
extension PID: Validatable {}
extension String: Validatable {
    init?(_ string: String) { self = string }
}
