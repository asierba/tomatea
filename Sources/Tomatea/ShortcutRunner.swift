import Foundation

enum ShortcutRunner {
    static func run(_ name: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["run", name]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw ShortcutError(name: name)
        }
    }

    static func existingNames() throws -> Set<String> {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["list"]
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        try process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return Set(String(decoding: data, as: UTF8.self).split(separator: "\n").map(String.init))
    }
}

struct ShortcutError: LocalizedError {
    let name: String

    var errorDescription: String? {
        "Couldn't run the \"\(name)\" shortcut. Check it exists in Shortcuts."
    }
}
