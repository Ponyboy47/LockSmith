import PathKit

public enum LockSmithError: Error {
    enum LockError: Error {
        case doesNotExist(type: String)
        case corruptFile(location: Path)
        case corruptFileKey(location: Path)
        case corruptFileValue(location: Path, key: String, value: String)
    }

    enum PIDFileError: Error {
        case corruptFile(Path)
    }

    case deadProcess(forPID: PID)
    case existingProcess(withPID: PID)
    case maximumInstancesExist
    case unlockError
}
