import Core
import Foundation

@main
struct App {

  static func main() {
    // let file = getFileSibling(#filePath, "Files/example.txt")
    let file = getFileSibling(#filePath, "Files/input.txt")

    print("\(#fileID): \(#filePath) - \(file)")
  }

}
