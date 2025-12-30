import Collections
import Core
import Foundation
import RationalModule

enum OnOff: String, CustomStringConvertible {
  case on = "#"
  case off = "."

  var description: String {
    return self.rawValue
  }

  func toggle() -> OnOff {
    return self == .on ? .off : .on
  }
}

class PuzzleLine: CustomStringConvertible {
  let requiredConfiguration: [OnOff]
  let toggles: [[Int]]
  let joltageRequirement: [Int]

  init(requiredConfiguration: [OnOff], toggles: [[Int]], joltageRequirement: [Int]) {
    self.requiredConfiguration = requiredConfiguration
    self.toggles = toggles
    self.joltageRequirement = joltageRequirement
  }

  var description: String {
    return "\(requiredConfiguration) \(toggles) \(joltageRequirement)"
  }
}

private func handleLine(_ lines: inout [PuzzleLine], line: String) {
  let lineRegex = /\[(?<required>[^\}]+)\] |\((?<toggle>[^\)]+?)\) |\{(?<joltage>[^\}]+)\}/
  let matches = line.matches(of: lineRegex)
  let requiredConfiguration = (matches.first!.required).map({req in
    req.map{ OnOff(rawValue: String($0))! }
  })!
  let toggles = matches.dropFirst().dropLast().map({ match in
    let togglesString = match.toggle!
    return togglesString.components(separatedBy: ",").map{ Int($0)! }
  })
  let joltageRequirement = matches.last!.joltage.map({ joltage in
    joltage.components(separatedBy: ",").map({ Int($0)! })
  })!
  lines.append(PuzzleLine(requiredConfiguration: requiredConfiguration, toggles: toggles, joltageRequirement: joltageRequirement))
}

private func calcToggles(_ line: PuzzleLine) -> Int {
  var foundConfigurations = [[OnOff]:Int]()
  let emptyLine = line.requiredConfiguration.map { _ in OnOff.off }
  foundConfigurations[emptyLine] = 0
  for rep in 1...10000 {
    var newConfigurations = [[OnOff]:Int]()
    for toggles in line.toggles {
      for foundConfiguration in foundConfigurations.keys {
        var newConfiguration = foundConfiguration
        for toggle in toggles {
          newConfiguration[toggle] = newConfiguration[toggle].toggle()
        }
        if newConfiguration == line.requiredConfiguration {
          // We got what we need on this rep
          return rep
        }
        if foundConfigurations.keys.contains(newConfiguration) {
          // already had this in same or less
          continue
        }
        //first time we saw it
        newConfigurations[newConfiguration] = rep
      }
    }
    //Add the new ones in to search next time
    foundConfigurations.merge(newConfigurations) { (original, _) in original }
  }
  print("Failed on: \(line)")
  return -1
}

private func part1(_ lines: [PuzzleLine]) -> Int {
  return lines.reduce(0) { acc, line in
    return acc + calcToggles(line)
  }
}

typealias MatrixValue = Double
let minusOne = -1.0
let zero = 0.0
let one = 1.0
let delta = 0.001

// extension MatrixValue: @retroactive @unchecked Sendable {}

extension MatrixValue {
  var isNegative: Bool {
    return !isEffectivelyZero && self < 0
  }
  var isFractional: Bool {
    return !isEffectivelyZero && abs(self - self.rounded(.toNearestOrAwayFromZero)) > delta
  }
  var asInteger: Int {
    return Int(self.rounded(.toNearestOrAwayFromZero))
  }
  var isEffectivelyZero: Bool {
    return abs(self) < delta
  }
  var clean: String {
    return String(format:"%.8g", self)
  }
}

private func printMatrix(_ matrix: inout [[MatrixValue]]) {
  for row in matrix {
    var rowString = ""
    for value in row {
      rowString += "\(value) "
    }
    print(rowString)
  }
  print("")
}

enum MatrixError: Error {
    case noSolution(String)
}

