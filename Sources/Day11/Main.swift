import Core
import Foundation

class Node: CustomStringConvertible {
  let id: String
  let outputs: Set<String>

  init(id: String, outputs: Set<String>) {
    self.id = id
    self.outputs = outputs
  }

  var description: String {
    return "\(id), \(outputs)"
  }

}

private func handleLine(_ nodes: inout [String:Node], line: String) {
  let regex = /(?<s>\w+)/
  let matches = line.matches(of: regex)
  let id = String(matches.first!.s)
  let outputs = matches.dropFirst().reduce(into: Set<String>()) {
    $0.insert(String($1.s))
  }
  nodes[id] = Node(id: id, outputs: outputs)
}

//DFS from start to end with memoization and allowing certain nodes to be ignored
private func dfs(
  _ nodes: inout [String:Node],
  _ node: String,
  _ end: String,
  _ memo: inout [String:Int],
  _ ignoreNodes: inout Set<String>,
) -> Int {
  if node == end {
    return 1 //path found
  }
  if let paths = memo[node] {
    return paths //already computed
  }

  var totalPaths = 0
  let nodeObj = nodes[node]!
  for output in nodeObj.outputs {
    if ignoreNodes.contains(output) {
      continue
    }
    totalPaths += dfs(&nodes, output, end, &memo, &ignoreNodes)
  }
  memo[node] = totalPaths
  return totalPaths
}

private func solution(
  _ nodes: inout [String:Node],
  start: String,
  end: String,
  ignoreNodes: Set<String>,
) -> Int {
  var memo = [String:Int]()
  var ignoreNodes = ignoreNodes
  return dfs(&nodes, start, end, &memo, &ignoreNodes)
}


@main
struct App {

  static func main() {
    // let file1 = getFileSibling(#filePath, "Files/example.txt")
    // let file2 = getFileSibling(#filePath, "Files/example2.txt")
    let file1 = getFileSibling(#filePath, "Files/input.txt")
    let file2 = file1

    var nodes1 = try! readFileLineByLine(file: file1, into: [String:Node](), handleLine)
    let paths1 = solution(&nodes1, start: "you", end: "out", ignoreNodes: Set<String>())
    print(paths1)

    var nodes2 = try! readFileLineByLine(file: file2, into: [String:Node](), handleLine)
    nodes2["out"] = Node(id: "out", outputs: Set<String>())

    let svrToDac = solution(&nodes2, start: "svr", end: "dac", ignoreNodes: ["fft"])
    print("svr -> dac (exc fft): \(svrToDac)")
    let dacToFft = solution(&nodes2, start: "dac", end: "fft", ignoreNodes: [])
    print("dac -> fft: \(dacToFft)")
    let fftToOut = solution(&nodes2, start: "fft", end: "out", ignoreNodes: [])
    print("fft -> out: \(fftToOut)")

    let svrToFft = solution(&nodes2, start: "svr", end: "fft", ignoreNodes: ["dac"])
    print("svr -> fft (exc dac): \(svrToFft)")
    let fftToDac = solution(&nodes2, start: "fft", end: "dac", ignoreNodes: [])
    print("fft -> dac: \(fftToDac)")
    let dacToOut = solution(&nodes2, start: "dac", end: "out", ignoreNodes: [])
    print("dac -> out: \(dacToOut)")

    let part2Result = (svrToDac * dacToFft * fftToOut) + (svrToFft * fftToDac * dacToOut)
    print("Part2 Result: \(part2Result)")
  }

}
