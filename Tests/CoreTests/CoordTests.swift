import Testing
@testable import Core

@Test
func doMove(){
  let current = Coord(x: 0, y: 0)
  #expect(doMove(current, .up) == Coord(x: 0, y: -1))
  #expect(doMove(current, .down) == Coord(x: 0, y: 1))
  #expect(doMove(current, .left) == Coord(x: -1, y: 0))
  #expect(doMove(current, .right) == Coord(x: 1, y: 0))
}
