# LockSmith

LockSmith is meant to be a system lock manager for swift executables.

By creating a LockSmith instance, you are locking down your current swift executable so that no other instance can be running. You also gain access to easy locking mechanisms for files and threads to help make you program thread-safe.

## Installation
Installation can be done through the Swift Package Manager

Add the following line to your dependencies in you `Package.swift` file
```swift
.package(url: "https://github.com/Ponyboy47/LockSmith.git", from: "0.2.0")
```

## Usage

In your main.swift:
```swift
import LockSmith

guard var processLock = LockSmith.singleton else {
    print("Another instance of your executable is already running")
}

// Your executable code here...

// This forces the destructor to be called, which unlocks any leftover locks (like the process lock)
processLock = nil

// the end
```

More examples later...

## License
MIT
