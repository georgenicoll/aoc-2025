import Core
import Foundation
import RegexBuilder

enum Direction: String {
  case l = "L"
  case r = "R"
}

struct Instruction {
  let direction: Direction
  let steps: Int
}

fileprivate func parse(_ content: String) -> [Instruction] {
  let regex = /(?<direction>\w)(?<steps>\d+)/.dotMatchesNewlines()
  return content.matches(of: regex).map { match in
    Instruction(
      direction: Direction(rawValue: String(match.output.direction))!,
      steps: Int(match.output.steps)!
    )
  }
}

/// - Returns: (number of times that we hit 0, number of times we cross 0)
fileprivate func runInstructions(instructions: [Instruction], numSlots: Int, startingPoint: Int) -> (Int, Int) {

  var exactZeros = 0
  var zeroCrossings = 0
  var current = startingPoint

  for instruction in instructions {
    let rotations = instruction.steps / numSlots
    let remainder = instruction.steps % numSlots

    zeroCrossings += rotations

    func calcNextNoMod() -> Int {
      switch instruction.direction {
      case .l:
        return current - remainder
      case .r:
        return current + remainder
      }
    }

    let nextNoMod = calcNextNoMod()
    if nextNoMod < 0 {
      zeroCrossings += (current == 0 ? 0 : 1) // Crossed going left if we weren't at 0 so inc
    }
    if nextNoMod == 0 || nextNoMod == numSlots {
      exactZeros += (remainder > 0 || rotations > 0 ? 1 : 0) // Actually moved to get here then inc
      zeroCrossings -= (remainder == 0 && rotations > 0 ? 1 : 0) // Moved a multiple to get here then dec the crossings
    }
    if nextNoMod > numSlots {
      zeroCrossings += (current == 0 ? 0 : 1) // Crossed going right if we weren't at 0 so inc
    }

    current = (nextNoMod + numSlots) % numSlots // Ensure it's a +ve modulus
  }

  return (exactZeros, zeroCrossings)
}

@main
struct App {

  static func main() {
    // let instructions = parse(try! readEntireFile(getSourceFileSibling(#filePath, "Files/example.txt")))
    // let instructions = parse(try! readEntireFile(getSourceFileSibling(#filePath, "Files/example2.txt")))
    let instructions = parse(try! readEntireFile(getFileSibling(#filePath, "Files/input.txt")))
    let (exactZeros, zeroPasses) = runInstructions(instructions: instructions, numSlots: 100, startingPoint: 50)
    print("Exact Zeros (Part 1): \(exactZeros)")
    print("Clicks in passing: \(zeroPasses)")
    print("Exact + Passing (Part 2): \(exactZeros + zeroPasses)")
  }

}
