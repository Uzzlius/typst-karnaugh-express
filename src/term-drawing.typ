#import "@preview/cetz:0.5.3"
#import cetz : draw
#import "utils.typ": recolor-stroke

#let fast-outline(term-coordinates) = ((ctx) => {
  let body = curve(
    fill: red,
    ..for (y, x) in term-coordinates {
      (
        curve.move(((x - 0.5) * ctx.length, (y - 0.5) * ctx.length)),
        curve.line(((x + 0.5) * ctx.length, (y - 0.5) * ctx.length)),
        curve.line(((x + 0.5) * ctx.length, (y + 0.5) * ctx.length)),
        curve.line(((x - 0.5) * ctx.length, (y + 0.5) * ctx.length)),
      )
    }
  )

  let (width: w, height: h) = measure(body)
  let (w, h) = (w / ctx.length, h / ctx.length)
  let pos = (0, 3)
  let p = cetz.util.apply-transform(ctx.transform, pos)

  p = (p.at(0) + w/2, p.at(1) - h/2, 0)

  (
    ctx: ctx,
    drawables: ((
      type: "content", pos: p,
      width: w, height: h,
      segments: (), body: body, tags: (),
    ),),
  )
},)

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
    }
    fast-outline(term-coordinates)
  }
}
