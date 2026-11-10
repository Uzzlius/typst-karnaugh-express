#import "@preview/cetz:0.5.3" : draw
#import "graycode.typ": generate-bit-positions, position-bits

// creates the bar based on the previously calculated positions
#let create-bar(name, start, end, offset, is-horizontal, height, small-bar-len, bar-letter-distance, stroke) = {
  let content-position = (0, 0)
  let main-line = (0, 0)
  let small-line-1 = (0, 0)
  let small-line-2 = (0, 0)
  let anchor = ""

  if is-horizontal{
    let length = end - start

    content-position = ((start + length/2, offset + bar-letter-distance))
    main-line = ((start, offset), (end, offset))
    small-line-1 = ((end, offset - small-bar-len),(end, offset + small-bar-len))
    small-line-2 = ((start, offset - small-bar-len),(start, offset + small-bar-len))

    anchor = "south"

  }else{
    start = (height - 1) - start
    end = (height - 1) - end

    let length = end - start

    content-position = (offset - bar-letter-distance, start + length/2)
    main-line = ((offset, start), (offset, end))
    small-line-1 = ((offset - small-bar-len, end),(offset + small-bar-len, end))
    small-line-2 = ((offset - small-bar-len, start),(offset + small-bar-len, start))

    anchor = "east"
  }

  draw.content(content-position, (name), anchor: anchor)
  draw.line(main-line.at(0), main-line.at(1), stroke: stroke)
  draw.line(small-line-1.at(0), small-line-1.at(1), stroke: stroke)
  draw.line(small-line-2.at(0), small-line-2.at(1), stroke: stroke)
}

// finds wether a variable is "active" for a range of given rows/columns
// positions that are right after another, like (1, 2, 3) will be combined to (1,3) for a continuous line
#let value-in-line(lines, order) = {
  let arr = ()

  order = lines - order - 1

  lines = calc.pow(2, lines)

  let first = 1
  let last = 0
  let been-on = false

  for n in range(lines){
    let c = n.bit-xor(n.bit-rshift(1))
    let c = c.bit-rshift(order).bit-and(1)
    if c == 1 {
      if n != last + 1 {
        if been-on {
          arr.push((first + 1, last +1))
        }
        first = n
      }
      been-on = true
      last = n
    }

  }
  arr.push((first+1, last+1))
  arr
}

// find out, which variables cover which rows / columns
#let create-bar-values((arrangement)) = {
  let row-dict = (:)
  let col-dict = (:)

  for (i, row) in arrangement.at(0).enumerate() {
    let arr = value-in-line(arrangement.at(0).len(), i)
    row-dict.insert(row, arr)
  }
  for (i, col) in arrangement.at(1).enumerate() {
    let arr = value-in-line(arrangement.at(1).len(), i)
    col-dict.insert(col, arr)
  }

  (row-dict, col-dict)
}


// generates two standard arrangements for variables in k-maps.
// 0: alternating between row and column labeling, starting from the right
// 1: rows first, then columns, starting from the left
// for example
// generate-standard-arrangements(("x1", "x2", "x3"), 0) = (("x2"), ("x1", "x3"))
#let generate-standard-arrangements((vars), mode) = {
  let arrangement = ()
  let row-vars = calc.floor(vars.len()/2)
  let col-vars = calc.ceil(vars.len()/2)

  if mode == 0 {
    let col-arrangement = ()
    for i in range(col-vars) {
      col-arrangement.push(vars.at(2 * i + if(row-vars == col-vars) {1} else {0}))
    }
    let row-arrangement = ()
    for i in range(row-vars) {
      row-arrangement.push(vars.at(2 * i + if row-vars == col-vars {0} else {1}))
    }
    arrangement = (row-arrangement, col-arrangement)
  }

  else if mode == 1 {
    arrangement = (vars.slice(0, row-vars), vars.slice(row-vars))
  }

  arrangement
}

// place the values based on the generated subscripts
#let arrange-values((values), subscripts, default) = {
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


// use the parsed terms to determine what cells should be active
#let find-matching-term-positions(parsed-terms, subscripts) = {
  let coordinates = ()
  for term in parsed-terms {
    let inb = ()
    for (i-row, row) in subscripts.enumerate() {
      for (i-col, cell-code) in subscripts.at(i-row).enumerate() {
        if cell-code.bit-and(term.at(0)) == term.at(1) {
          inb.push((i-col, i-row))
        }
      }
    }
    coordinates.push(inb)
  }
  coordinates
}

