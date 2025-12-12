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
  let configurations: [[Coord]]

  init(id: Int, configurations: [[Coord]]) {
    self.id = id
    self.configurations = configurations
  }

  var description: String {
    "Shape \(id): \(configurations)"
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

@main
struct App {


  static func main() {
    let file = getFileSibling(#filePath, "Files/example.txt")
    //let file = getFileSibling(#filePath, "Files/input.txt")

    let basicShapes = loadBasicShapes(try! readEntireFile(file))
    print(basicShapes)

    let puzzles = try! readFileLineByLine(file: file, into: [Puzzle](), loadPuzzle)
    print(puzzles)

    let shapeConfigurations = calculateDistinctShapeConfigurations(basicShapes)
    print(shapeConfigurations)
  }

}
