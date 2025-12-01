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

  func doStep(direction: Direction) {
    switch direction {
    case .l:
      current = (current - 1) % numSlots
    case .r:
      current = (current + 1) % numSlots
    }
  }

  // Just perform a step at a time to avoid worrying about remainders and mods
  for instruction in instructions {
    // Do all but the last step for this instruction
    for _ in 0..<(instruction.steps - 1){
      doStep(direction: instruction.direction)
      if current == 0 {
        zeroCrossings += 1
      }
    }
    // The last step for this instruction
    doStep(direction: instruction.direction)
    if current == 0 {
      exactZeros += 1
    }
  }

  return (exactZeros, zeroCrossings)
}

@main
struct App {

  static func main() {
    let instructions = parse(try! readEntireFile(getSourceFileSibling(#filePath, "Files/input.txt")))
    let (exactZeros, zeroPasses) = runInstructions(instructions: instructions, numSlots: 100, startingPoint: 50)
    print("Exact Zeros (Part 1): \(exactZeros)")
    print("Clicks in passing: \(zeroPasses)")
    print("Exact + Passing (Part 2): \(exactZeros + zeroPasses)")
  }

}
