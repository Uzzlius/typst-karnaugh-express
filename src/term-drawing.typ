#import "@preview/cetz:0.5.3" : draw
#import "utils.typ": recolor-stroke

// ---------- geometry: returns the clockwise loop of one cell as data ----------
#let cell-segments(pos, neighbours, radius, pad) = {
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
  let seg-line(p, q, exposed) = (kind: "line", p: p, q: q, exposed: exposed)
  let seg-arc(p, q, d0, d1, r) = (
    kind: "arc", p: p, q: q, exposed: true,
    c1: (p.at(0) + d0.at(0) * m * r, p.at(1) + d0.at(1) * m * r),
    c2: (q.at(0) + d1.at(0) * m * r, q.at(1) + d1.at(1) * m * r),
  )

  let segs = ()
  // top
  segs.push(seg-line((xl + rnw + inw, yt), (xr - rne - ine, yt), not n))
  if rne > 0 { segs.push(seg-arc((xr - rne, yt), (xr, yt - rne), (1, 0), (0, 1), rne)) }
  if ine > 0 { segs.push(seg-arc((xr - ine, yt), (xr, yt - ine), (0, -1), (-1, 0), ine)) }
  // right
  segs.push(seg-line((xr, yt - rne - ine), (xr, yb + rse + ise), not e))
  if rse > 0 { segs.push(seg-arc((xr, yb + rse), (xr - rse, yb), (0, -1), (1, 0), rse)) }
  if ise > 0 { segs.push(seg-arc((xr, yb + ise), (xr - ise, yb), (-1, 0), (0, 1), ise)) }
  // bottom
  segs.push(seg-line((xr - rse - ise, yb), (xl + rsw + isw, yb), not s))
  if rsw > 0 { segs.push(seg-arc((xl + rsw, yb), (xl, yb + rsw), (-1, 0), (0, -1), rsw)) }
  if isw > 0 { segs.push(seg-arc((xl + isw, yb), (xl, yb + isw), (0, 1), (1, 0), isw)) }
  // left
  segs.push(seg-line((xl, yb + rsw + isw), (xl, yt - rnw - inw), not w))
  if rnw > 0 { segs.push(seg-arc((xl, yt - rnw), (xl + rnw, yt), (0, 1), (-1, 0), rnw)) }
  if inw > 0 { segs.push(seg-arc((xl, yt - inw), (xl + inw, yt), (1, 0), (0, -1), inw)) }
  segs
}

#let draw-seg(s) = {
  import draw: *
  if s.kind == "line" { line(s.p, s.q) } else { bezier(s.p, s.q, s.c1, s.c2) }
}

// ---------- fill: one merged closed shape per cell, no stroke ----------
#let draw-cell-fill(segs, ..style) = {
  import draw: *
  merge-path(..style, stroke: none, { for s in segs { draw-seg(s) } })
}

// ---------- chaining of exposed segments ----------
#let pt-key(p) = (
  str(int(calc.round(p.at(0) * 1000))) + "," + str(int(calc.round(p.at(1) * 1000)))
)

#let chain-segments(segs) = {
  let by-start = (:)
  let ends = (:)
  for (i, s) in segs.enumerate() {
    by-start.insert(pt-key(s.p), i)
    ends.insert(pt-key(s.q), true)
  }
  let used = segs.map(_ => false)
  // walk open chains from their true start first
  let order = range(segs.len()).sorted(key: i => if pt-key(segs.at(i).p) in ends { 1 } else { 0 })
  let chains = ()
  for i0 in order {
    if used.at(i0) { continue }
    let chain = ()
    let i = i0
    while i != none and not used.at(i) {
      used.at(i) = true
      chain.push(segs.at(i))
      i = by-start.at(pt-key(segs.at(i).q), default: none)
    }
    chains.push(chain)
  }
  chains
}

#let draw-term-outline(segs, ..style) = {
  import draw: *
  for chain in chain-segments(segs.filter(s => s.exposed)) {
    let closed = pt-key(chain.first().p) == pt-key(chain.last().q)
    merge-path(..style, fill: none, close: closed, {
      for s in chain { draw-seg(s) }
    })
  }
}

// Draws all the term bundles provided in the term-coordinate-list
#let draw-multiple-bundle-cells(term-coordinates-list, highlight-colors, highlight-inset, highlight-steps, highlight-stroke, columns, rows, highlight-radius, highlight-transparency, step-distance) = {
  for (term-number, term-coordinates) in term-coordinates-list.enumerate() {
    // Iterate through the coloros. Wrap around
    let color = highlight-colors.at(calc.rem(term-number, highlight-colors.len()))

    // Calculate the inset of a given term, so the distance
    // from the grid line to the bundle outline
    let gap = highlight-inset + calc.rem(term-number, highlight-steps) * step-distance

    let term-segs = ()
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
      // at the given direction, so (north, east, south, west, north-east, north-west, south-east, south-west)
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

      let segs = cell-segments(coordinate-center, neighbours, highlight-radius, gap)
      term-segs += segs
      draw-cell-fill(segs, fill: color.transparentize(highlight-transparency))
    }

    draw-term-outline(
      term-segs,
      stroke: recolor-stroke(highlight-stroke, color),
    )
  }
}
