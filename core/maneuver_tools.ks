@lazyglobal off.

function finecircle {
    parameter accuracy is 400.

    printm("Fine circular orbit...").
    local lock semip to abs(eta:apoapsis - eta:periapsis).
    local lock dir to lookdirup(heading(90, -180 * (eta:apoapsis / semip)) :vector, ship:facing:topvector) .
    
    rotate2(dir).
    lock steering to dir.
    
    lock throttle to min(((ship:apoapsis-ship:periapsis)/50000), 0.05).
    wait until ship:periapsis > ship:apoapsis - accuracy.
    lock throttle to 0.
    unlock throttle.
    unlock steering.
    wait 1.
}

// Redefine this function to allow rcs rotation on some stages.
global use_rcs4rotation is { return false. }.

function rotate2 {
    // Rotetes ship to direction. Releases lock on stearing!!! lock must be reaquired after function call.
    parameter dir.
    parameter max_time is 60.
    parameter angle_precision is 0.15.
    
    lock steering to dir.
    local starttime is time:seconds.
    if use_rcs4rotation () { rcs on. }
    local lock dyaw to abs(dir:yaw - ship:facing:yaw).
    local lock dpitch to abs(dir:pitch - ship:facing:pitch).
    local lock droll to abs(dir:roll - ship:facing:roll).
    until dyaw < angle_precision and dpitch < angle_precision and droll < angle_precision{
        if time:seconds - starttime > max_time {
            print beep.
            hudtext("ERROR: can't rotate rocket to target in " + max_time + "seconds", 10, 2, 30, RED, true).
            return.
        }
    }
    if use_rcs4rotation () { rcs off. }
    unlock steering.
}

function nodedv {
    // Calculates dv for ap/pe nodes.
    // http://wiki.kerbalspaceprogram.com/wiki/Tutorial:_Basic_Orbiting_(Math)
    parameter r1.
    parameter r2.
    parameter r2_new.
    
    set r1 to r1 + body:radius.
    set r2 to r2 + body:radius.
    set r2_new to r2_new + body:radius.
    
    return sqrt(2 * body:mu / r1) * (sqrt(r2_new / (r1 + r2_new)) - sqrt(r2 / (r1 + r2))).
}

function anode {
    parameter altm.
    // create apoapsis maneuver node
    printm("Apoapsis maneuver, orbiting " + body:name).
    print "    Apoapsis: " + round(apoapsis/1000) + "km".
    print "    Periapsis: " + round(periapsis/1000) + "km -> " + round(altm/1000) + "km".
    
    // setup node 
    local dv is nodedv(apoapsis, periapsis, altm).
    printm("Apoapsis burn dv:" + round(dv) + "m/s").
    return node(time:seconds + eta:apoapsis, 0, 0, dv).
}

function pnode {
    parameter altm.
    // create apoapsis maneuver node
    print "Periapsis maneuver, orbiting " + body:name.
    print "    Apoapsis: " + round(apoapsis/1000) + "km -> " + round(altm/1000) + "km".
    print "    Periapsis: " + round(periapsis/1000) + "km".
    
    // setup node 
    local dv is nodedv(periapsis, apoapsis, altm).
    printm("Periapsis burn dv:" + round(dv) + "m/s").
    return node(time:seconds + eta:periapsis, 0, 0, dv).
}

global g0 is 9.82.
function get_burntime {
    parameter dv.

    local engs is list().
    list engines in engs.
    local thrustSum is 0.0.
    local denomSum is 0.0.
    
    // http://wiki.kerbalspaceprogram.com/wiki/Tutorial:Advanced_Rocket_Design
    for eng in engs {
        if eng:isp > 0 {
            local thrust is eng:maxthrust * (eng:thrustlimit / 100).
            set thrustSum to thrustSum + thrust.
            set denomSum to denomSum + (thrust / eng:isp).
        }
    }
    set dv to dv/2.
    // https://www.reddit.com/r/Kos/comments/3ftcwk/compute_burn_time_with_calculus/
    // https://www.reddit.com/r/Kos/comments/4568p2/executing_maneuver_nodes_figuring_out_the_rocket/
    local ispavg is thrustSum / denomSum.
    local ve is ispavg * g0.
    local m0 is ship:mass.
    local t is (m0 * g0 / denomSum) * (1 - constant:e^(-dv/ve)).
    
    local sss is nextnode:eta - t.
    local drag is 0.
    print "t " + t.
    until sss > nextnode:eta {
        local bpos is POSITIONAT(ship:body, sss) - POSITIONAT(ship, sss).
        local vel is VELOCITYAT(ship, sss):orbit - POSITIONAT(ship, sss).
        local altm is bpos:mag.
        set drag to drag + (body:mu/altm^2) * cos(vang(bpos, vel))* 0.01.
        //set drag to drag + ( body:mu/((altitude + body:radius)^2)) * 0.01.
        set sss to sss + 0.01.
    }
    print "drag " + drag.
    set dv to dv + drag.
    
    return 2*(m0 * g0 / denomSum) * (1 - constant:e^(-dv/ve)).
}

function execnode {
    parameter nd.
    parameter align_time is 60.

    printm("Executing node.").
    print "    Node in: " + round(nd:eta) + ", DeltaV: " + round(nd:deltav:mag).

    local burntime is get_burntime (nd:deltav:mag).
    print "    Estimated burn duration: " + round(burntime, 2) + " s".

    warpto(time:seconds + nd:eta - burntime / 2 - align_time).
    wait until warp = 0 and ship:unpacked.
    
    printm("Navigating node target.").
    rotate2(lookdirup(nd:deltav, ship:facing:topvector), align_time).
   
    // lets try to 'auto' correct if node direction is changed
    lock steering to lookdirup(nd:deltav, ship:facing:topvector).

    // Add 1 sec as fine tune will require ~2 sec instead of 1
    printm("Waiting to burn start.").
    wait until nd:eta <= (burntime / 2).

    // throttle is 100% until there is less than 1 second of time left to burn
    // when there is less than 1 second - decrease the throttle linearly
    local lock max_acc to ship:maxthrust / ship:mass.
    function get_throttle {
        if(max_acc < 0.001){ return 0. } // if stage was burnt out
        return min(max(nd:deltav:mag / max_acc, 0.005), 1).
    }
    lock throttle to get_throttle().

    // here's the tricky part, we need to cut the throttle
    // as soon as our nd:deltav and initial deltav start facing opposite directions (or close to it)
    // this check is done via checking the dot product of those 2 vectors
    local ndv0 is nd:deltav.
    until vdot(ndv0, nd:deltav) < 0.5 {
        check_stage().
    }
    
    lock throttle to 0.
    printm("End burn, remain dv " + round(nd:deltav:mag, 1) + "m/s, vdot: " + round(vdot(ndv0, nd:deltav), 1)).
    unlock steering.
    unlock throttle.
    wait 1.

    // set throttle to 0 just in case
    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
}

function execute_current_node {
    execnode(nextnode).
}