import Core
import Foundation

private func handleLine(_ coords: inout [Coord], line: String) {
  let coordRegex = /(?<x>\d+),(?<y>\d+)/
  if let match = line.firstMatch(of: coordRegex) {
    let x = Int(match.output.x)!
    let y = Int(match.output.y)!
    coords.append(Coord(x: x, y: y))
  }
}

extension Coord {
  func area(to other: Coord) -> Int {
    (abs(x - other.x) + 1) * (abs(y - other.y) + 1)
  }
}

private func part1(_ coords: [Coord]) -> Int {
  var maxArea = -1
  for (i, coord1) in coords.enumerated() {
    for coord2 in coords.dropFirst(i + 1) {
      let area = coord1.area(to: coord2)
      maxArea = max(maxArea, area)
    }
  }
  return maxArea
}

private func createPerimeter(_ coords: inout [Coord]) -> Set<Coord> {
  var perimeter = Set<Coord>()

  for i in 0..<coords.count {
    let point1 = coords[i]
    let point2 = coords[(i + 1) % coords.count]

    let (xmin, xmax) = (min(point1.x, point2.x), max(point1.x, point2.x))
    let (ymin, ymax) = (min(point1.y, point2.y), max(point1.y, point2.y))
    for x in xmin...xmax {
      for y in ymin...ymax {
        perimeter.insert(Coord(x: x, y: y))
      }
    }
  }

  return perimeter
}

typealias Area = (from: Coord, to: Coord, area: Int)

private func containedInPerimeter(_ perimeter: inout Set<Coord>, _ area: Area) -> Bool {
  let (xmin, xmax) = (min(area.from.x, area.to.x), max(area.from.x, area.to.x))
  let (ymin, ymax) = (min(area.from.y, area.to.y), max(area.from.y, area.to.y))

  for coord in perimeter { //Check if perimiter goes inside the rectangle - if it does then we can't do it
    if (xmin < coord.x && coord.x < xmax) && (ymin < coord.y && coord.y < ymax) {
      return false
    }
  }
  return true
}

private func part2(_ coords: inout [Coord]) -> Int {
  var perimeter = createPerimeter(&coords)

  var areas = coords.enumerated()
    .flatMap{ (offset: Int, coord1: Coord) in
      return coords.dropFirst(offset + 1).map { coord2 in return (coord1, coord2) }
    }
    .map { pair in (from: pair.0, to: pair.1, area: pair.0.area(to: pair.1)) }
  areas.sort { $0.area > $1.area }

  for area in areas {
    if containedInPerimeter(&perimeter, area) {
      return area.area
    }
  }
  return 0
}

@main
struct App {

  static func main() {
    // let file = getFileSibling(#filePath, "Files/example.txt")
    let file = getFileSibling(#filePath, "Files/input.txt")

    var coords = try! readFileLineByLine(file: file, into: [Coord](), handleLine)

    let part1 = part1(coords)
    print(part1)

    let part2 = part2(&coords)
    print(part2)
  }

}
