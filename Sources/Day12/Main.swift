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

private func createInitialGrid(width: Int, height: Int) -> Table<Character> {
  let table = Table<Character>()
  for _ in 0..<height {
    try! table.newRow()
    for _ in 0..<width {
      try! table.addElement(element: blank)
    }
  }
  try! table.finaliseRow()
  return table
}

extension Table {
  func output() {
    self.printTable()
    print("")
  }
}

struct State {
  let grid: Table<Character>
  let remainingShapes: [Int]
  let remainingToPlace: Int
}

class States {
  var states: [State] = []
}

private func findNextPlacement(_ grid: Table<Character>, _ coords: inout [Coord]) -> (x: Int, y: Int)? {
  //shapes are 3x3 centered around 0,0 - we can't put them right at the edge - find the lowest y then x we can place it
  for y in 1..<(grid.numRows - 1) {
    inner: for x in 1..<(grid.numColumns - 1) {
      for coord in coords {
        let newX = x + coord.x
        let newY = y + coord.y
        if grid[newX,newY] != blank {
          continue inner //can't do this configuration
        }
      }
      return (x, y)
    }
  }
  return nil
}

private func placeShape(_ grid: Table<Character>, _ coords: inout [Coord], _ x: Int, _ y: Int, _ shapeId: Character) {
  for coord in coords {
    grid[x + coord.x, y + coord.y] = shapeId
  }
}

private func solvable(_ shapeConfigurations: [ShapeConfiguration], _ puzzle: Puzzle) -> Bool {
  let grid = createInitialGrid(width: puzzle.width, height: puzzle.height)
  // grid.output()

  var currentStates = States()
  var nextStates = States()

  currentStates.states.append(State(grid: grid, remainingShapes: puzzle.shapes, remainingToPlace: puzzle.shapes.reduce(0) { $0 + $1 }))

  while !currentStates.states.isEmpty {
    for state in currentStates.states {
      // state.grid.output()
      //Try placing one of each shape we have left in all it's orientations in this state
      for shapeIndex in 0..<state.remainingShapes.count {
        if state.remainingShapes[shapeIndex] == 0 { //no more of this shape
          continue
        }
        let configurations = shapeConfigurations[shapeIndex]
        for var configuration in configurations.configurations {
          if let (x, y) = findNextPlacement(state.grid, &configuration) {
            let newGrid = state.grid.copy()
            placeShape(newGrid, &configuration, x, y, shapeConfigurations[shapeIndex].gridId)
            if state.remainingToPlace == 1 {
              //That's everything - woop woop
              newGrid.output()
              return true
            }
            var newRemainingShapes = state.remainingShapes
            newRemainingShapes[shapeIndex] -= 1
            nextStates.states.append(State(grid: newGrid, remainingShapes: newRemainingShapes, remainingToPlace: state.remainingToPlace - 1))
          }
        }
      }
    }

    let tempStates = currentStates
    currentStates = nextStates
    nextStates = tempStates
    nextStates.states.removeAll(keepingCapacity: true)

    //Sort the current states and throw away the ones we don't want to keep

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
    // print(basicShapes)

    let puzzles = try! readFileLineByLine(file: file, into: [Puzzle](), loadPuzzle)
    // print(puzzles)

    let shapeConfigurations = calculateDistinctShapeConfigurations(basicShapes)
    // print(shapeConfigurations)

    let result = puzzles.reduce(0) { acc, puzzle in
      return acc + (solvable(shapeConfigurations, puzzle) ? 1 : 0)
    }
    print(result)
  }

}
