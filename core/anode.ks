parameter altm.
// create apoapsis maneuver node
printm("Apoapsis maneuver, orbiting " + body:name).
printm("Apoapsis: " + round(apoapsis/1000) + "km").
printm("Periapsis: " + round(periapsis/1000) + "km -> " + round(altm/1000) + "km").

// setup node 
set dv to run nodedv(apoapsis, periapsis, altm).
printm("Apoapsis burn dv:" + round(dv) + "m/s").
set nd to node(time:seconds + eta:apoapsis, 0, 0, dv).

return nd.
