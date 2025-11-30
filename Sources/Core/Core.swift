import Foundation

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
