// arrange the display variables in the same way as the functional variables
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

// create the standard "label" based on the provided variables
#let create-label-equation(vars, funcname: $f$) = {
  math.equation(funcname + math.lr($($ + vars.join($,$) + $)$))
}
