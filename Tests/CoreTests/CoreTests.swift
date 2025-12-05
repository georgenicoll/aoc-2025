import Testing
@testable import Core

@Test
func testMissingFileThrowsFileNotFound() {
  #expect(throws: FileError.fileNotFound) {
    _ = try readFileLineByLine(
      file: getFileSibling(#filePath, "Files/missingFile.txt"),
      into: [String](),
    ) { _, _ in }
  }
}

private func runFileLoadTest(_ fileName: StaticString, _ expectedLines: [String]) {
  let lines = try! readFileLineByLine(
    file: getFileSibling(#filePath, "Files/\(fileName)"),
    into: [String](),
  ) { context, line in
    context.append(line)
  }
  #expect(lines == expectedLines)
}

@Test
func testLoadSingleLine() {
  runFileLoadTest("singleLine.txt", ["This is a single line"])
}

@Test
func testLoadMultipleWithEmptyLine() {
  runFileLoadTest(
    "multipleWithEmpty.txt",
    [
      "first line",
      "",
      "last line",
    ]
  )
}

@Test
func testIgnoreEmptyLastLine() {
  runFileLoadTest(
    "emptyLastLine.txt",
    [
      "first line",
      "second line",
    ]
  )
}

@Test(arguments: 1...100)
func testLoadSmallBuffer(bufferSize: Int) {
  let lines = try! readFileLineByLine(
    file: getFileSibling(#filePath, "Files/smallBuffer.txt"),
    into: [String](),
    bufferSize: bufferSize,
  ) { context, line in
    context.append(line)
  }
  #expect(lines == [
      "first line",
      "second line",
      "third line",
      "fourth line",
      "fifth line",
      "sixth line",
      "seventh line",
      "eighth line",
      "ninth line",
      "tenth line",
  ])
}

@Test
func testReadEntireEmpty() {
  let contents = try! readEntireFile(
    getFileSibling(#filePath, "Files/entireFileEmpty.txt")
  )
  #expect(contents == "")
}

@Test
func testReadEntireFile1() {
  let contents = try! readEntireFile(
    getFileSibling(#filePath, "Files/entireFile1.txt")
  )
  #expect(contents == """
    This is a file
    It should contain everything
    """)
}

@Test
func testReadEntireFile2() {
  let contents = try! readEntireFile(
    getFileSibling(#filePath, "Files/entireFile2.txt")
  )
  #expect(contents == """
    This is another file
    It should
    contain everything
    again
    when loaded
    """)
}

@Test
func testReadEntireFileNoFile() {
  #expect(throws: FileError.fileNotFound) {
    _ = try readEntireFile(getFileSibling(#filePath, "Files/missingFile.txt"))
  }
}
