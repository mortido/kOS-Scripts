function nodedv {
    // Calculates dv for ap/pe nodes.
    // http://wiki.kerbalspaceprogram.com/wiki/Tutorial:_Basic_Orbiting_(Math)
    parameter r1.
    parameter r2.
    parameter r2_new.
    
    return (sqrt(2 * body:mu) / r1) * (sqrt(r2_new / (r1 + r2_new)) - sqrt(r2 / (r1 + r2))).
}

function anode {
    parameter altm.
    // create apoapsis maneuver node
    printm("Apoapsis maneuver, orbiting " + body:name).
    printm("Apoapsis: " + round(apoapsis/1000) + "km").
    printm("Periapsis: " + round(periapsis/1000) + "km -> " + round(altm/1000) + "km").
    
    // setup node 
    local dv is nodedv(apoapsis, periapsis, altm).
    printm("Apoapsis burn dv:" + round(dv) + "m/s").
    return node(time:seconds + eta:apoapsis, 0, 0, dv).
}

function pnode {
    parameter altm.
    // create apoapsis maneuver node
    printm("Periapsis maneuver, orbiting " + body:name).
    printm("Apoapsis: " + round(apoapsis/1000) + "km -> " + round(altm/1000) + "km").
    printm("Periapsis: " + round(periapsis/1000) + "km").
    
    // setup node 
    local dv is nodedv(periapsis, apoapsis, altm).
    printm("Periapsis burn dv:" + round(dv) + "m/s").
    return node(time:seconds + eta:periapsis, 0, 0, dv).
}