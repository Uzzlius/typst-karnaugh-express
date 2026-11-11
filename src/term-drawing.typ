#import "@preview/cetz:0.5.3" : draw

// Draw one cell's contribution to a group outline.
// neighbours: (north, east, south, west) — true if that neighbour is in the same group.
// pad: gap between the outline and the grid edge (only on exposed sides).
#let draw-bundle-cell(pos, neighbours, radius: 0.15, pad: 0.1, ..style) = {
  import draw: *

  let (cx, cy) = pos
  let h = 0.5
  let (n, e, s, w, ne, nw, se, sw) = neighbours

  // Inset exposed sides by pad; flush with grid on shared sides
  let xl = cx - h + (if w { 0 } else { pad })
  let xr = cx + h - (if e { 0 } else { pad })
  let yt = cy + h - (if n { 0 } else { pad })
  let yb = cy - h + (if s { 0 } else { pad })

  // Round a corner only when both adjacent sides are exposed (convex corner)
  let rnw = if not n and not w { radius } else { 0 }
  let rne = if not n and not e { radius } else { 0 }
  let rse = if not s and not e { radius } else { 0 }
  let rsw = if not s and not w { radius } else { 0 }

  // Round an inner corner only when both adjacent neighbours are covered and
  // the diagonal neighbours are not (concave corner)
  let inw = if n and w and not nw { pad } else { 0 }
  let ine = if n and e and not ne { pad } else { 0 }
  let ise = if s and e and not se { pad } else { 0 }
  let isw = if s and w and not sw { pad } else { 0 }

  let m = 0.551784  // bezier circle approximation constant
  let bez(p, q, d0x, d0y, d1x, d1y, r) = bezier(
    p, q,
    (p.at(0) + d0x * m * r, p.at(1) + d0y * m * r),
    (q.at(0) + d1x * m * r, q.at(1) + d1y * m * r),
    ..style, fill: none, close: false
  )

  // Trace clockwise. Draw exposed segments; move-to over internal ones.
  {
    // Top edge
    if not n { line((xl + rnw, yt), (xr - rne, yt), ..style, fill: none, close: false)}

    // NE corner
    if not n and not e { bez((xr - rne, yt), (xr, yt - rne),  1,  0,  0,  1, rne)}
    // NE inner corner
    if ine > 0 { bez((xr - ine, yt), (xr, yt - ine),  0, -1, -1,  0, ine)}

    // Right edge
    if not e { line((xr, yt - rne), (xr, yb + rse), ..style, fill: none, close: false)}

    // SE corner
    if not s and not e { bez((xr, yb + rse), (xr - rse, yb),  0, -1,  1,  0, rse)}
    // SE inner corner
    if ise > 0 { bez((xr, yb + ise), (xr - ise, yb), -1,  0,  0,  1, ise)}

    // Bottom edge
    if not s { line((xr - rse, yb), (xl + rsw, yb), ..style, fill: none, close: false)}

    // SW corner
    if not s and not w { bez((xl + rsw, yb), (xl, yb + rsw), -1,  0,  0, -1, rsw)}
    // SW inner corner
    if isw > 0 { bez((xl + isw, yb), (xl, yb + isw),  0,  1,  1,  0, isw)}

    // Left edge
    if not w { line((xl, yb + rsw), (xl, yt - rnw), ..style, fill: none, close: false)}

    // NW corner
    if not n and not w { bez((xl, yt - rnw), (xl + rnw, yt),  0,  1, -1,  0, rnw) }
    // NW inner corner
    if inw > 0 { bez((xl, yt - inw), (xl + inw, yt),  1,  0,  0, -1, inw)}
  }

  merge-path(..style, stroke: none, {
    // Top edge
    line((xl + rnw + inw, yt), (xr - rne - ine, yt))

    // NE corner
    if not n and not e { bez((xr - rne, yt), (xr, yt - rne),  1,  0,  0,  1, rne)}
    if ine > 0 { bez((xr - ine, yt), (xr, yt - ine),  0, -1, -1,  0, ine)}

    // Right edge
    line((xr, yt - rne - ine), (xr, yb + rse + ise))

    // SE corner
    if not s and not e { bez((xr, yb + rse), (xr - rse, yb),  0, -1,  1,  0, rse)}
    if ise > 0 { bez((xr, yb + ise), (xr - ise, yb), -1,  0,  0,  1, ise)}

    // Bottom edge
    line((xr - rse - ise, yb), (xl + rsw + isw, yb))

    // SW corner
    if not s and not w { bez((xl + rsw, yb), (xl, yb + rsw), -1,  0,  0, -1, rsw)}
    if isw > 0 { bez((xl + isw, yb), (xl, yb + isw),  0,  1,  1,  0, isw)}

    // Left edge
    line((xl, yb + rsw + isw), (xl, yt - rnw - inw))

    // NW corner
    if not n and not w { bez((xl, yt - rnw), (xl + rnw, yt),  0,  1, -1,  0, rnw)}
    if inw > 0 { bez((xl, yt - inw), (xl + inw, yt),  1,  0,  0, -1, inw)}
  })
}

// Draws all the term bundles provided in the term-coordinate-list
#let draw-multiple-bundle-cells(term-coordinates-list, highlight-colors, highlight-inset, highlight-steps, highlight-stroke, columns, rows, highlight-radius, highlight-transparency) = {
  for (term-number, term-coordinates) in term-coordinates-list.enumerate() {
    // Iterate through the coloros. Wrap around
    let color = highlight-colors.at(calc.rem(term-number, highlight-colors.len()))

    // Calculate the inset of a given term, so the distance
    // from the grid line to the bundle outline
    let gap = highlight-inset + calc.rem(term-number, highlight-steps)

    for single-coordinate in term-coordinates {
      let row = single-coordinate.at(0)
      let column = single-coordinate.at(1)

      let coordinate-center = (column, rows - row - 1)

      // Calculate with wrap around
      let up    = calc.rem-euclid(row - 1, rows)
      let down  = calc.rem-euclid(row + 1, rows)
      let left  = calc.rem-euclid(column - 1, columns)
      let right = calc.rem-euclid(column + 1, columns)

      // Creates a list that represents, wether the bundle has a neighbour
      // at the given direction, so (north, east, south, west)
      let neighbours = (
        (up,   column) in term-coordinates,   // north
        (row,  right)  in term-coordinates,   // east
        (down, column) in term-coordinates,   // south
        (row,  left)   in term-coordinates,   // west

        (up,   right)  in term-coordinates,   // north-east
        (up,   left)   in term-coordinates,   // north-west
        (down, right)  in term-coordinates,   // south-east
        (down, left)   in term-coordinates,   // south-west
      )

      // Actually draw the cell bundle
      draw-bundle-cell(
        coordinate-center,
        neighbours,
        radius: highlight-radius,
        pad: gap,
        fill: color.transparentize(highlight-transparency),
        stroke: color + highlight-stroke)
    }
  }
}