enum Term {
    case rawValue(MatrixValue)
    case variable(MatrixValue, Int)  // e.g., t1, 2.t2, ...

    static func multiply(_ scalar: MatrixValue, _ terms: [Term]) -> [Term] {
        var result: [Term] = []
        for term in terms {
            switch term {
            case .rawValue(let value):
                result.append(.rawValue(scalar * value))
            case .variable(let coeff, let index):
                result.append(.variable(scalar * coeff, index))
            }
        }
        return result
    }

    static func collapse(_ terms: [Term]) -> [Term] {
        var combined: OrderedDictionary<Int, MatrixValue> = [:]
        var rawValue: MatrixValue = zero

        for term in terms {
            switch term {
            case .rawValue(let value):
                rawValue = rawValue + value
            case .variable(let coeff, let index):
                combined[index] = (combined[index] ?? zero) + coeff
            }
        }

        var result: [Term] = []
        if !rawValue.isEffectivelyZero {
            result.append(.rawValue(rawValue))
        }
        for (index, coeff) in combined {
            if !coeff.isEffectivelyZero {
                result.append(.variable(coeff, index))
            }
        }
        return result
    }

    static func termsString(_ terms: [Term]) -> String {
        var parts: [String] = []
        for term in terms {
            switch term {
            case .rawValue(let value):
                parts.append("\(value.clean)")
            case .variable(let coeff, let index) where coeff == one :
                parts.append("t\(index)")
            case .variable(let coeff, let index) where coeff == minusOne :
                parts.append("-t\(index)")
            case .variable(let coeff, let index):
                parts.append("\(coeff.clean)*t\(index)")
            }
        }
        return parts.joined(separator: " + ")
    }

    static func calculateValue(_ terms: [Term], _ freeVarValues: inout [MatrixValue]) -> MatrixValue {
        var result: MatrixValue = zero
        for term in terms {
            switch term {
            case .rawValue(let value):
                result = result + value
            case .variable(let coeff, let index):
                result = result + coeff * freeVarValues[index]
            }
        }
        return result
    }

    static func variablesInTerms(_ terms: [Term]) -> Set<Int> {
        var vars: Set<Int> = []
        for term in terms {
            switch term {
            case .rawValue(_):
                continue
            case .variable(_, let index):
                vars.insert(index)
            }
        }
        return vars
    }
}

func convertToMatrix(_ puzzleLine: PuzzleLine) -> [[MatrixValue]] {
    let numVariables = puzzleLine.toggles.count
    let numEquations = puzzleLine.requiredConfiguration.count

    // Initialize augmented matrix with zeros
    var augmentedMatrix: [[MatrixValue]] = Array(repeating: Array(repeating: zero, count: numVariables + 1), count: numEquations)

    // Fill the matrix based on toggles
    for (varIndex, toggleIndices) in puzzleLine.toggles.enumerated() {
        for toggleIndex in toggleIndices {
            augmentedMatrix[toggleIndex][varIndex] = augmentedMatrix[toggleIndex][varIndex] + one
        }
    }

    // Fill the last column based on required configuration
    for (eqIndex, requiredJoltage) in puzzleLine.joltageRequirement.enumerated() {
        augmentedMatrix[eqIndex][numVariables] = MatrixValue(requiredJoltage)
    }

    return augmentedMatrix
}

typealias SolutionLine = (terms: [Term], variables: Set<Int>)

