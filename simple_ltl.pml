byte x = 1
active proctype t0() {
  x++
}

active proctype t1() {
  x--
}
ltl { [] (x == 1) }
ltl { <> (x == 1) }
ltl { [] <> (x == 1) }
ltl { <> [] (x == 1) }