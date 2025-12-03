import Core
import Foundation
import RegexBuilder

@main
struct App {

  static func main() {
    let regex = /key="(?<key>[^"]*)".*?value="(?<value>[^"]*)"/
    var context = [[String:String]]()
    let loaded = try! readFileLineByLine(
      getFileSibling(#filePath, "Files/input.txt"),
      &context,
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
