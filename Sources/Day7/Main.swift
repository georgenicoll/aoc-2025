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
private func part1(_ manifold: Manifold) -> (Int, Int) {
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
        case .space: //Beam continues
          manifold.grid[col, currentRow] = .beam(number: number)
        case .splitter: //Beam is split into 2 - we need combine all paths to this square
          splits += 1

          func addBeam(_ col: Int, _ row: Int, _ beamBeingSplitNumber: Int, _ countPreviousRow: Bool) {
            //Check if beam is coming in on this column already from above - this should also be added to the number
            let previousRowNumber: Int
            if !countPreviousRow {
              previousRowNumber = 0
            } else if case .beam(let number) = manifold.grid[col, row - 1] {
              previousRowNumber = number
            } else {
              previousRowNumber = 0
            }

            //Now make sure we combine the left and rights and previous together
            if case .beam(let number) = manifold.grid[col, row] {
              manifold.grid[col, row] = .beam(number: number + beamBeingSplitNumber + previousRowNumber)
            } else {
              manifold.grid[col, row] = .beam(number: beamBeingSplitNumber + previousRowNumber)
            }
          }

          addBeam(col - 1, currentRow, number, false)
          addBeam(col + 1, currentRow, number, true) //only include the previous row beam when moving right
        case .beam:
          //Shouldn't be but do nothing
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

    let (part1, part2) = part1(manifold)
    print(part1)
    print(part2)
  }

}
