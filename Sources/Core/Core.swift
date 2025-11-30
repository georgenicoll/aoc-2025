import Foundation

extension CustomStringConvertible {
    public var description: String {
        let text = "\(type(of: self)): "
        let mirror = Mirror(reflecting: self)
        let props = mirror.children.compactMap { element in
            element.label.map { "\($0): \(element.value)" }
        }.joined(separator: ", ")
        return text + (props.isEmpty ? "()" : "(\(props))")
    }
}

extension CustomDebugStringConvertible {
    public var debugDescription: String {
        let output = "\(type(of: self)): "
        let mirror = Mirror(reflecting: self)

        let properties = mirror.children.map { child in
            if let label = child.label {
                return "\(label): \(child.value)"
            }
            return "unknown"
        }

        // Also show properties from superclasses and private ones from the same file
        var allProps: [String] = properties
        var currentMirror: Mirror? = mirror.superclassMirror
        while let superMirror = currentMirror {
            let superProps = superMirror.children.compactMap { element in
                element.label.map { "\($0): \(element.value)" }
            }
            allProps.append(contentsOf: superProps)
            currentMirror = superMirror.superclassMirror
        }

        let propsString = allProps.isEmpty ? "()" : "(\(allProps.joined(separator: ", ")))"
        return output + propsString
    }
}

enum FileError: Error {
    case fileNotFound
}

public func getSourceFileSibling(_ sourceFilePath: StaticString, _ fileName: String) -> String {
    let directory = URL(fileURLWithPath: String(describing: sourceFilePath))
        .deletingLastPathComponent()
    let file = directory.appendingPathComponent(fileName)
    return file.path
}

public func readFileLineByLine<Context>(
    _ path: String,
    _ ctx: inout Context,
    bufferSize: Int = 4096,
    recv: (inout Context, String) -> Void,
) throws -> Context {
    guard let fileHandle = FileHandle(forReadingAtPath: path) else {
        throw FileError.fileNotFound
    }
    defer {
        fileHandle.closeFile()
    }

    var leftover = ""

    while true {
        let data = fileHandle.readData(ofLength: bufferSize)
        if data.isEmpty {
            break  // End of file
        }

        if let content = String(data: data, encoding: .utf8) {
            let firstIsNewLine = content.first == "\n"

            //If the first is a new line and we had a left over, the left over was actually full - process it now
            if firstIsNewLine && !leftover.isEmpty {
                recv(&ctx, leftover)
                leftover = ""
            }

            // Now trim any leading new line to continue processing
            let trimmed = firstIsNewLine ? String(content.dropFirst()) : content

            // Process any lines we find in the current trimmed buffer, keeping the last as the left over
            let lines = trimmed.split(separator: "\n", omittingEmptySubsequences: false)
            for (index, line) in lines.enumerated() {
                let fullLine = leftover + line
                leftover = ""
                if index == lines.count - 1 {
                    leftover = fullLine  // last one in lines...  we might have more coming so
                } else {
                    recv(&ctx, fullLine)
                }
            }
        }
    }

    //Finally if there was any left over, then it's the last to be processed...
    if !leftover.isEmpty {
        recv(&ctx, leftover)
    }

    return ctx
}

public func readEntireFile(_ path: String) throws -> String {
    guard let fileHandle = FileHandle(forReadingAtPath: path) else {
        throw FileError.fileNotFound
    }
    defer {
        fileHandle.closeFile()
    }
    let data = fileHandle.readDataToEndOfFile()
    return String(data: data, encoding: .utf8)!
}
