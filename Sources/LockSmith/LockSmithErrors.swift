import FileSmith

public enum LockSmithError: Error {
    enum LockError: Error {
        case doesNotExist(type: String)
        case corruptFile(location: FilePath)
        case corruptFileKey(location: FilePath)
        case corruptFileValue(location: FilePath, key: String, value: String)
    }

    enum PIDFileError: Error {
        case corruptFile(FilePath)
    }

    case deadProcess(forPID: PID)
    case existingProcess(withPID: PID)
    case maximumInstancesExist
    case unlockError
}
