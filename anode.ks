parameter altm.
// create apoapsis maneuver node
printm("Apoapsis maneuver, orbiting " + body:name).
printm("Apoapsis: " + round(apoapsis/1000) + "km").
printm("Periapsis: " + round(periapsis/1000) + "km -> " + round(altm/1000) + "km").

// present orbit properties
set vom to velocity:orbit:mag.  // actual velocity
set rb to body:radius.
set r to rb + altitude.         // actual distance to body
set ra to rb + apoapsis.        // radius in apoapsis
set va to sqrt( vom^2 + 2*body:mu*(1/ra - 1/r) ). // velocity in apoapsis
set a to (periapsis + 2*rb + apoapsis)/2. // semi major axis present orbit

// future orbit properties
set r2 to rb + apoapsis.    // distance after burn at apoapsis
set a2 to (altm + 2*rb + apoapsis)/2. // semi major axis target orbit
set v2 to sqrt( vom^2 + (body:mu * (2/r2 - 2/r + 1/a - 1/a2 ) ) ).

// setup node 
set deltav to v2 - va.
printm("Apoapsis burn: " + round(va) + ", dv:" + round(deltav) + " -> " + round(v2) + "m/s").
set nd to node(time:seconds + eta:apoapsis, 0, 0, deltav).
add nd.
printm("Node created.").