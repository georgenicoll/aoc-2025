import Core
import Foundation
import RegexBuilder


struct Range: CustomStringConvertible{
  var start: Int
  var end: Int

  var description: String {
    return "\(start)-\(end)"
  }
}


func parseFile(_ file: String) -> ([Range], [Int]) {
  let contents = try! readEntireFile(file)

  let rangeRegex = /^(?<start>\d+)-(?<end>\d+)$/.anchorsMatchLineEndings()
  let ranges = contents.matches(of: rangeRegex).map({ match in
    Range(start: Int(match.output.start)!, end: Int(match.output.end)!)
  })

  let idRegex = /^(?<id>\d+)$/.anchorsMatchLineEndings()
  let ids = contents.matches(of: idRegex).map({ match in
    Int(match.output.id)!
  })

  return (ranges, ids)
}

func calcPart1(_ ranges: [Range], _ ids: [Int]) -> Int {
  var numFresh = 0
  for id in ids {
    for range in ranges {
      if range.start <= id && id <= range.end {
        numFresh += 1
        break
      }
    }
  }
  return numFresh
}

func calcPart2(_ ranges: [Range]) -> Int {
  // order by range starts
  let sortedRanges = ranges.sorted(by: { $0.start < $1.start })

  var sum = 0
  var latestStart = sortedRanges[0].start
  var latestEnd = sortedRanges[0].end
  // Loop through keeping a track of where the latest start and end:
  //  - if the new range is non-overlapping, then count the range and start a new one
  //  - if the new range is overlapping, then extend the current one if it finishes later
  for range in sortedRanges[1...] {
    if range.start > latestEnd {
      //new range
      sum += latestEnd - latestStart + 1
      latestStart = range.start
      latestEnd = range.end
    } else {
      //otherwise must be overlapping, extend if we need to
      latestEnd = max(range.end, latestEnd)
    }
  }

  //Finally count the last range
  sum += latestEnd - latestStart + 1

  return sum
}

@main
struct App {

  static func main() {
    let file = getFileSibling(#filePath, "Files/input.txt")
    let (ranges, ids) = parseFile(file)

    let part1 = calcPart1(ranges, ids)
    print(part1)

    let part2 = calcPart2(ranges)
    print(part2)
  }

}
