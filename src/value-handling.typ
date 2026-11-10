#import "@preview/cetz:0.5.3": draw
#import draw: *

// Draws the subscripts and values to the correct cells
#let draw-values-and-subscripts(placed-values, cell-graycodes, value-font-size, draw-subscripts, subscript-dist, subscript-font-size) = {
  let row-count = cell-graycodes.len()
  let column-count = cell-graycodes.at(0).len()

  // Loop thorugh every cell
  for row in range(row-count) {
    for column in range(column-count) {

      let cell-graycode = cell-graycodes.at(column).at(row)

      let value = [#placed-values.at(column, default: ()).at(row, default: none)]
      // Draw values
      content(name: str(cell-graycode), (row, (column-count - 1) - column), text(value, size: value-font-size))

      // Draw subscripts
      if draw-subscripts{
      content(
        (row + subscript-dist, ((column-count -1)-column) - subscript-dist),
        text(str(
          cell-graycode
          ), size: subscript-font-size),
          anchor: "south-east"
        )
      }
    }
  }
}


// Places provided values in the order of the truth table
#let order-values(values, cell-graycodes, default) = {
  let values-placed = ()
  for row in range(cell-graycodes.len()){
    let row-placed = ()

    // Loop thorugh all of the cells, retrieve the cell-gray-code there
    // and place the correct value
    for col in range(cell-graycodes.at(row).len()){

      // Find the value that belongs here by using
      // the gray code of the cell as an index
      row-placed.push(values.at(cell-graycodes.at(row).at(col), default: default))

    }
    values-placed.push(row-placed)
  }
  values-placed
}
