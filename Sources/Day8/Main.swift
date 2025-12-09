import Core
import Foundation
import RegexBuilder

let notSet = -1

class JunctionBox {
  let id: Int
  let coord: Coord3
  var circuitId: Int = notSet
  var connections: Set<Int> = []

  init(id: Int, coord: Coord3) {
    self.id = id
    self.coord = coord
  }

  func distanceTo(_ other: JunctionBox) -> Double {
    let xDist = self.coord.x - other.coord.x
    let yDist = self.coord.y - other.coord.y
    let zDist = self.coord.z - other.coord.z
    let sumOfSquares = (xDist * xDist) + (yDist * yDist) + (zDist * zDist)
    return pow(Double(sumOfSquares), 1.0/3.0)
  }
}

class SetWrapper<T: Hashable> {
  var set: Set<T>
  init(_ set: Set<T>) {
    self.set = set
  }
}

private func parseLine(_ coords: inout [Coord3], line: String) {
  let coordRegex = /(?<x>\d+),(?<y>\d+),(?<z>\d+)/
  if let match = line.firstMatch(of: coordRegex) {
    let x = Int(match.x)!
    let y = Int(match.y)!
    let z = Int(match.z)!
    coords.append(Coord3(x: x, y: y, z: z))
  }
}

private func createJunctionBoxes(_ coords: [Coord3]) -> [JunctionBox] {
  var junctionBoxes: [JunctionBox] = []
  for (i, coord) in coords.enumerated() {
    junctionBoxes.append(JunctionBox(id: i, coord: coord))
  }
  return junctionBoxes
}

class BoxDistance {
  var boxA: JunctionBox
  var boxB: JunctionBox
  let distance: Double

  init(_ boxA: JunctionBox, _ boxB: JunctionBox, _ distance: Double) {
    self.boxA = boxA
    self.boxB = boxB
    self.distance = distance
  }
}

///Calculate all of the distances from one box to another and return the list ordered by shortest first
private func calculateDistances(_ junctionBoxes: inout [JunctionBox]) -> [BoxDistance] {
  var distances = [BoxDistance]()
  for (i, box1) in junctionBoxes.dropLast().enumerated() {
    for j in i+1..<junctionBoxes.count {
      let box2 = junctionBoxes[j]
      distances.append(BoxDistance(box1, box2, box1.distanceTo(box2)))
    }
  }
  distances.sort { $0.distance < $1.distance }
  return distances
}

private func connectBoxes(
  _ circuits: inout [Int:SetWrapper<Int>],
  _ junctionBoxes: inout [JunctionBox],
  _ box1: inout JunctionBox,
  _ box2: inout JunctionBox,
) {
  let boxA = box1.id < box2.id ? box1 : box2
  let boxB = box1.id < box2.id ? box2 : box1
  // Connect them
  boxA.connections.insert(boxB.id)
  boxB.connections.insert(boxA.id)
  // What should this new circuit be?
  if boxA.circuitId == notSet && boxB.circuitId == notSet {
    //No circuits yet.   we'll take the lowest as the id
    boxA.circuitId = boxA.id
    boxB.circuitId = boxA.id
    circuits[boxA.id] = SetWrapper([boxA.id, boxB.id])
    return
  }
  if boxA.circuitId == notSet {
    //A in B's circuit
    boxA.circuitId = boxB.circuitId
    circuits[boxB.circuitId]!.set.insert(boxA.id)
    return
  }
  if boxB.circuitId == notSet {
    //Put B in A's circuit
    boxB.circuitId = boxA.circuitId
    circuits[boxA.circuitId]!.set.insert(boxB.id)
    return
  }
  if boxA.circuitId != boxB.circuitId {
    //Merge circuits to the largets circuit
    let idsA = circuits[boxA.circuitId]!
    let idsB = circuits[boxB.circuitId]!
    if idsA.set.count >= idsB.set.count {
      //Merge B into A
      circuits.removeValue(forKey: boxB.circuitId)
      idsB.set.forEach({ id in
        junctionBoxes[id].circuitId = boxA.circuitId
        idsA.set.insert(id)
      })
      return
    }
    //Merge A into B
    circuits.removeValue(forKey: boxA.circuitId)
    idsA.set.forEach({ id in
      junctionBoxes[id].circuitId = boxB.circuitId
      idsB.set.insert(id)
    })
  }
  //Get here should be the same - nothing to do
}

private func solution(
  _ coords: [Coord3],
  stopFunc: (Int, inout Set<Int>, JunctionBox, JunctionBox) -> Bool,
) -> Int {
  var connectedBoxes = Set<Int>()
  var circuits = [Int:SetWrapper<Int>]()
  var junctionBoxes = createJunctionBoxes(coords)
  let distances: [BoxDistance] = calculateDistances(&junctionBoxes)

  for (rep, distance) in distances.enumerated() {
    connectBoxes(&circuits, &junctionBoxes, &distance.boxA, &distance.boxB)
    connectedBoxes.insert(distance.boxA.id)
    connectedBoxes.insert(distance.boxB.id)

    if stopFunc(rep + 1, &connectedBoxes, distance.boxA, distance.boxB) {
      break
    }
  }

  //Now get a sorted list of the circuits, largest first
  let sortedCircuits = circuits
    .map { ($0, $1) }
    .sorted { $0.1.set.count > $1.1.set.count }

  return sortedCircuits.prefix(3).reduce(1) { $0 * $1.1.set.count }
}


@main
struct App {

  static func main() {
    // let file = getFileSibling(#filePath, "Files/example.txt")
    // let stopAfterReps = 10
    let file = getFileSibling(#filePath, "Files/input.txt")
    let stopAfterReps = 1000
    let coords = try! readFileLineByLine(file: file, into: [Coord3](), parseLine)

    let part1 = solution(coords) { rep, _, _, _ in
      return rep >= stopAfterReps
    }
    print(part1)

    let _ = solution(coords) { rep, connectedBoxes, boxA, boxB in
      if connectedBoxes.count < coords.count {
        return false
      }
      print("Stopping after connecting \(boxA.coord) and \(boxB.coord)")
      print("Distance: \(boxA.coord.x * boxB.coord.x)")
      return true
    }
  }

}
