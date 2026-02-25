#import "@preview/cetz:0.4.2" : canvas, draw
#import "utils.typ": *

#let karnaugh(
    (variables),
    (values),
    arrangement: "",
    arrangement_standard: 0,

    terms: "",
    var_disp: (),

    stroke: 0.5pt,
    grid_size: 0.8cm,
    draw_subscripts:true,

    transparency: 70%,
    colors: (blue, green, yellow, purple, red),


    default_fill: "",
    label: "",

    value_size: 1em,
    subscript_size: 0.6em,
    distance_subscript_corner: 0.05,
    distance_bar_grid: 0.3,
    distance_bar_bar: 0.8,
    distance_bar_letter: 0.1,
    small_bar_len: 0.1,
    label_position: (0.2, 0.2)

  ) = {

  //create default label
  if label == "" {
    let var_string = create_var_string(variables)
    label = "f(" + var_string + ")"
  }

  //Generates one of two deault arrangements for k-maps
  if arrangement == "" {
    arrangement = generate_standard_arrangements(variables, arrangement_standard)
  }

  //Generates the subscripts of the cells
  let subscripts = generate_subscripts(variables, arrangement)

  //Calculate the amount of rows and columns
  let columns = calc.pow(2, arrangement.at(0).len())
  let rows = calc.pow(2, arrangement.at(1).len())

  //Arranges the display variables in the same way as the functinal variables
  //if no display variables are provided, use the functional variables
  if var_disp == () {
    var_disp = arrangement
  }
  else{
    var_disp = arrange_disp_vars(var_disp, arrangement, variables)
  }

  //arrange the provided values based on the generated subscripts
  let arranged_values = arrange_values(values, subscripts, default_fill)

  //calculate, where the bars have to go
  //returns which rows/columns are being covered for a given variable
  let bar_definer = create_bar_values(arrangement)

  //find the terms
  let term_positions = find_matching_term_positions(find_terms(variables, terms), subscripts)

  //draw
  canvas(length: grid_size,{
    // the grid is shifted by 0.5, so that coordinates are always in the center of a grid cell
    let abs_offset = 0.5
    let distance_subscript_corner = (abs_offset - distance_subscript_corner)

    //highlight the cells as specified in the provided terms
    for (i, term) in term_positions.enumerate() {
      for n in term {
        let coordinate_center = (n.at(0), columns - n.at(1) -1)
        draw.rect((coordinate_center.at(0) -0.5, coordinate_center.at(1) -0.5), (coordinate_center.at(0) +0.5, coordinate_center.at(1) +0.5), fill: colors.at(calc.rem(i, colors.len())).transparentize(transparency), stroke: 0pt)
      }
    }

    //draw the grid
    draw.grid((rows - abs_offset, columns - abs_offset), (-abs_offset, - abs_offset), stroke: stroke)

    //draw values and subscripts
    for column in range(columns) {
      for row in range(rows) {

        //draw values
        draw.content((row, (columns - 1) - column), text(str(arranged_values.at(column, default: ()).at(row, default: default_fill)), size: value_size))

        //draw subscripts
        if draw_subscripts{
        draw.content(
          (row + distance_subscript_corner, ((columns -1)-column) - distance_subscript_corner),
          text(str(
            subscripts.at(column, default: ()).at(row, default: "")
            ), size: subscript_size),
            anchor: "south-east"
          )
        }
      }
    }

    //holds the distance of a bar to the grid. (distance for vertical, distance for horizontal)
    let offset = (-abs_offset -distance_bar_grid, columns - abs_offset + distance_bar_grid)
    for (i, el) in bar_definer.enumerate() {
      for (n, (_, lines)) in el.pairs().enumerate().rev() {

        for line in lines {
          create_bar(
            var_disp.at(i).at(n),
            line.at(0) - (1 + abs_offset),
            line.at(1) - abs_offset,
            offset.at(i),
            if i == 0 {false} else {true},
            columns,
            small_bar_len,
            distance_bar_letter,
            stroke
          )
        }

        //update the offset for the next bar
        offset.at(i) += if i == 1 {distance_bar_bar} else {-distance_bar_bar}
      }
    }

    //draw label
    draw.content((0 - abs_offset - label_position.at(0), columns - abs_offset + label_position.at(1)), $label$, anchor: "south-east")

  })
}
