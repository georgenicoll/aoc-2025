import re
from pulp import LpProblem, LpMinimize, LpVariable, lpSum, LpInteger

def solve(buttonses, joltages) -> float:
    # Adapted from https://coin-or.github.io/pulp/CaseStudies/a_blending_problem.html
    prob = LpProblem("Joltages", LpMinimize)

    # variables are the number of presses of each button - same number of these as number of buttons(es)
    variables = [ LpVariable(f"butt_{i}", lowBound=0, cat=LpInteger) for i in range(len(buttonses)) ]

    # problem data - objective first
    prob += lpSum(variables), "Minimise the number of presses"

    # problem data - constraints - these are for each button and it's equivalent joltage
    # we enter them 'vertically', i.e. each column adds up to the wanted joltage
    for i in range(len(joltages)):
        button_variables = []
        for j in range(len(buttonses)):
            buttons = buttonses[j]
            if i in buttons:
                button_variables.append(variables[j])
        prob += lpSum(button_variables) == joltages[i], f"joltage_{i}"

    # write it to a file
    prob.writeLP("joltages.lp")

    # solve it
    prob.solve()

    # extract the variables and sum them up
    total = 0
    for v in variables:
        total += v.value()

    return total

def main():
    # file = 'Sources/Day10/Files/example.txt'
    file = 'Sources/Day10/Files/input.txt'
    total = 0
    with open(file, 'r') as f:
        lines = f.readlines()
        for line in lines:
            matches = re.findall(r'\((.*?)\)', line)
            buttonses = [list(map(int, match.split(','))) for match in matches]
            joltageMatch = re.search(r'\{(.*)\}', line)
            joltages = [int(i) for i in joltageMatch.group(1).split(',')]
            total += solve(buttonses, joltages)

    print(total)

if __name__ == '__main__':
    main()
