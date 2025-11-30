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
  //let applicanceRegex = /Name: (?<name>[^\s]+).*Type: (?<type>[^\s]+).*Age: (?<age>\d+)/
  let applicanceRegex =
    /Name: (?<name>[^\s]+).*?Type: (?<type>[^\s]+).*?Age: (?<age>\d+)/
    .dotMatchesNewlines()
  return contents.matches(of: applicanceRegex).map { regex in
    Appliance(
      name: String(regex.name),
      type: ApplianceType(rawValue: String(regex.type))!,
      age: Int(regex.age)!
    )
  }
}

@main
struct App {

  static func main() {
    let parsed = parse(try! readEntireFile(getSourceFileSibling(#filePath, "Files/input.txt")))
    print(parsed)
  }

}
