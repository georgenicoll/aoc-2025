import Core
import Foundation
import RegexBuilder

enum ApplianceType: String {
  case unknown = "unknown"
  case robot = "robot"
  case toaster = "toaster"
  case fridge = "fridge"
}

struct Appliance {
  let name: String
  let type: ApplianceType
  let age: Int
}

private func parse(_ contents: String) -> [Appliance] {
  let applicanceRegex =
    /Name: (?<name>[^\s]+).*?Type: (?<type>[^\s]+).*?Age: (?<age>\d+)/
    .dotMatchesNewlines()
  return contents.matches(of: applicanceRegex).map { match in
    Appliance(
      name: String(match.name),
      type: ApplianceType(rawValue: String(match.type))!,
      age: Int(match.age)!
    )
  }
}

@main
struct App {

  static func main() {
    let parsed = parse(try! readEntireFile(getFileSibling(#filePath, "Files/input.txt")))
    print(parsed)
  }

}
