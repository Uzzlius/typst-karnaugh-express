#import "@preview/cetz:0.4.2" : canvas, draw

// creates the bar based on the previously calculated positions
#let create_bar(name, start, end, offset, is_horizontal, height, small_bar_len, bar_letter_distance, stroke) = {
  let content_position = (0, 0)
  let main_line = (0, 0)
  let small_line_1 = (0, 0)
  let small_line_2 = (0, 0)
  let anchor = ""
  let length = end - start

  if is_horizontal{
    let length = end - start

    content_position = ((start + length/2, offset + bar_letter_distance))
    main_line = ((start, offset), (end, offset))
    small_line_1 = ((end, offset - small_bar_len),(end, offset + small_bar_len))
    small_line_2 = ((start, offset - small_bar_len),(start, offset + small_bar_len))

    anchor = "south"

  }else{
    start = (height - 1) - start
    end = (height - 1) - end

    let length = end - start

    content_position = (offset - bar_letter_distance, start + length/2)
    main_line = ((offset, start), (offset, end))
    small_line_1 = ((offset - small_bar_len, end),(offset + small_bar_len, end))
    small_line_2 = ((offset - small_bar_len, start),(offset + small_bar_len, start))

    anchor = "east"
  }

  draw.content(content_position, (name), anchor: anchor)
  draw.line(main_line.at(0), main_line.at(1), stroke: stroke)
  draw.line(small_line_1.at(0), small_line_1.at(1), stroke: stroke)
  draw.line(small_line_2.at(0), small_line_2.at(1), stroke: stroke)
}

// finds wether a variable is "active" for a range of given rows/columns
// positions that are right after another, like (1, 2, 3) will be combined to (1,3) for a continuous line
#let value_in_line(lines, order) = {
  let arr = ()

  order = lines - order - 1

  lines = calc.pow(2, lines)

  let first = 1
  let last = 0
  let been_on = false

  for n in range(lines){
    let c = n.bit-xor(n.bit-rshift(1))
    let c = c.bit-rshift(order).bit-and(1)
    if c == 1 {
      if n != last + 1 {
        if been_on {
          arr.push((first + 1, last +1))
        }
        first = n
      }
      been_on = true
      last = n
    }

  }
  arr.push((first+1, last+1))
  arr
}

// find out, which variables cover which rows / columns
#let create_bar_values((arrangement)) = {
  let row_dict = (:)
  let col_dict = (:)

  for (i, row) in arrangement.at(0).enumerate() {
    let arr = value_in_line(arrangement.at(0).len(), i)
    row_dict.insert(row, arr)
  }
  for (i, col) in arrangement.at(1).enumerate() {
    let arr = value_in_line(arrangement.at(1).len(), i)
    col_dict.insert(col, arr)
  }

  (row_dict, col_dict)
}

// given the variables and an arrangement, determin how to shift the bits so that the arrangement becomes
// the original variables. For example: vars = ("a", "b", "c"), arrangement = (("c"), ("a", "b"))
// you need to move c to position 0, a to position 2 and b to position 1, so (0, 2, 1)
#let generate_bit_positions(vars, arrangement) = {
  let flattened_arrangement = arrangement.flatten()
  let position_array = ()

  if vars.len() != vars.dedup().len() or flattened_arrangement.len() != flattened_arrangement.dedup().len() {panic("One or more variables appear more than once")}

  if vars.len() != flattened_arrangement.len() {panic("Too few arrangement variables")}

  for variable_arrangement in flattened_arrangement {
    let found_match = false
    for (i, variable) in vars.rev().enumerate() {
      if variable_arrangement == variable {
        position_array.push(i)
        found_match = true
        break
      }
    }
    if not found_match {panic("Arrangement of variables doesnt match the provided variables.")}
  }
  position_array
}

// combines two binary values as specified in the position array.
// for example a = 110, b = 01, position_array = (4, 2, 3, 0, 1), dim - (3,2) -> 10110
#let arrange_bits(position_array, row_gray, col_gray,  (dim), two_values: true) = {
  let amount_of_vars = dim.at(0) + dim.at(1)
  let concatenated_bits = 0
  if two_values {
    concatenated_bits = col_gray.bit-or(row_gray.bit-lshift(dim.at(1)))
  } else {
    concatenated_bits = row_gray
  }

  let cell_gray = 0

  for i in range(amount_of_vars) {
    let bit = concatenated_bits.bit-rshift(i).bit-and(1)
    bit = bit.bit-lshift(position_array.at(amount_of_vars - i -1))
    cell_gray = cell_gray.bit-or(bit)
  }
  cell_gray
}

