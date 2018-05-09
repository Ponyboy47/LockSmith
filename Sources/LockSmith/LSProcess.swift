import Foundation
import PathKit
import ErrNo

#if os(Linux)
import Glibc
#else
import Darwin
#endif

public final class LSProcess: Lockable {
    var pid: PID
    var arguments: [String]?
    var name: String
    var username: String = ""

    public var description: String {
        return "\(type(of: self))(pid: \(pid), name: \(name), username: \(username))"
    }

    public var hashValue: Int {
        return pid.hashValue
    }

    var pidFile: Path
    var lockFile: Path

    lazy var processLock: LSProcessLock = {
        LSProcessLock(self)
    }()

    public var isLocked: Bool { return lockFile.exists && isRunning }
    var isRunning: Bool { return LSProcess.isRunning(pid) }

    private static var argSeparator: String = "', '"
    enum Keys: String {
        case pid
        case arguments
        case name
        case username
    }

    static func isRunning(_ pid: PID) -> Bool {
        guard kill(pid, 0) == 0 else {
            switch ErrNo.lastError {
            case ESRCH: return false
            default: return true
            }
        }
        return true
    }

    init(_ runDirectory: Path) {
        let info = ProcessInfo.processInfo

        lockFile = runDirectory + "\(info.processName).lock"
        pidFile = runDirectory + "\(info.processName).pid"

        pid = info.processIdentifier
        arguments = info.arguments
        name = info.processName

        let pw = getpwuid(geteuid())
        if let usernameBytes = pw?.pointee.pw_name {
            username = String(cString: usernameBytes)
        }
    }

    init(from filepath: Path) throws {
        guard filepath.exists else {
            throw LockSmithError.LockError.doesNotExist(type: "process")
        }

        lockFile = filepath

        // Set some defaults to ensure these get set while reading the file
        self.pid = -1
        self.name = ""

        for line in try lockFile.read().components(separatedBy: "\n").filter({ !$0.isEmpty }) {
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
            case .username:
                self.username = value
            }
        }

        pidFile = Path(filepath.string.replacingOccurrences(of: ".lock", with: ".pid"))

        guard self.pid > 0 else {
            throw LockSmithError.LockError.corruptFileValue(location: filepath, key: Keys.pid.rawValue, value: "nil")
        }
        guard !self.name.isEmpty else {
            throw LockSmithError.LockError.corruptFileValue(location: filepath, key: Keys.name.rawValue, value: "nil")
        }
    }

    public func lock() -> Bool {
        let processFiles = pidFile.parent.absolute.glob("\(name).{pid,lock}")
        for file in processFiles {
            if file.string.hasSuffix(".pid") {
                guard let pidContents: String = try? file.read() else { return false }
                guard let pid = PID(pidContents) else { return false }

                guard !LSProcess.isRunning(pid) else { return false }
            } else {
                guard let existingProcess = try? LSProcess(from: file) else { return false }

                guard !existingProcess.isRunning else { return false }
            }

            do { try file.delete() } catch { return false }
        }

        var lockFileContents = "\(Keys.pid.rawValue) => \(pid)\n"
        lockFileContents += "\(Keys.name.rawValue) => \(name)\n"
        if !(arguments?.isEmpty ?? true) {
            lockFileContents += "\(Keys.arguments.rawValue) => \(arguments!.joined(separator: LSProcess.argSeparator))\n"
        }
        if !username.isEmpty {
            lockFileContents += "\(Keys.username.rawValue) => \(username)\n"
        }

        // Should only throw here if we lost a race-condition
        guard !pidFile.isFile else { return false }
        guard !lockFile.exists else { return false }

        do {
            try pidFile.write(String(pid))
            try lockFile.write(lockFileContents)
         } catch { return false }

        guard validate(pidFile, contents: pid) else { return false }
        guard validate(lockFile, contents: lockFileContents) else { return false }

        return true
    }

    public func unlock() -> Bool {
        do {
            try pidFile.delete()
            try lockFile.delete()
        } catch { return false }

        return true
    }

    private func validate<C: Validatable>(_ filepath: Path, contents: C) -> Bool {
        guard let strValue: String = try? filepath.read() else { return false }
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
