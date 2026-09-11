module RaiseNbr {
  // Define the 4-neighbors of a cell (up, down, left, right)
  function Nbr4(r: int, c: int): (int, int)[]
  {
    [ (r-1, c), (r+1, c), (r, c-1), (r, c+1) ]
  }

  // Define the RaiseNbr operation
  function RaiseNbr(h: real[][], p: (int, int), processed: set<(int, int)>): real[][]
  requires h != null
  requires 0 <= p.0 < h.Length && 0 <= p.1 < h[p.0].Length
  requires forall r, c :: (r, c) in processed ==> 0 <= r < h.Length && 0 <= c < h[r].Length
  ensures forall r, c :: 0 <= r < h.Length && 0 <= c < h[r].Length ==>
            (r, c) in processed ==>
            RaiseNbr(h, p, processed)[r][c] == h[r][c]
  ensures forall r, c :: 0 <= r < h.Length && 0 <= c < h[r].Length ==>
            (r, c) not in processed ==>
            RaiseNbr(h, p, processed)[r][c] >= h[r][c]
  ensures forall r, c :: 0 <= r < h.Length && 0 <= c < h[r].Length ==>
            (r, c) in Nbr4(p.0, p.1) && (r, c) not in processed ==>
            RaiseNbr(h, p, processed)[r][c] >= max(h[r][c], h[p.0][p.1])
  {
    var h' := h;
    var nbrs := Nbr4(p.0, p.1);
    foreach n in nbrs
    {
      var r, c := n;
      if r >= 0 && r < h.Length && c >= 0 && c < h[r].Length && (r, c) not in processed
      {
        h'[r][c] := max(h[r][c], h[p.0][p.1]);
      }
    }
    return h';
  }

  // Lemma to prove the properties of RaiseNbr
  lemma RaiseNbrProperties(h: real[][], p: (int, int), processed: set<(int, int)>)
    requires h != null
    requires 0 <= p.0 < h.Length && 0 <= p.1 < h[p.0].Length
    requires forall r, c :: (r, c) in processed ==> 0 <= r < h.Length && 0 <= c < h[r].Length
    ensures forall r, c :: 0 <= r < h.Length && 0 <= c < h[r].Length ==>
            (r, c) in processed ==>
            RaiseNbr(h, p, processed)[r][c] == h[r][c]
    ensures forall r, c :: 0 <= r < h.Length && 0 <= c < h[r].Length ==>
            (r, c) not in processed ==>
            RaiseNbr(h, p, processed)[r][c] >= h[r][c]
    ensures forall r, c :: 0 <= r < h.Length && 0 <= c < h[r].Length ==>
            (r, c) in Nbr4(p.0, p.1) && (r, c) not in processed ==>
            RaiseNbr(h, p, processed)[r][c] >= max(h[r][c], h[p.0][p.1])
  {
    var h' := RaiseNbr(h, p, processed);
    var nbrs := Nbr4(p.0, p.1);
    foreach n in nbrs
    {
      var r, c := n;
      if r >= 0 && r < h.Length && c >= 0 && c < h[r].Length && (r, c) not in processed
      {
        assert h'[r][c] == max(h[r][c], h[p.0][p.1]);
      }
    }
  }
}
