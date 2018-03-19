internal final class LSProcessLock: LSLock {
    override public var isLocked: Bool { return process?.isLocked ?? false }

    convenience init(_ process: LSProcess) {
        self.init(.process(process))
    }

    override func lock() -> Bool {
        return process?.lock() ?? false
    }

    override func unlock() -> Bool {
        return process?.unlock() ?? false
    }
}
