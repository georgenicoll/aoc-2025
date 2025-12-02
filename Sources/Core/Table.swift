public enum TableError: Error, Equatable {
    public enum Kind: Sendable, Equatable {
        case inconsistentState(message: String)
    }

    case kind(Kind)
}


public class Table<Element> {
    private var rows: [[Element]] = [[Element]]()
    private var width: Int? = nil

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

    public func elementAt(column: Int, row: Int) throws -> Element {
        if row >= rows.count {
            throw TableError.kind(.inconsistentState(message: "Row index out of bounds \(row)"))
        }
        if column >= width! {
            throw TableError.kind(.inconsistentState(message: "Column index out of bounds \(column)"))
        }
        return rows[row][column]
    }

    public subscript(column: Int, row: Int) -> Element {
        get {
            try! elementAt(column: column, row: row)
        }
    }

}