/// Solves an underdetermined linear system using Gaussian elimination.
/// - Parameter augmentedMatrix: The [A | b] matrix as a 2D array (m rows, n+1 columns).
/// - Returns: A tuple containing:
///     - solution terms and variables in the terms array
///     - A string describing the solution (parametric form) or "No solution" if inconsistent.
///     - An integer indicating the number of free variables or -1 if there is "No solution".
func solveUnderdeterminedSystem(augmentedMatrix: [[MatrixValue]]) -> ([SolutionLine], String, Int) {
    let m = augmentedMatrix.count  // Number of equations
    let n = augmentedMatrix[0].count - 1  // Number of variables

    // Make a mutable copy
    var matrix = augmentedMatrix.map { $0 }

    // Gaussian elimination to row echelon form
    var lead = 0  // Current leading column
    for r in 0..<m {
        // Find pivot row (partial pivoting for numerical stability)
        var pivotRow = r
        for i in r..<m {
            if abs(matrix[i][lead]) > abs(matrix[pivotRow][lead]) {
                pivotRow = i
            }
        }

        // Swap rows if needed
        if pivotRow != r {
            matrix.swapAt(r, pivotRow)
        }

        // If pivot is zero, move to next column
        if matrix[r][lead].isEffectivelyZero {
            lead += 1
            if lead >= n { break }
            continue
        }

        // Eliminate below the pivot
        for i in (r+1)..<m {
            let factor = matrix[i][lead] / matrix[r][lead]
            for j in lead...(n) {
                matrix[i][j] -= factor * matrix[r][j]
            }
        }

        lead += 1
        if lead >= n { break }
    }

    printMatrix(&matrix)

    // Check for inconsistency (non-zero in last column with zero row)
    var rank = 0
    for row in matrix {
        let isZeroRow = row[0..<n].allSatisfy { $0.isEffectivelyZero }
        if isZeroRow && !row[n].isEffectivelyZero {
            return ([], "No solution (inconsistent system)", -1)
        }
        if !isZeroRow { rank += 1 }
    }

    // Back-substitution to find parametric solution
    var solution: [[Term]] = Array(repeating: [], count: n)  // One entry per variable
    var freeVars: [Int] = []  // Indices of free variables
    var paramIndex = 0  // For t1, t2, etc.

    // Track assigned variables
    var assigned = Set<Int>()

    // Start from bottom rows
    for r in stride(from: m-1, through: 0, by: -1) {
        // Find the leading variable in this row
        var leadCol = -1
        for c in 0..<n {
            if !matrix[r][c].isEffectivelyZero {
                leadCol = c
                break
            }
        }
        if leadCol == -1 { continue }  // Zero row

        // Express lead variable in terms of later ones
        var terms = [Term.rawValue(matrix[r][n] / matrix[r][leadCol])]  // Constant term
        for c in (leadCol+1)..<n {
            let coeff = -matrix[r][c] / matrix[r][leadCol]
            if !coeff.isEffectivelyZero {
                if solution[c].isEmpty {
                    // Free variable
                    if !freeVars.contains(c) {
                        solution[c].append(.variable(one, paramIndex))
                        freeVars.append(c)
                        paramIndex += 1
                    }
                }
                terms.append(contentsOf: Term.multiply(coeff, solution[c]))
            }
        }
        solution[leadCol] = Term.collapse(terms)
        assigned.insert(leadCol)
    }

    // Any remaining unassigned variables are free
    for c in 0..<n {
        if !assigned.contains(c) && solution[c].isEmpty {
            solution[c].append(.variable(one, paramIndex))
            freeVars.append(c)
            paramIndex += 1
        }
    }

    // Build the output string
    var solutionString = "General solution:\n"
    for i in 0..<n {
        let termsString = solution[i].isEmpty ? "0" : Term.termsString(solution[i])
        solutionString += "x\(i) = \(termsString)\n"
    }
    if freeVars.isEmpty {
        solutionString += "(Unique solution)\n"
    } else {
        solutionString += "Where t0, t1, ... are free parameters.\n"
    }
    return (solution.map{ (terms: $0, variables: Term.variablesInTerms($0)) }, solutionString, freeVars.count)
}

enum ViolationType {
    case none
    case negativeValue
    case fractionalValue
}

