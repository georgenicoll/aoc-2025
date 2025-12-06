import Core
import Foundation

enum Op: String {
  case times = "*"
  case plus = "+"

  var identity: Int {
    switch self {
    case .times:
      return 1
    case .plus:
      return 0
    }
  }

  func apply(_ a: Int, _ b: Int) -> Int {
    switch self {
    case .times:
      return a * b
    case .plus:
      return a + b
    }
  }
}

struct Problem {
  var linesNumbers: [[Int]] = []
  var lines: [String] = []
  var ops: [Op] = []
  var paddedOps: [String] = []
}

private func handleLine(_ problem: inout Problem, line: String) {
  let numbersRegex = /(?<number>\d+) */
  let numbers = line.matches(of: numbersRegex)
  if !numbers.isEmpty {
    problem.linesNumbers.append(numbers.map { Int($0.number)! })
    problem.lines.append(line)
    return
  }
  let opsRegex = /(?<op>\*|\+) */
  let ops = line.matches(of: opsRegex)
  if !ops.isEmpty {
    problem.ops = ops.map { Op(rawValue: String($0.op))! }
  }
  let paddedOpsRegex = /(?<op>(\*|\+)\s*)/
  let paddedOps = line.matches(of: paddedOpsRegex)
  if !paddedOps.isEmpty {
    problem.paddedOps = paddedOps.map { String($0.op) }
  }
}

private func part1(_ problem: Problem) -> Int {
  return problem.ops.enumerated().reduce(0) { grandTotal, indexAndOp in
    let (index, op) = indexAndOp
    let subTotal = problem.linesNumbers.reduce(op.identity) { subTotal, line in
      return op.apply(subTotal, line[index])
    }
    return grandTotal + subTotal
  }
}

private func part2(_ problem: Problem) -> Int {
  let (grandTotal, _) = zip(problem.ops, problem.paddedOps)
    .enumerated()
    .reduce((total: 0, opStart: 0)) { acc, indexOpAndPaddedOp in
      let (index, (op, paddedOp)) = indexOpAndPaddedOp
      let lastOne = index >= problem.ops.count - 1

      var digits = [[Character]]()

      // Group into digits within each column for this op
      for line in problem.lines { //loop the lines top to bottom
        let opEnd = lastOne ? line.count : acc.opStart + paddedOp.count - 1
        let startIndex = line.index(line.startIndex, offsetBy: acc.opStart)
        let endIndex = line.index(line.startIndex, offsetBy: opEnd)
        let numberString = line[startIndex..<endIndex]
        for (j, char) in numberString.enumerated() {
          if j >= digits.count {
            digits.append([])
          }
          if char == " " {
            continue
          }
          digits[j].append(char)
        }
      }

      //convert each digits to a number and apply the op
      let subTotal = digits
        .map { Int(String($0))! }
        .reduce(op.identity) { op.apply($0, $1) }

      return (acc.total + subTotal, acc.opStart + paddedOp.count)
    }
  return grandTotal
}

@main
struct App {

  static func main() {
    // let file = getFileSibling(#filePath, "Files/example.txt")
    let file = getFileSibling(#filePath, "Files/input.txt")
    let problem = try! readFileLineByLine(file: file, into: Problem(), handleLine)

    let part1 = part1(problem)
    print(part1)

    let part2 = part2(problem)
    print(part2)
  }

}
