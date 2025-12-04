import Core
import Foundation
import RegexBuilder

@main
struct App {

  static func main() {
    let regex = /key="(?<key>[^"]*)".*?value="(?<value>[^"]*)"/
    let loaded = try! readFileLineByLine(
      file: getFileSibling(#filePath, "Files/input.txt"),
      into: [[String:String]](),
    ) { context, line in
      var keyValues = [String:String]()
      for match in line.matches(of: regex) {
        keyValues[String(match.key)] = String(match.value)
      }
      context.append(keyValues)
    }
    print(loaded)
  }

}