private func violatesConstraints(_ solutionLines: [SolutionLine], _ allocations: inout [MatrixValue]) -> ViolationType {
  // this is a set of the variables indexes that we have
  let variablesInAllocations = Set(0..<allocations.count)
  //Check each line - bottom to top as we should have fewer variables in the bottom lines?
  for line in solutionLines {
    //Do we have all of the values? in this line?
    if !line.variables.isSubset(of: variablesInAllocations) {
      //We don't have all the values yet
      continue
    }
    //Calculate the button presses value
    let value = Term.calculateValue(line.terms, &allocations)
    //If any variable is negative, we violate constraints
    if value.isNegative {
      return .negativeValue
    }
    //If any variable is fractional, we violate constraints
    if value.isFractional {
      return .fractionalValue
    }
  }
  return .none
}

// Recursively attributes non-negative integer values to free variables and tries to find a valid solution.
// returns the lowest value found, or nil if none found.
private func attributeAndCalculate(
  solutionLinesByHighestLevel: inout [Int:[SolutionLine]],
  constraintViolations: inout [[MatrixValue]:ViolationType],
  level: Int,
  remainingToAllocate: Int,
  numFreeVars: Int,
  allocations: [MatrixValue],
  trySolution: (inout [MatrixValue]) -> Int?,
) -> ([MatrixValue], Int)? {
  if level == numFreeVars {
    var newAllocations = allocations
    newAllocations.append(MatrixValue(remainingToAllocate))

    if violatesConstraints(solutionLinesByHighestLevel[level]!, &newAllocations) != .none {
      return nil
    }

    //We can calculate
    let presses = trySolution(&newAllocations)
    if let presses {
      return (newAllocations, presses)
    }
    return nil
  }

  func checkConstraints(_ checkConstraintAllocations: inout [MatrixValue]) -> ViolationType {
    // If this violates constraints, skip it (and maybe bomb out completely)
    var violationType = constraintViolations[checkConstraintAllocations]
    if violationType == nil {
      violationType = violatesConstraints(solutionLinesByHighestLevel[level]!, &checkConstraintAllocations)
      constraintViolations[checkConstraintAllocations] = violationType
    }
    return violationType!
  }

  //Do the next level
  var bestSolution: ([MatrixValue], Int)? = nil
  var foundValid = false

  allocationLoop: for i in 0...remainingToAllocate {

    var newAllocations = allocations
    newAllocations.append(MatrixValue(i))

    // If this violates constraints, skip it (and maybe bomb out completely)
    let violationType = checkConstraints(&newAllocations)
    switch violationType {
      case .negativeValue:
        if foundValid {
          // we had a valid one already, we've reached an invalid integer one - that aint going to change so completely bomb
          break allocationLoop
        }
        continue allocationLoop
      case .fractionalValue:
        continue allocationLoop
      default:
        break // out of switch
    }
    foundValid = true

    let possibleSolution = attributeAndCalculate(
      solutionLinesByHighestLevel: &solutionLinesByHighestLevel,
      constraintViolations: &constraintViolations,
      level: level + 1,
      remainingToAllocate: remainingToAllocate - i,
      numFreeVars: numFreeVars,
      allocations: newAllocations,
      trySolution: trySolution,
    )
    //Found a possible solution, is it the best?
    if let (allocations, presses) = possibleSolution {
      if bestSolution == nil || presses < bestSolution!.1 {
        bestSolution = (allocations, presses)
      }
    }
  }
  return bestSolution
}

