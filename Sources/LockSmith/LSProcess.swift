import ErrNo
import class Foundation.ProcessInfo
import TrailBlazer

#if os(Linux)
import func Glibc.geteuid
import func Glibc.getpwuid
import func Glibc.kill
#else
import func Darwin.geteuid
import func Darwin.getpwuid
import func Darwin.kill
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

    var pidFile: FilePath
    var lockFile: FilePath

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
            case .ESRCH: return false
            default: return true
            }
        }
        return true
    }

    init(_ runDirectory: DirectoryPath) {
        let info = ProcessInfo.processInfo

        lockFile = runDirectory + FilePath("\(info.processName).lock")!
        pidFile = runDirectory + FilePath("\(info.processName).pid")!

        pid = info.processIdentifier
        arguments = info.arguments
        name = info.processName

        let pw = getpwuid(geteuid())
        if let usernameBytes = pw?.pointee.pw_name {
            username = String(cString: usernameBytes)
        }
    }

    init(from filepath: FilePath) throws {
        guard filepath.exists else {
            throw LockSmithError.LockError.doesNotExist(type: "process")
        }

        lockFile = filepath

        // Set some defaults to ensure these get set while reading the file
        self.pid = -1
        self.name = ""

        guard let contents: String = try lockFile.read() else {
            throw LockSmithError.StringError.notConvertible(using: .utf8)
        }
        for line in contents.components(separatedBy: "\n").lazy.filter({ !$0.isEmpty }).lazy {
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

        pidFile = FilePath(filepath.string.replacingOccurrences(of: ".lock", with: ".pid"))!

        guard self.pid > 0 else {
            throw LockSmithError.LockError.corruptFileValue(location: filepath, key: Keys.pid.rawValue, value: "nil")
        }
        guard !self.name.isEmpty else {
            throw LockSmithError.LockError.corruptFileValue(location: filepath, key: Keys.name.rawValue, value: "nil")
        }
    }

    public func lock() throws {
        do {
            let globbed = try (pidFile.parent.absolute ?? pidFile.parent).glob(pattern: "\(name).{pid,lock}")

            for var file in globbed.matches.files {
                if file.string.hasSuffix(".pid") {
                    let pidContents: String = try file.read() ?! LockSmithError.LockError.failedToLock(reason: "\(file.string) is not a utf-8 encoded file")
                    guard let pid = PID(pidContents) else { throw LockSmithError.PIDFileError.invalidPID(pidContents) }

                    guard !LSProcess.isRunning(pid) else { throw LockSmithError.existingProcess(withPID: pid) }
                } else {
                    let existingProcess = try LSProcess(from: file)

                    guard !existingProcess.isRunning else { throw LockSmithError.existingProcess(withPID: pid) }
                }

                try file.delete()
            }
        } catch GlobError.noMatches {}

        var lockFileContents = "\(Keys.pid.rawValue) => \(pid)\n"
        lockFileContents += "\(Keys.name.rawValue) => \(name)\n"
        if !(arguments?.isEmpty ?? true) {
            lockFileContents += "\(Keys.arguments.rawValue) => \(arguments!.joined(separator: LSProcess.argSeparator))\n"
        }
        if !username.isEmpty {
            lockFileContents += "\(Keys.username.rawValue) => \(username)\n"
        }

        try pidFile.create(contents: String(pid))
        try lockFile.create(contents: lockFileContents)
    }

    public func unlock() throws {
        try pidFile.delete()
        try lockFile.delete()
    }

    public static func == (lhs: LSProcess, rhs: LSProcess) -> Bool {
        return lhs.arguments == rhs.arguments &&
            lhs.name == rhs.name &&
            lhs.username == rhs.username
    }
}
