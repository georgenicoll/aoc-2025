import Core
import Foundation
import RegexBuilder

class BasicShape: CustomStringConvertible {
  let id: Int
  let points: [Coord]

  init(id: Int, points: [Coord]) {
    self.id = id
    self.points = points
  }

  var description: String {
    "Shape \(id): \(points)"
  }
}

private func loadBasicShapes(_ content: String) -> [BasicShape] {
  let shapeRegex = /(?<id>\d):\n(?<line1>[#\.]{3})\n(?<line2>[#\.]{3})\n(?<line3>[#\.]{3})\n/
  return content.matches(of: shapeRegex).map { match in
    let id = Int(match.output.id)!
    let line1 = match.output.line1
    let line2 = match.output.line2
    let line3 = match.output.line3

    func linePoints(line: Substring, y: Int) -> [Coord] {
      return line.enumerated().compactMap { (index, char) in
        if char == "#" {
          return Coord(x: index - 1, y: y - 1)
        }
        return nil
      }
    }

    return BasicShape(
      id: id,
      points:
        linePoints(line: line1, y: 0) +
        linePoints(line: line2, y: 1) +
        linePoints(line: line3, y: 2)
    )
  }
}

class Puzzle: CustomStringConvertible {
  let width: Int
  let height: Int
  let shapes: [Int]

  init(width: Int, height: Int, shapes: [Int]) {
    self.width = width
    self.height = height
    self.shapes = shapes
  }

  var description: String {
    "Puzzle \(width)x\(height): \(shapes)"
  }
}

private func loadPuzzle(_ puzzles: inout [Puzzle], line: String) {
  let dimensionsRegex = /(?<width>\d+)x(?<height>\d+):/

  let dimensionMatch = line.firstMatch(of: dimensionsRegex)
  guard dimensionMatch != nil else {
    return
  }

  let dimensionsMatch = dimensionMatch!
  let width = Int(dimensionsMatch.output.width)!
  let height = Int(dimensionsMatch.output.height)!

  let shapesRegex = /\ (?<numShapes>\d+)/
  let shapes = line.matches(of: shapesRegex).map { match in
    Int(match.output.numShapes)!
  }

  puzzles.append(Puzzle(width: width, height: height, shapes: shapes))
}

class ShapeConfiguration: CustomStringConvertible {
  let id: Int
  let gridId: Character
  let configurations: [[Coord]]

  init(id: Int, configurations: [[Coord]]) {
    self.id = id
    self.gridId = Character(UnicodeScalar(id + 48)!)
    self.configurations = configurations
  }

  var description: String {
    "Shape \(id) (\(gridId)): \(configurations)"
  }
}

let rotationMappings = [
    Coord(x: -1, y: -1): Coord(x: 1, y: -1),
    Coord(x: 0, y: -1) : Coord(x: 1,  y: 0),
    Coord(x: 1, y: -1) : Coord(x: 1,  y: 1),

    Coord(x: -1,  y: 0): Coord(x: 0, y: -1),
    Coord(x: 0,  y: 0) : Coord(x: 0,  y: 0),
    Coord(x: 1,  y: 0) : Coord(x: 0,  y: 1),

    Coord(x: -1, y: 1): Coord(x: -1,  y: -1),
    Coord(x: 0, y: 1) : Coord(x: -1,  y: 0),
    Coord(x: 1, y: 1) : Coord(x: -1,  y: 1),
]

private func calculateRotations(_ coords: [Coord]) -> [[Coord]] {

  func rotate90(_ points: [Coord]) -> [Coord] {
    return points.map { coord in
      rotationMappings[coord]!
    }
  }
  var rotations = [coords]
  var points = coords
  for _ in 0..<3 {
    points = rotate90(points)
    rotations.append(points)
  }
  return rotations
}

private func flip(_ coords: [Coord], xChange: Int = 1, yChange: Int = 1) -> [Coord] {
  return coords.map { coord in
    Coord(x: coord.x * xChange, y: coord.y * yChange)
  }
}

private func calculateShapeConfigurations(_ basicShape: BasicShape) -> [[Coord]] {
  //Could be a bit over the top here but any duplicates will be removed later
  let rotations = calculateRotations(basicShape.points)
  let xFlipped = calculateRotations(flip(basicShape.points, xChange: -1))
  let yFlipped = calculateRotations(flip(basicShape.points, yChange: -1))
  let xyFlipped = calculateRotations(flip(basicShape.points, xChange: -1, yChange: -1))

  let combined = (rotations + xFlipped + yFlipped + xyFlipped).map { coords in
    coords.sorted(by: { 10 * $0.y + $0.x < 10 * $1.y + $1.x })
  }

  return Array(Set(combined))
}

private func calculateDistinctShapeConfigurations(_ basicShapes: [BasicShape]) -> [ShapeConfiguration] {
  return basicShapes.map { shape in
    let configurations = calculateShapeConfigurations(shape)
    return ShapeConfiguration(id: shape.id, configurations: configurations)
  }
}

let blank = Character(".")

class Grid {
  var rows: [UInt64]
  var width: Int

  init(_ rows: [UInt64], _ width: Int) {
    self.rows = rows
    self.width = width
  }

  func copy() -> Grid {
    return Grid(self.rows, self.width)
  }

  func output() {
    for row in rows {
      let rowString = String(row, radix: 2)
      let padding = String(repeating: "0", count: 64 - rowString.count)
      let fullString = "\(padding)\(rowString)"
      let endIndex = fullString.index(fullString.startIndex, offsetBy: width)
      print(fullString[..<endIndex])
    }
    print("")
  }
}

class CompactShape: CustomStringConvertible {
  var rows: [UInt8]

  init(_ rows: [UInt8]) {
    self.rows = rows
  }

  var description: String {
    rows.map { String($0, radix: 2) }.joined(separator: "")
  }
}

class CompactConfiguration: CustomStringConvertible {
  let id: Int
  let configurations: [CompactShape]
  let squaresNeededByConfigurations: Int

  init(
    id: Int,
    configurations: [CompactShape],
    squaresNeededByConfigurations: Int,
  ) {
    self.id = id
    self.configurations = configurations
    self.squaresNeededByConfigurations = squaresNeededByConfigurations
  }

  var description: String {
    "Shape \(id): \(configurations)"
  }
}

private func createCompactConfigurations(_ shapeConfigurations: [ShapeConfiguration]) -> [CompactConfiguration] {
  let xMap = [
    -1: UInt8(0b00000100),
    0: UInt8(0b00000010),
    1: UInt8(0b00000001)
  ]

  return shapeConfigurations.map { config in
    let compactShapes = config.configurations.map { coords in
      var rows = Array(repeating: UInt8(0), count: 3)
      for coord in coords {
        rows[coord.y + 1] |= xMap[coord.x]!
      }
      return CompactShape(rows)
    }
    return CompactConfiguration(
      id: config.id,
      configurations: compactShapes,
      squaresNeededByConfigurations: config.configurations.first!.count
    )
  }
}

private func createInitialGrid(width: Int, height: Int) -> Grid {
  if width > 64 {
    fatalError("Width must be <= 64")
  }
  return Grid(Array(repeating: UInt64(0), count: height), width)
}

struct State {
  let grid: Grid
  let remainingShapes: [Int]
  let remainingToPlace: Int
  let lastPlacement: Coord
}

class States {
  var states: [State] = []
}

let shapeDimension = 3

private func findNextPlacement(_ grid: Grid, _ startAtX: Int?, _ lastY: Int, _ shape: CompactShape) -> (x: Int, y: Int)? {
  if lastY + 1 > grid.rows.count - 1 {
    return nil
  }
  //shapes are 3x3 centered around 0,0 - we can't put them right at the edge - find the lowest y then x we can place it
  //but there is no point in going all the way to the start - just look a couple back from the last placement
  let startY = max(1, lastY)
  let startX = startAtX ?? 1 //start at the left if no startX specified
  if startX + 1 > grid.width - 1 {
    return nil
  }
  for y in startY..<(grid.rows.count - 1) {
    inner: for x in startX..<(grid.width - 1) {
      let shiftAmount = 64 - shapeDimension - x + 1
      //Hardcoding this to 3 rows in the shape
      let topRow: UInt64 = UInt64(shape.rows[0]) << shiftAmount
      //We can only fit bitwise and returns a 0
      if (topRow & grid.rows[y - 1]) != 0 {
        continue inner
      }
      let middleRow: UInt64 = UInt64(shape.rows[1]) << shiftAmount
      if (middleRow & grid.rows[y]) != 0 {
        continue inner
      }
      let bottomRow: UInt64 = UInt64(shape.rows[2]) << shiftAmount
      if (bottomRow & grid.rows[y + 1]) != 0 {
        continue inner
      }
      //It'll fit
      return (x, y)
    }
  }
  return nil
}

private func placeShape(_ grid: Grid, _ shape: CompactShape, _ x: Int, _ y: Int) {
  //Hardcoding this to 3 rows in the shape
  //bitwise or for the new value
  let shiftAmount = 64 - shapeDimension - x + 1
  let topRow: UInt64 = UInt64(shape.rows[0]) << shiftAmount
  grid.rows[y - 1] = grid.rows[y - 1] | topRow
  let middleRow: UInt64 = UInt64(shape.rows[1]) << shiftAmount
  grid.rows[y] = grid.rows[y] | middleRow
  let bottomRow: UInt64 = UInt64(shape.rows[2]) << shiftAmount
  grid.rows[y + 1] = grid.rows[y + 1] | bottomRow
}

private func precheck(_ configurations: [CompactConfiguration], _ puzzle: Puzzle) -> Bool {
  //Simple check to see whether there are enough squares for the puzzle to work
  let totalSquaresNeeded = puzzle.shapes.enumerated().reduce(0) { (total, indexAndNumber) in
    let (index, number) = indexAndNumber
    let shape = configurations[index]
    return total + (shape.squaresNeededByConfigurations * number)
  }
  return totalSquaresNeeded <= puzzle.width * puzzle.height
}

let maxStates = 250

private func solvable(_ compactConfigurations: [CompactConfiguration], _ puzzle: Puzzle) -> Bool {
  // if !precheck(compactConfigurations, puzzle) {
  //   print("Precheck failed")
  //   return false
  // }

  let grid = createInitialGrid(width: puzzle.width, height: puzzle.height)
  // grid.output()

  var currentStates = States()
  var nextStates = States()

  currentStates.states.append(State(
    grid: grid,
    remainingShapes: puzzle.shapes,
    remainingToPlace: puzzle.shapes.reduce(0) { $0 + $1 },
    lastPlacement: Coord(x: -1, y: -1),
  ))

  while !currentStates.states.isEmpty {
    // print("states size: \(currentStates.states.count)")
    for state in currentStates.states {
      // state.grid.output()
      //Try placing one of each shape we have left in all it's orientations in this state
      for shapeIndex in 0..<state.remainingShapes.count {
        if state.remainingShapes[shapeIndex] == 0 { //no more of this shape
          continue
        }
        let configurations = compactConfigurations[shapeIndex]
        for configuration in configurations.configurations {
          var possiblePlacements = [(x: Int, y: Int)?]()
          possiblePlacements.append(findNextPlacement(state.grid, nil, state.lastPlacement.y, configuration))
          possiblePlacements.append(findNextPlacement(state.grid, state.lastPlacement.x + shapeDimension + 1, state.lastPlacement.y, configuration))
          possiblePlacements.append(findNextPlacement(state.grid, nil, state.lastPlacement.y + 1, configuration))
          for (x, y) in possiblePlacements.compactMap({ $0 }) {
            let newGrid = state.grid.copy()
            placeShape(newGrid, configuration, x, y)
            if state.remainingToPlace == 1 {
              newGrid.output()
              return true
            }
            var newRemainingShapes = state.remainingShapes
            newRemainingShapes[shapeIndex] -= 1
            nextStates.states.append(State(
              grid: newGrid,
              remainingShapes: newRemainingShapes,
              remainingToPlace: state.remainingToPlace - 1,
              lastPlacement: Coord(x: x, y: y),
            ))
          }
        }
      }
    }

    let tempStates = currentStates
    currentStates = nextStates
    nextStates = tempStates
    nextStates.states.removeAll(keepingCapacity: true)

    //Sort the current states and throw away the ones we don't want to keep
    //Initial attempt, sort to choose lower ys before lower xs
    currentStates.states.sort { 100 * $0.lastPlacement.y + $0.lastPlacement.x < 100 * $1.lastPlacement.y + $1.lastPlacement.x }
    if currentStates.states.count > maxStates {
        currentStates.states.removeSubrange(maxStates...)
    }
  }

  //Get here we couldn't do it
  return false
}

@main
struct App {

  static func main() {
    //let file = getFileSibling(#filePath, "Files/example.txt")
    let file = getFileSibling(#filePath, "Files/input.txt")

    let basicShapes = loadBasicShapes(try! readEntireFile(file))
    let puzzles = try! readFileLineByLine(file: file, into: [Puzzle](), loadPuzzle)

    let shapeConfigurations = calculateDistinctShapeConfigurations(basicShapes)
    let compactShapeConfigs = createCompactConfigurations(shapeConfigurations)

    let totalShapeCombinations = compactShapeConfigs.reduce(0) { $0 + $1.configurations.count }
    print("There are a total of \(totalShapeCombinations) shape combinations\n")

    let result = puzzles.enumerated().reduce(0) { acc, indexAndPuzzle in
      let solvable = solvable(compactShapeConfigs, indexAndPuzzle.element)
      print("Puzzle \(indexAndPuzzle.offset): \(solvable)\n")
      return acc + (solvable ? 1 : 0)
    }
    print(result)
  }

}
