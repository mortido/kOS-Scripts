// Calculates dv for ap/pe nodes.
// http://wiki.kerbalspaceprogram.com/wiki/Tutorial:_Basic_Orbiting_(Math)
parameter r1.
parameter r2.
parameter r2_new.

set dv to (sqrt(2 * body:mu) / r1) * (sqrt(r2_new / (r1 + r2_new)) - sqrt(r2 / (r1 + r2))).

return dv.