private func calculateMinSolution(_ lineIndex: Int, _ puzzleLine: PuzzleLine, _ solution: inout [SolutionLine], _ numFreeVars: Int) -> Int? {
  // We want to minimise the total number of presses, which is the sum of all variables.
  let allTerms = Term.collapse(solution.flatMap{ $0.terms })
  print("Terms to minimize (according to constraints): \(Term.termsString(allTerms))")

  func trySolution(_ allocations: inout [MatrixValue]) -> Int? {
    //Calculate all terms
    let calculatedPresses = solution.map { Term.calculateValue($0.terms, &allocations) }
    //Calculate the joltages that this produces, keeping a count of the number of presses
    var calculatedJoltages = Array(repeating: 0, count: puzzleLine.joltageRequirement.count)
    var totalPresses = 0
    for (varIndex, buttonPresses) in calculatedPresses.enumerated() {
      // negative or fractional presses make no sense - drop out now
      if buttonPresses.isNegative || buttonPresses.isFractional {
        return nil
      }
      //Ok apply them all...
      for toggleIndex in puzzleLine.toggles[varIndex] {
        let updatedJoltage = calculatedJoltages[toggleIndex] + buttonPresses.asInteger
        // if this will blow through what we need, drop out straight away
        if updatedJoltage > puzzleLine.joltageRequirement[toggleIndex] {
          return nil
        }
        // update the joltage and record the presses
        calculatedJoltages[toggleIndex] = updatedJoltage
      }
      // and keep a track of the total presses
      totalPresses += buttonPresses.asInteger
    }
    //Final check that this matches the required puzzle solution
    for (index, calculatedValue) in calculatedJoltages.enumerated() {
      let requiredValue = puzzleLine.joltageRequirement[index]
      if calculatedValue != requiredValue {
        return nil
      }
    }
    //They all matched - return the total presses
    return totalPresses
  }

  var constraintViolations = [[MatrixValue]:ViolationType]()
  var solutionLinesByHighestLevel = solution.reduce(into: [Int:[SolutionLine]]()) { acc, line in
    let level = (line.variables.max() ?? -1) + 1
    var linesAtLevel = acc[level] ?? []
    linesAtLevel.append(line)
    acc[level] = linesAtLevel
  }

  var minPresses: Int? = nil
  for i in 0...250 {
    if let (_, presses) = attributeAndCalculate(
      solutionLinesByHighestLevel: &solutionLinesByHighestLevel,
      constraintViolations: &constraintViolations,
      level: 1,
      remainingToAllocate: i,
      numFreeVars: numFreeVars,
      allocations: [MatrixValue](),
      trySolution: trySolution,
    ) {
      //best so far?
      if minPresses == nil || presses < minPresses! {
        minPresses = presses
      }
    }
  }
  return minPresses
}

private func part2(_ lines: [PuzzleLine]) -> Int {
  return lines.enumerated().reduce(0) { acc, indexAndLine in
    let start = Date()
    print("Processing line: \(indexAndLine.offset)")
    var matrix = convertToMatrix(indexAndLine.element)
    printMatrix(&matrix)
    let (solution, solutionString, numFreeVars) = solveUnderdeterminedSystem(augmentedMatrix: matrix)
    print(solutionString)
    print("There are \(numFreeVars) free variables.")
    let increment: Int
    if numFreeVars < 1 {
      //We should already have the solution
      var allocations = [MatrixValue]()
      let presses = solution.reduce(0) { $0 + Term.calculateValue($1.terms, &allocations) }
      print("Direct solution for line \(indexAndLine.offset): \(presses)\n")
      increment = presses.asInteger
    } else {
      //otherwise search for it.
      var solution = solution
      let minSolution = calculateMinSolution(indexAndLine.offset, indexAndLine.element, &solution, numFreeVars)
      print("Minimum solution for line \(indexAndLine.offset): \(minSolution ?? -1)\n")
      increment = minSolution ?? 0
    }
    print("Calculation took \(Date().timeIntervalSince(start)) seconds\n")
    return acc + increment
  }
}

@main
struct App {

  static func main() {
    // let file = getFileSibling(#filePath, "Files/example.txt")
    // let file = getFileSibling(#filePath, "Files/example2.txt")
    let file = getFileSibling(#filePath, "Files/input.txt")

    let lines = try! readFileLineByLine(file: file, into: [PuzzleLine](), handleLine)
    // print(lines)

    let part1 = part1(lines)
    print(part1)

    let part2 = part2(lines)
    print(part2)
  }

}
