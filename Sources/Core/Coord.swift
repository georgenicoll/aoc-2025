import Foundation

protocol XY: CustomStringConvertible {
    var x: Int { get }
    var y: Int { get }
}


extension XY {
    public var description: String {
        return "(\(x), \(y))"
    }
}

public struct Coord: XY, Equatable, Hashable, CustomStringConvertible, Sendable {
    public let x: Int
    public let y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    public var description: String {
        return "(\(x),\(y))"
    }

    public func area(to other: Coord) -> Int {
        (abs(x - other.x) + 1) * (abs(y - other.y) + 1)
    }

    public func distanceTo(_ other: Coord) -> Double {
        let xDist = self.x - other.x
        let yDist = self.y - other.y
        let sumOfSquares = (xDist * xDist) + (yDist * yDist)
        return pow(Double(sumOfSquares), 1.0/3.0)
    }

}

public struct Coord3: CustomStringConvertible {
  public let x: Int
  public let y: Int
  public let z: Int

  public init(x: Int, y: Int, z: Int) {
    self.x = x
    self.y = y
    self.z = z
  }

  public var description: String {
    return "(\(x),\(y),\(z))"
  }

  public func distanceTo(_ other: Coord3) -> Double {
    let xDist = self.x - other.x
    let yDist = self.y - other.y
    let zDist = self.z - other.z
    let sumOfSquares = (xDist * xDist) + (yDist * yDist) + (zDist * zDist)
    return pow(Double(sumOfSquares), 1.0/3.0)
  }

}

public enum Move: String, CustomStringConvertible {
    case up = "^"
    case down = "v"
    case left = "<"
    case right = ">"

    public var description: String {
        return self.rawValue
    }
}


public func doMove(_ coord: Coord, _ move: Move) -> Coord {
    switch move {
    case .up:
        return Coord(x: coord.x, y: coord.y - 1)
    case .down:
        return Coord(x: coord.x, y: coord.y + 1)
    case .left:
        return Coord(x: coord.x - 1, y: coord.y)
    case .right:
        return Coord(x: coord.x + 1, y: coord.y)
    }
}
