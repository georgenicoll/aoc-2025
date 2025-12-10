import Core
import Foundation

enum OnOff: String, CustomStringConvertible {
  case on = "#"
  case off = "."

  var description: String {
    return self.rawValue
  }

  func toggle() -> OnOff {
    return self == .on ? .off : .on
  }
}

class PuzzleLine: CustomStringConvertible {
  let requiredConfiguration: [OnOff]
  let toggles: [[Int]]
  let joltageRequirement: [Int]

  init(requiredConfiguration: [OnOff], toggles: [[Int]], joltageRequirement: [Int]) {
    self.requiredConfiguration = requiredConfiguration
    self.toggles = toggles
    self.joltageRequirement = joltageRequirement
  }

  var description: String {
    return "\(requiredConfiguration) \(toggles) \(joltageRequirement)"
  }
}

private func handleLine(_ lines: inout [PuzzleLine], line: String) {
  let lineRegex = /\[(?<required>[^\}]+)\] |\((?<toggle>[^\)]+?)\) |\{(?<joltage>[^\}]+)\}/
  let matches = line.matches(of: lineRegex)
  let requiredConfiguration = (matches.first!.required).map({req in
    req.map{ OnOff(rawValue: String($0))! }
  })!
  let toggles = matches.dropFirst().dropLast().map({ match in
    let togglesString = match.toggle!
    return togglesString.components(separatedBy: ",").map{ Int($0)! }
  })
  let joltageRequirement = matches.last!.joltage.map({ joltage in
    joltage.components(separatedBy: ",").map({ Int($0)! })
  })!
  lines.append(PuzzleLine(requiredConfiguration: requiredConfiguration, toggles: toggles, joltageRequirement: joltageRequirement))
}

private func calcToggles(_ line: PuzzleLine) -> Int {
  var foundConfigurations = [[OnOff]:Int]()
  let emptyLine = line.requiredConfiguration.map { _ in OnOff.off }
  foundConfigurations[emptyLine] = 0
  for rep in 1...10000 {
    var newConfigurations = [[OnOff]:Int]()
    for toggles in line.toggles {
      for foundConfiguration in foundConfigurations.keys {
        var newConfiguration = foundConfiguration
        for toggle in toggles {
          newConfiguration[toggle] = newConfiguration[toggle].toggle()
        }
        if newConfiguration == line.requiredConfiguration {
          // We got what we need on this rep
          return rep
        }
        if foundConfigurations.keys.contains(newConfiguration) {
          // already had this in same or less
          continue
        }
        //first time we saw it
        newConfigurations[newConfiguration] = rep
      }
    }
    //Add the new ones in to search next time
    foundConfigurations.merge(newConfigurations) { (original, _) in original }
  }
  print("Failed on: \(line)")
  return -1
}

private func part1(_ lines: [PuzzleLine]) -> Int {
  return lines.reduce(0) { acc, line in
    return acc + calcToggles(line)
  }
}

@main
struct App {

  static func main() {
    //let file = getFileSibling(#filePath, "Files/example.txt")
    let file = getFileSibling(#filePath, "Files/input.txt")

    let lines = try! readFileLineByLine(file: file, into: [PuzzleLine](), handleLine)
    // print(lines)

    let part1 = part1(lines)
    print(part1)

    print("Part 2 using python & pulp (run python Sources/Day10/main.py)")
  }

}
