import Core
import Foundation
import RegexBuilder

struct ProductID {
  let first: Int
  let last: Int
}

func parse(_ contents: String) -> [ProductID] {
  let regex = /(?<first>\d+)-(?<last>\d+)/
  return contents.matches(of: regex).map { match in
    ProductID(
      first: Int(match.output.first)!,
      last: Int(match.output.last)!,
    )
  }
}

func isInvalidPart1(id: Int) -> Bool {
  let all = String(id)
  if all.count % 2 != 0 {
    return false
  }
  let firstBit = all.substring(to: all.count / 2)
  let secondBit = all.substring(from: all.count / 2)
  return firstBit == secondBit
}

func isInvalidPart2(id: Int) -> Bool {
  //Try each combination of numbers to see whether they are repeated througout
  let all = String(id)

  outer: for idx in 0..<all.count / 2 {
    //If all isn't divisible by the lenth, then no point in trying this one
    let subLength = idx + 1
    if all.count % subLength != 0 {
      continue
    }
    //Now look at all of the groups - do they all match?
    let firstGroup = all.substring(to: subLength)
    for startIndex in stride(from: subLength, to: all.count, by: subLength) {
      let start = all.index(all.startIndex, offsetBy: startIndex)
      let end = all.index(start, offsetBy: subLength)
      let thisGroup = all[start..<end]
      if thisGroup != firstGroup {
        //No match - move on to the next one
        continue outer
      }
    }
    //Get here it was invalid - they all matched
    return true
  }
  return false //all checks passed
}

func invalidIds(product: ProductID, test: (Int) -> Bool) -> [Int] {
  var result = [Int]()
  for id in product.first...product.last {
    if test(id) {
      result.append(id)
    }
  }
  return result
}

func sumOfInvalid(products: [ProductID], test: (Int) -> Bool) -> Int {
  products.reduce(0) { sum, product in
    let invalidIds = invalidIds(product: product, test: test)
    return sum + invalidIds.reduce(0) { sum, id in
      sum + id
    }
  }
}


@main
struct App {

  static func main() {
    let products = parse(try! readEntireFile(getFileSibling(#filePath, "Files/input.txt")))
    print(sumOfInvalid(products: products, test: isInvalidPart1))
    print(sumOfInvalid(products: products, test: isInvalidPart2))
  }

}
