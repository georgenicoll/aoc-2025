import Core
import Foundation
import RegexBuilder

struct Coord3: CustomStringConvertible {
  let x: Int
  let y: Int
  let z: Int

  var description: String {
    return "(\(x),\(y),\(z))"
  }
}

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
  numConnections: Int,
  stopFunc: (inout Set<Int>, JunctionBox, JunctionBox) -> Bool,
) -> Int {
  var connectedBoxes = Set<Int>()
  var circuits = [Int:SetWrapper<Int>]()
  var junctionBoxes = createJunctionBoxes(coords)

  for rep in 0..<numConnections { // need numConnections connections to be made
    if rep % 50 == 0 {
      print("Rep: \(rep)")
    }
    //Find next closest connection
    var currentMin: Double? = nil
    var boxA: JunctionBox? = nil
    var boxB: JunctionBox? = nil
    for (id1, box1) in junctionBoxes.enumerated() {
      for (id2, box2) in junctionBoxes.enumerated() {
        if id1 == id2 { continue }
        if box1.connections.contains(id2) { continue }

        let distance = box1.distanceTo(box2)
        if currentMin == nil || distance < currentMin! {
          currentMin = distance
          boxA = box1
          boxB = box2
        }
      }
    }

    connectBoxes(&circuits, &junctionBoxes, &boxA!, &boxB!)
    connectedBoxes.insert(boxA!.id)
    connectedBoxes.insert(boxB!.id)

    if stopFunc(&connectedBoxes, boxA!, boxB!) {
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
    let file = getFileSibling(#filePath, "Files/input.txt")
    let coords = try! readFileLineByLine(file: file, into: [Coord3](), parseLine)

    // print(coords)

    // let part1 = solution(coords, numConnections: 10)
    // let part1 = solution(coords, numConnections: 1000)
    // print(part1)

    let part2 = solution(coords, numConnections: Int.max, stopFunc: { connectedBoxes, boxA, boxB in
      if connectedBoxes.count == coords.count {
        print("Stopping after connecting \(boxA.coord) and \(boxB.coord)")
        print("Distance: \(boxA.coord.x * boxB.coord.x)")
        return true
      }
      return false
    })
    print(part2)
  }

}
