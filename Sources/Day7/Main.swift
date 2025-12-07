import Core
import Foundation

enum Square: CustomStringConvertible {
  case space
  case splitter
  case beam(number: Int)

  var description: String {
    switch self {
    case .space: return ". "
    case .splitter: return "^ "
    case .beam(let number): return String(format: "%02d", number)
    }
  }

  static func fromChar(_ char: Character) -> Square {
    switch char {
    case "S": return Square.space
    case "^": return Square.splitter
    case "|": return Square.beam(number: 0)
    default: return Square.space
    }
  }
}

class Manifold {
  var grid: Table<Square> = Table<Square>()
  var startX: Int = -1

  func copy() -> Manifold {
    let manifold = Manifold()
    manifold.grid = self.grid.copy()
    manifold.startX = self.startX
    return manifold
  }
}

private func handleLine(_ manifold: inout Manifold, line: String) {
  try! manifold.grid.newRow()
  for (index, char) in line.enumerated() {
    let square: Square
    if char == "S" {
      square = Square.space
      manifold.startX = index
    } else {
      square = Square.fromChar(char)
    }
    try! manifold.grid.addElement(element: square)
  }
}

private func outputManifold(_ manifold: Manifold) {
  // manifold.grid.printTable()
  // print("")
}

/// Returns splits (part1) and number of paths (part2)
private func solution(_ manifold: Manifold) -> (Int, Int) {
  //Set up the first row - we should have a beam at the startX
  manifold.grid[manifold.startX, 0] = Square.beam(number: 1)

  var splits = 0
  //Now work out where splits happen - we compare the current lines splitters with the beams
  //coming in on the previous row
  for row in 1..<manifold.grid.numRows {
    let previousRow = row - 1
    let currentRow = row

    //Look for all the beams in the previous row and see if they should be split or not
    for col in 0..<manifold.grid.numColumns {
      if case .beam(let number) = manifold.grid[col, previousRow] {
        //it's a beam on the previous row - should we split it?
        switch manifold.grid[col, currentRow] {
        case .space:
          //Beam continues to this space
          manifold.grid[col, currentRow] = .beam(number: number)
        case .splitter:
          //Beam needs to be split into 2
          splits += 1

          func addBeam(_ col: Int, _ row: Int, _ beamBeingSplitNumber: Int, _ countPreviousRow: Bool) {
            //Take account of a beam in the previous - if we've been asked to do so
            var beamOnPreviousRowNumber = 0
            if case let .beam(number) = manifold.grid[col, row - 1], countPreviousRow {
              beamOnPreviousRowNumber = number
            }

            //Now make sure we combine the left and rights and previous together
            if case .beam(let number) = manifold.grid[col, row] {
              manifold.grid[col, row] = .beam(number: number + beamBeingSplitNumber + beamOnPreviousRowNumber)
            } else {
              manifold.grid[col, row] = .beam(number: beamBeingSplitNumber + beamOnPreviousRowNumber)
            }
          }

          //Calculate the beam to the left of the splitter
          addBeam(col - 1, currentRow, number, false)
          //Calculate the beam to the right of the splitter
          addBeam(col + 1, currentRow, number, true /*only include on the rhs to avoid double counting*/)
        case .beam:
          //Shouldn't be a beam here on the current row yet but do nothing anyway
          break
        }
      }
    }
    outputManifold(manifold)
  }

  //calculate the sum of the totals on the final row to get the total paths
  var paths = 0
  for col in 0..<manifold.grid.numColumns {
    if case .beam(let number) = manifold.grid[col, manifold.grid.numRows - 1] {
      paths += number
    }
  }

  return (splits, paths)
}

@main
struct App {

  static func main() {
    // let file = getFileSibling(#filePath, "Files/example.txt")
    let file = getFileSibling(#filePath, "Files/input.txt")
    let manifold = try! readFileLineByLine(file: file, into: Manifold(), handleLine)
    try! manifold.grid.finaliseRow()

    outputManifold(manifold)

    let (part1, part2) = solution(manifold)
    print(part1)
    print(part2)
  }

}
