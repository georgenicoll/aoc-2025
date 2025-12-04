protocol XY: CustomStringConvertible {
    var x: Int { get }
    var y: Int { get }
}


extension XY {
    public var description: String {
        return "(\(x), \(y))"
    }
}


public struct Coord: XY {
    public let x: Int
    public let y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
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