// create the standard "label" based on the provided variables
#let create-label-equation(vars, funcname: $f$) = {
  math.equation(funcname + math.lr($($ + vars.join($,$) + $)$))
}

//arrange the display variables in the same way as the functional variables
#let arrange-disp-vars(var-disp, arrangement, vars) = {
  let var-disp-len = var-disp.len()
  let var-len = vars.len()

  let new-disp = ()

  for row in arrangement {
    let inb = ()
    for (i-col, val) in row.enumerate() {
      let index = vars.position(x => x == val)
      inb.push(var-disp.at(index, default: vars.at(index)))
    }
    new-disp.push(inb)
  }
  new-disp
}


// Draw one cell's contribution to a group outline.
// neighbours: (north, east, south, west) — true if that neighbour is in the same group.
// pad: gap between the outline and the grid edge (only on exposed sides).
#let draw-bundle-cell(pos, neighbours, radius: 0.15, pad: 0.1, ..style) = {
  let (cx, cy) = pos
  let h = 0.5
  let (n, e, s, w) = neighbours

  // Inset exposed sides by pad; flush with grid on shared sides
  let xl = cx - h + (if w { 0 } else { pad })
  let xr = cx + h - (if e { 0 } else { pad })
  let yt = cy + h - (if n { 0 } else { pad })
  let yb = cy - h + (if s { 0 } else { pad })

  // Round a corner only when both adjacent sides are exposed
  let rnw = if not n and not w { radius } else { 0 }
  let rne = if not n and not e { radius } else { 0 }
  let rse = if not s and not e { radius } else { 0 }
  let rsw = if not s and not w { radius } else { 0 }

  let m = 0.551784  // bezier circle approximation constant
  let bez(p, q, d0x, d0y, d1x, d1y, r) = draw.bezier(
    p, q,
    (p.at(0) + d0x * m * r, p.at(1) + d0y * m * r),
    (q.at(0) + d1x * m * r, q.at(1) + d1y * m * r),
    ..style, fill: none, close: false
  )

  // Trace clockwise. Draw exposed segments; move-to over internal ones.
  {
    // Top edge
    if not n { draw.line((xl + rnw, yt), (xr - rne, yt), ..style, fill: none, close: false)}

    // NE corner
    if not n and not e { bez((xr - rne, yt), (xr, yt - rne),  1,  0,  0,  1, rne)}

    // Right edge
    if not e { draw.line((xr, yt - rne), (xr, yb + rse), ..style, fill: none, close: false)}

    // SE corner
    if not s and not e { bez((xr, yb + rse), (xr - rse, yb),  0, -1,  1,  0, rse)}

    // Bottom edge
    if not s { draw.line((xr - rse, yb), (xl + rsw, yb), ..style, fill: none, close: false)}

    // SW corner
    if not s and not w { bez((xl + rsw, yb), (xl, yb + rsw), -1,  0,  0, -1, rsw)}

    // Left edge
    if not w { draw.line((xl, yb + rsw), (xl, yt - rnw), ..style, fill: none, close: false)}

    // NW corner
    if not n and not w { bez((xl, yt - rnw), (xl + rnw, yt),  0,  1, -1,  0, rnw) }
  }
  draw.merge-path(..style, stroke: none, {
    // Top edge
    draw.line((xl + rnw, yt), (xr - rne, yt))

    // NE corner
    if not n and not e { bez((xr - rne, yt), (xr, yt - rne),  1,  0,  0,  1, rne)}
    // Right edge
    draw.line((xr, yt - rne), (xr, yb + rse))

    // SE corner
    if not s and not e { bez((xr, yb + rse), (xr - rse, yb),  0, -1,  1,  0, rse)}

    // Bottom edge
    draw.line((xr - rse, yb), (xl + rsw, yb))

    // SW corner
    if not s and not w { bez((xl + rsw, yb), (xl, yb + rsw), -1,  0,  0, -1, rsw)}

    // Left edge
    draw.line((xl, yb + rsw), (xl, yt - rnw))

    // NW corner
    if not n and not w { bez((xl, yt - rnw), (xl + rnw, yt),  0,  1, -1,  0, rnw)}
  })
}
