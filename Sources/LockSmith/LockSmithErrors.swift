import struct TrailBlazer.FilePath

public enum LockSmithError: Error {
    public enum LockError: Error {
        case doesNotExist(type: String)
        case corruptFile(location: FilePath)
        case corruptFileKey(location: FilePath)
        case corruptFileValue(location: FilePath, key: String, value: String)
        case failedToLock(reason: String)
        case processStillRunning(withPID: PID)
    }

    public enum UnlockError: Error {
        case failedToUnlock(reason: String)
    }

    public enum PIDFileError: Error {
        case corruptFile(FilePath)
        case invalidPID(String)
    }

    public enum StringError: Error {
        case notConvertible(using: String.Encoding)
    }

    case deadProcess(forPID: PID)
    case existingProcess(withPID: PID)
    case unknownRunDirectory
    case maximumInstancesExist
    case unownedLock
}
