parameter altm.
// create apoapsis maneuver node
printm("Periapsis maneuver, orbiting " + body:name).
printm("Apoapsis: " + round(apoapsis/1000) + "km -> " + round(altm/1000) + "km").
printm("Periapsis: " + round(periapsis/1000) + "km").

// setup node 
set dv to run nodedv(periapsis, apoapsis, altm).
printm("Periapsis burn dv:" + round(dv) + "m/s").
set nd to node(time:seconds + eta:periapsis, 0, 0, dv).

return nd.
