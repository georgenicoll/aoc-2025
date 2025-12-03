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

  fileprivate init(
    name: String,
    type: ApplianceType = .unknown,
    age: Int = 0,
  ) {
    self.name = name
    self.type = type
    self.age = age
  }

  fileprivate func with(
    type: ApplianceType? = nil,
    age: Int? = nil,
  ) -> Appliance  {
    Appliance(
      name: self.name,
      type: type ?? self.type,
      age: age ?? self.age
    )
  }
}

struct Context {
  var loading: Appliance? = nil
  var linesProcessed: Int = 0
  var appliances: [String:Appliance] = [:]

  fileprivate mutating func addLoadingAppliance() {
    if let loading = self.loading {
      self.appliances[loading.name] = loading
    }
    self.loading = nil
  }
}

private func handleLine(_ context: inout Context, line: String) {
  let attributeMatch = /^(?<attribute>.*):\s*(?<value>.*)$/

  if let match = line.wholeMatch(of: attributeMatch) {
    switch match.attribute {
      case "Name":
        context.loading = Appliance(name: String(match.value))
      case "Type":
        context.loading = context.loading?.with(
          type: ApplianceType(rawValue: String(match.value))!
        )
      case "Age":
        context.loading = context.loading?.with(
          age: Int(match.value)!
        )
      default:
        fatalError("Unknown attribute: \(match.attribute)")
    }
  } else {
    context.addLoadingAppliance()
  }

  context.linesProcessed += 1
}

@main
struct App {

  static func main() {
    var ctx = Context()
    var context = try! readFileLineByLine(
      getFileSibling(#filePath, "Files/input.txt"),
      &ctx,
      recv: handleLine,
    )
    context.addLoadingAppliance()
    print(context)
  }

}
