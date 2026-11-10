#import "@preview/cetz:0.5.2" : canvas, draw
#import "src/utils.typ": *
#import "src/graycode-handling.typ": *
#import "src/terms.typ": *
#import "src/arrangement-standards.typ": *
#import "src/term-drawing.typ": *
#import "src/bars.typ": *
#import "src/value-handling.typ": *

#let karnaugh(
  variables,
  values,

  arrangement: auto,
  arrangement-standard: 0,

  terms: (),
  var-disp: (),

  stroke: 0.5pt,
  draw-subscripts: true,

  default-fill: none,
  function-name: $f$,
  label: auto,

  value-font-size: 1em,
  subscript-font-size: 0.6em,
  distance-subscript-corner: 0.05,
  distance-bar-grid: 0.3,
  distance-bar-bar: 0.8,
  distance-bar-letter: 0.1,
  small-bar-len: 0.1,

  label-position: (0.2, 0.2),

  highlight-transparency: 70%,
  highlight-colors: (blue, green, yellow, purple, red),
  highlight-radius: 0.2,
  highlight-inset: 0.1,
  highlight-steps: 1,
  highlight-stroke: 0.5pt,
  ) = {

  // Create default label
  if label == auto {
    label = create-label-equation(
      var-disp + variables.slice(var-disp.len()),
      funcname: function-name
    )
  }

  // Generates one of two deault arrangements for k-maps
  if arrangement == auto {
    arrangement = generate-standard-arrangement(variables, arrangement-standard)
  }

  // Generates the graycodes of the cells
  let cell-gray-codes = generate-cell-graycodes(variables, arrangement)

  // Calculate the amount of rows and columns
  let column-count = calc.pow(2, arrangement.at(0).len())
  let row-count = calc.pow(2, arrangement.at(1).len())

  // Arranges the display variables in the same way as the functinal variables
  // if no display variables are provided, use the functional variables
  if var-disp == () {
    var-disp = arrangement
  }
  else{
    var-disp = arrange-disp-vars(var-disp, arrangement, variables)
  }

  // Arrange the provided values based on the generated graycodes
  let placed-values = order-values(values, cell-gray-codes, default-fill)

  // Calculate, where the bars have to go
  // Returns which rows/columns are being covered for a given variable
  let bar-positions = calculate-bar-positions(arrangement)

  // Parse all the terms
  let parsed-term-list = parse-term-list(variables, terms)

  // Calculate the term coordinates
  let term-coordinates-list = term-list-to-active-coordinates(parsed-term-list, cell-gray-codes)

  // Draw everything
  draw.group(name: "name", {
    // The grid is shifted by 0.5, so that coordinates are always in the center of a grid cell
    let abs-offset = 0.5
    let subscript-dist = (abs-offset - distance-subscript-corner)

    // Draw the terms into the K-map
    draw-multiple-bundle-cells(term-coordinates-list, highlight-colors, highlight-inset, highlight-steps, highlight-stroke, column-count, row-count, highlight-radius, highlight-transparency)

    // Draw the grid
    draw.grid((row-count - abs-offset, column-count - abs-offset), (-abs-offset, - abs-offset), stroke: stroke)

    // Place the values in the grid and draw the subscripts
    draw-values-and-subscripts(placed-values, cell-gray-codes, value-font-size, draw-subscripts, subscript-dist, subscript-font-size)

    // Draw all of the bars that indicate where a variable is active
    draw-all-bars(bar-positions, abs-offset, distance-bar-grid, distance-bar-bar, distance-bar-letter, column-count, var-disp, small-bar-len, stroke)

    // Draw the Label
    draw.content((0 - abs-offset - label-position.at(0), column-count - abs-offset + label-position.at(1)), label, anchor: "south-east")

  })
}
