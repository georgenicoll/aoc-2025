import Testing
@testable import Core

struct Value: Equatable {
    let thing: String
}

@Test
func populateATable(){
  let table = Table<Value>()
  try! table.newRow()
    .addElement(element: Value(thing: "rod"))
    .addElement(element: Value(thing: "jane"))
    .newRow()
    .addElement(element: Value(thing: "freddy"))
    .addElement(element: Value(thing: "bungle"))
    .newRow()
    .addElement(element: Value(thing: "zippy"))
    .addElement(element: Value(thing: "george"))
    .finaliseRow()
  #expect(table.numRows == 3)
  #expect(table.numColumns == 2)
  #expect(table[0,0].thing == "rod")
  #expect(table[1,0].thing == "jane")
  #expect(table[0,1].thing == "freddy")
  #expect(table[1,1].thing == "bungle")
  #expect(table[0,2].thing == "zippy")
  #expect(table[1,2].thing == "george")
}

@Test
func inconsistentRowWidthsThrows() {
    #expect(throws: TableError.kind(.inconsistentState(message: "Inconsistent row width"))) {
        let table = Table<Value>()
        try table.newRow()
            .addElement(element: Value(thing: "bob"))
            .addElement(element: Value(thing: "dave"))
            .newRow()
            .addElement(element: Value(thing: "bob"))
            .newRow()
    }
}

@Test
func inconsistentFinalRowWidthsThrows() {
    #expect(throws: TableError.kind(.inconsistentState(message: "Inconsistent last row width"))) {
        let table = Table<Value>()
        try table.newRow()
            .addElement(element: Value(thing: "bob"))
            .addElement(element: Value(thing: "dave"))
            .newRow()
            .addElement(element: Value(thing: "bob"))
            .finaliseRow()
    }
}

@Test
func tooManyInRowThrows() {
    #expect(throws: TableError.kind(.inconsistentState(message: "Row is full"))) {
        let table = Table<Value>()
        try table.newRow()
            .addElement(element: Value(thing: "bob"))
            .newRow()
            .addElement(element: Value(thing: "bob"))
            .addElement(element: Value(thing: "dave"))
    }
}

@Test
func noRowYetThrows() {
    #expect(throws: TableError.kind(.inconsistentState(message: "No rows exist yet"))) {
        let table = Table<Value>()
        try table.addElement(element: Value(thing: "bob"))
    }
}

@Test
func copyTable() {
  let original = Table<Value>()
  try! original.newRow()
    .addElement(element: Value(thing: "rod"))
    .addElement(element: Value(thing: "jane"))
    .newRow()
    .addElement(element: Value(thing: "freddy"))
    .addElement(element: Value(thing: "bungle"))
    .finaliseRow()
  let copy = original.copy()
  #expect(copy.numRows == 2)
  #expect(copy.numColumns == 2)
  #expect(copy[0,0].thing == "rod")
  #expect(copy[1,0].thing == "jane")
  #expect(copy[0,1].thing == "freddy")
  #expect(copy[1,1].thing == "bungle")
  original[0,1] = Value(thing: "zippy")
  #expect(original[0,1].thing == "zippy")
  #expect(copy[0,1].thing == "freddy")
}

@Test
func isInBounds() {
  let table = Table<Value>()
  try! table.newRow()
    .addElement(element: Value(thing: "rod"))
    .addElement(element: Value(thing: "jane"))
    .newRow()
    .addElement(element: Value(thing: "freddy"))
    .addElement(element: Value(thing: "bungle"))
    .finaliseRow()
  #expect(table.numRows == 2)
  #expect(table.numColumns == 2)
  #expect(table.isInBounds(column: 0, row: 0) == true)
  #expect(table.isInBounds(column: 1, row: 1) == true)
  #expect(table.isInBounds(column: -1, row: 0) == false)
  #expect(table.isInBounds(column: 0, row: -1) == false)
  #expect(table.isInBounds(column: 2, row: 0) == false)
  #expect(table.isInBounds(column: 0, row: 2) == false)
}
