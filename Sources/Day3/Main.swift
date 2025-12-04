import Core
import Foundation

enum Day3Error: Error {
  case digitNotFound
}

private func maxValueRecursion(
  _ maxLevel: Int,
  _ level: Int,
  _ characters: inout [String.Element],
  _ levelStart: Int,
  _ gatheredCharacters : inout [String.Element],
) throws -> Int {
  //Max level reached?  what's this number?
  if level == maxLevel {
    return Int(String(gatheredCharacters))!
  }
  //Iterate over the remaining characters looking for the highest digit
  var maxDigit = -1
  var maxDigitIndex = -1
  for i in levelStart...(characters.count - (maxLevel - level)) {
    let digit = Int(String(characters[i]))!
    if digit > maxDigit {
      maxDigit = digit
      maxDigitIndex = i
      if digit == 9 { //no point in looking further if we find a 9
        break
      }
    }
  }
  if maxDigitIndex == -1 {
    throw Day3Error.digitNotFound
  }
  gatheredCharacters.append(characters[maxDigitIndex])
  return try maxValueRecursion(maxLevel, level + 1, &characters, maxDigitIndex + 1, &gatheredCharacters)
}

private func maxValue(_ maxLevel: Int, _ line: String) -> Int {
  var characters = Array(line)
  var gatheredCharacters = [String.Element]()
  gatheredCharacters.reserveCapacity(maxLevel)
  return try! maxValueRecursion(maxLevel, 0, &characters, 0, &gatheredCharacters)
}

@main
struct App {

  static func main() {
    let file = getFileSibling(#filePath, "Files/input.txt")
    let banks = try! readFileLineByLine(file: file, into: [String]()) { $0.append($1) }

    let part1 = banks.reduce(0) { sum, line in
      sum + maxValue(2, line)
    }
    print(part1)

    let part2 = banks.reduce(0) { sum, line in
      sum + maxValue(12, line)
    }
    print(part2)
   }

}