// generate the subscripts of each cell based on the gray code of the row and column
// using helper functions from above
#let generate_subscripts(vars, arrangement) = {
  let position_array = generate_bit_positions(vars, arrangement)
  let row_bits = arrangement.at(0).len()
  let col_bits = arrangement.at(1).len()

  let rows = calc.pow(2, arrangement.at(0).len())
  let cols = calc.pow(2, arrangement.at(1).len())

  let subscript_array = ()

  for i_row in range(rows) {
    let row_array = ()
    let row_gray = i_row.bit-xor(i_row.bit-rshift(1))
    for i_col in range(cols) {
      let col_gray = i_col.bit-xor(i_col.bit-rshift(1))
      let cell_gray = arrange_bits(position_array, row_gray, col_gray, (row_bits, col_bits))
      row_array.push(cell_gray)
    }
    subscript_array.push(row_array)
  }

  subscript_array
}

// generates two standard arrangements for variables in k-maps.
// 0: alternating between row and column labeling, starting from the right
// 1: rows first, then columns, starting from the left
#let generate_standard_arrangements((vars), mode) = {
  let arrangement = ()
  let row_vars = calc.floor(vars.len()/2)
  let col_vars = calc.ceil(vars.len()/2)

  if mode == 0 {
    let col_arrangement = ()
    for i in range(col_vars) {
      col_arrangement.push(vars.at(2 * i + if(row_vars == col_vars) {1} else {0}))
    }
    let row_arrangement = ()
    for i in range(row_vars) {
      row_arrangement.push(vars.at(2 * i + if(row_vars == col_vars) {0} else {1}))
    }
    arrangement = (row_arrangement, col_arrangement)
  }

  if mode == 1 {
    arrangement = (vars.slice(0, row_vars), vars.slice(row_vars))
  }
  arrangement
}

// place the values based on the generated subscripts
#let arrange_values((values), subscripts, default) = {
  let arr = ()
  for i in range(subscripts.len()){
    let temp = ()
    for n in range(subscripts.at(i).len()){
      temp.push(values.at(subscripts.at(i).at(n), default: default))
    }
    arr.push(temp)
  }
  arr
}

// given a term, parse it so that it can later be used to compare it to the subscripts
#let parse_terms(vars, term) = {
  let arrangement = term.split(",")
  let var_val = ()
  let x = 0
  let mask = 0
  let provided_variable_count = arrangement.len()
  let amount_of_vars = vars.len()

  for i in range(arrangement.len()) {
    arrangement.at(i) = arrangement.at(i).trim(" ")
    if arrangement.at(i).first() == "!" {
      var_val.push(arrangement.at(i).trim("!"))
    }
    else {
      var_val.push(arrangement.at(i))
    }
  }
  for (i, var) in vars.enumerate() {
    if not var in var_val {var_val.push(var)}
  }
  for (i, var) in var_val.enumerate() {
    if i >= provided_variable_count {
      break
    }
    mask = mask.bit-or(1.bit-lshift(amount_of_vars - i -1))
    if arrangement.at(i).starts-with("!") {continue}
    x = x.bit-or(1.bit-lshift(amount_of_vars - i -1))
  }
  let position_array = generate_bit_positions(vars, var_val)

  mask = arrange_bits(position_array, mask, 0, (amount_of_vars, 0), two_values: false)
  x = arrange_bits(position_array, x, 0, (amount_of_vars, 0), two_values: false)

  (mask, x)
}

// parse multiple terms and put them into an array
#let find_terms(vars, terms) = {
  let parsed_terms = ()
  for term in terms{
    parsed_terms.push(parse_terms(vars, term))
  }
  parsed_terms
}

// use the parsed terms to determine what cells should be active
#let find_matching_term_positions(parsed_terms, subscripts) = {
  let coordinates = ()
  for term in parsed_terms {
    let inb = ()
    for (i_row, row) in subscripts.enumerate() {
      for (i_col, cell_code) in subscripts.at(i_row).enumerate() {
        if cell_code.bit-and(term.at(0)) == term.at(1) {
          inb.push((i_col, i_row))
        }
      }
    }
    coordinates.push(inb)
  }
  coordinates
}

// create the standard "label" based on the provided variables
#let create_var_string(vars) = {
  let string = ""
  for (i, var) in vars.enumerate() {
    string = string + if i != 0 {", "} else {""} + var
  }
  string
}

//arrange the display variables in the same way as the functional variables
#let arrange_disp_vars(var_disp, arrangement, vars) = {
  let var_disp_len = var_disp.len()
  let var_len = vars.len()

  let new_disp = ()

  for row in arrangement {
    let inb = ()
    for (i_col, val) in row.enumerate() {
      let index = vars.position(x => x == val)
      inb.push(var_disp.at(index, default: vars.at(index)))
    }
    new_disp.push(inb)
  }
  new_disp
}
