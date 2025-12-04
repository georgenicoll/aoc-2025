public enum TableError: Error, Equatable {
    public enum Kind: Sendable, Equatable {
        case inconsistentState(message: String)
    }

    case kind(Kind)
}


public struct Coord: Equatable {
    public let x: Int
    public let y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}


public class Table<Element> {
    private var rows: [[Element]] = [[Element]]()
    private var width: Int? = nil

    public init() {
    }

    public var numRows: Int {
        get {
            return rows.count
        }
    }

    public var numColumns: Int {
        get {
            return width ?? 0
        }
    }

    @discardableResult
    public func newRow() throws -> Self {
        if rows.isEmpty {
            rows.append([Element]())
            return self
        } else if rows.count == 1 { //If this is the first row, we can lock in the width
            width = rows[0].count
        } else {
            if rows[rows.count - 1].count != width {
                throw TableError.kind(.inconsistentState(message: "Inconsistent row width"))
            }
        }
        rows.append([Element]())
        rows[rows.count - 1].reserveCapacity(width!)
        return self
    }

    @discardableResult
    public func addElement(element: Element) throws -> Self {
        if rows.isEmpty {
            throw TableError.kind(.inconsistentState(message: "No rows exist yet"))
        }
        if width != nil && rows[rows.count - 1].count == width {
            throw TableError.kind(.inconsistentState(message: "Row is full"))
        }
        rows[rows.count - 1].append(element)
        return self
    }

    @discardableResult
    public func finaliseRow() throws -> Self {
        if rows.count == 1 { //If this is the first row, we can lock in the width
            width = rows[0].count
        } else {
            if rows[rows.count - 1].count != width {
                throw TableError.kind(.inconsistentState(message: "Inconsistent last row width"))
            }
        }
        return self
    }

    public func isInBounds(column: Int, row: Int) -> Bool {
        return column >= 0 && column < numColumns && row >= 0 && row < numRows
    }

    private func checkBounds(column: Int, row: Int) throws {
        if column < 0 || column >= numColumns {
            throw TableError.kind(.inconsistentState(message: "Column out of bounds"))
        }
        if row < 0 || row >= numRows {
            throw TableError.kind(.inconsistentState(message: "Row out of bounds"))
        }
    }

    public func elementAt(column: Int, row: Int) throws -> Element {
        try checkBounds(column: column, row: row)
        return rows[row][column]
    }

    public func maybeElementAt(column: Int, row: Int) -> Element? {
        if !isInBounds(column: column, row: row) {
            return nil
        }
        return rows[row][column]
    }

    public subscript(column: Int, row: Int) -> Element {
        get {
            try! elementAt(column: column, row: row)
        }
        set {
            try! checkBounds(column: column, row: row)
            rows[row][column] = newValue
        }
    }

    public func printTable() {
        for row in rows {
            for column in row {
                print("\(column)", terminator: "")
            }
            print("")
        }
    }

    public func copy() -> Table<Element> {
        let copy = Table<Element>()
        copy.rows = rows
        copy.width = width
        return copy
    }

}