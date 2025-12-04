import Core
import Foundation

enum Square: String, CustomStringConvertible {
  case empty = "."
  case roll = "@"

  var description: String {
    self.rawValue
  }
}

private func handleLine(table: inout Table<Square>, line: String) {
  try! table.newRow()
  for char in line {
    let square = Square(rawValue: String(char))!
    try! table.addElement(element: square)
  }
}

let surroundingSquareOffsets = [
  (-1, -1), (0, -1), (1, -1),
  (-1, 0),           (1, 0),
  (-1, 1),  (0, 1),  (1, 1),
]

private func numRollsInSurroundingSquares(_ table: Table<Square>, col: Int, row: Int) -> Int {
  var sum = 0
  for (colOffset, rowOffset) in surroundingSquareOffsets {
    if let square = table.maybeElementAt(column: col + colOffset, row: row + rowOffset) {
      if square == .roll {
        sum += 1
      }
    }
  }
  return sum
}

private func rollsThatCanBeRemoved(_ table: Table<Square>) -> [Coord] {
  var rolls = [Coord]()
  for row in 0..<table.numRows {
    for col in 0..<table.numColumns {
      let thisSquare = table[col, row]
      if thisSquare == .roll {
        if numRollsInSurroundingSquares(table, col: col, row: row) < 4 {
          rolls.append(Coord(x: col, y: row))
        }
      }
    }
  }
  return rolls
}

private func calculatePart2(_ table: inout Table<Square>) -> Int {
  var sum = 0
  while true {
    let rolls = rollsThatCanBeRemoved(table)
    if rolls.isEmpty {
      break
    }
    for roll in rolls {
      table[roll.x, roll.y] = .empty
    }
    sum += rolls.count
  }
  return sum
}

@main
struct App {

  static func main() {
    let file = getFileSibling(#filePath, "Files/input.txt")
    var table = try! readFileLineByLine(file: file, into: Table<Square>(), handleLine)
    try! table.finaliseRow() //fix last row

    let part1Rolls = rollsThatCanBeRemoved(table)
    print(part1Rolls.count)

    let part2 = calculatePart2(&table)
    print(part2)
  }

}
