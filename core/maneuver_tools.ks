@lazyglobal off.

function finecircle {
    parameter accuracy is 100,
              extra_offset is 0.

    printm("Fine circular orbit...").
    local lock semip to abs(eta:apoapsis - eta:periapsis).
    lock steering to heading(90, -180 * (eta:apoapsis / semip)) + R(0,0,0).
    
    // TODO: wait for rotation.
    
    lock max_acc to ship:maxthrust / ship:mass.
    // TODO: calculate dv.
    // min(dv/max_acc, 1).
    lock throttle to min(((ship:apoapsis-(ship:periapsis-accuracy))/20000),1).
    
    wait until ship:periapsis > ship:apoapsis - accuracy.
    lock throttle to 0.
    unlock throttle.
    unlock steering.
    wait 1.
    printm("Done!").
}

function rotate2 {
    parameter dir.
    parameter max_time is 60.
    
    lock steering to lookdirup(dir:vector, ship:facing:topvector).
    local lock dpitch to abs(dir:pitch - facing:pitch).
    local lock dyaw to abs(dir:yaw - facing:yaw).
    local starttime is time:seconds.
    until dpitch < 0.15 and dyaw < 0.15 {
        if time:seconds - starttime > max_time {
            print beep.
            hudtext("ERROR: can't rotate rocket to target in " + max_time + "seconds", 10, 2, 30, RED, true).
            return.
        }
        wait 0.1.
    }
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
    
    // https://www.reddit.com/r/Kos/comments/3ftcwk/compute_burn_time_with_calculus/
    local ispavg is thrustSum / denomSum.
    local ve is ispavg * g0.
    local m0 is ship:mass.
    //return (m0 * g0 / denomSum) * (1 - constant:e^(-dv/ve))/2.
    return (0.5 * m0 * g0 / denomSum) * (1.5 - 0.5*constant:e^(-dv/ve) - constant:e^(-0.5 * dv/ve))+0.25.
    //local t is (m0 * g0 / denomSum) * (1 - constant:e^(-dv/ve)).
    //local accm is dv / t.
    //return (dv/2)/accm.
}

function execnode {
    parameter nd.

    printm("Executing node.").
    print "    Node in: " + round(nd:eta) + ", DeltaV: " + round(nd:deltav:mag).

    local ndv0 is nd:deltav.
    local burn is get_burntime (ndv0:mag).
    print "    Estimated burn duration: " + round(burn) + "s".

    local offset is 60.
    //warpto(time:seconds + nd:eta - burn / 2 - offset).
    warpto(time:seconds + nd:eta - burn - offset).
    wait until warp = 0 and ship:unpacked.
    
    printm("Navigating node target.").
    rotate2(ndv0:direction, offset).

    // Add 1 sec as fine tune will require ~2 sec instead of 1
    printm("Waiting to burn start.").
    //wait until nd:eta <= (burn / 2 + 0.5).
    wait until nd:eta <= burn.

    printm("Burn - " + round(burn,2) + " s").
    local oldtime is time:seconds.
    local startvel is ship:velocity:orbit.
    local lock max_acc to ship:maxthrust / ship:mass.
    local lock heregrav to body:mu/((altitude + body:radius)^2).
    local gravdv is V(0,0,0).
    local lock dv to ship:velocity:orbit - startvel - gravdv.

    // local lock ndv to ndv0 - dv.
    local lock ndv to nd:deltav.
    
    // throttle is 100% until there is less than 1 second of time left to burn
    // when there is less than 1 second - decrease the throttle linearly
    lock throttle to min(max(ndv:mag/max_acc, 0.005), 1).

    // lets try to 'auto' correct if node direction is changed
    lock steering to lookdirup(ndv, ship:facing:topvector).

    global lock ddvv to ndv:mag.
    global aacc is max_acc.
    
    when ddvv <= max_acc then {
        printm("-----------FINE!").
        global ttt is time:seconds.
    }
    until false {
    
        // apply gravity to start velocity to exclude it from applied deltav calculation
        local newtime is time:seconds.
        local dtime is newtime - oldtime.
        set oldtime to newtime.
        set gravdv to gravdv + heregrav * dtime * body:position:normalized.

        // here's the tricky part, we need to cut the throttle
        // as soon as our nd:deltav and initial deltav start facing opposite directions
        // this check is done via checking the dot product of those 2 vectors
        if vdot(ndv0, ndv) < 0
        {
            print "    Overburn.".
            lock throttle to 0.
            printm("End burn, remain dv " + round(ndv:mag,1) + "m/s, vdot: " + round(vdot(ndv0, ndv), 1)).
            break.
        }
    
        // we have very little left to burn, less then 0.1m/s
        if ndv:mag < 0.1
        {
            printm("Finalizing burn, remain dv " + round(ndv:mag,1) + "m/s, vdot: " + round(vdot(ndv0, ndv), 1)).
            // we burn slowly until our node vector starts to drift significantly from initial vector
            // this usually means we are on point
            wait until vdot(ndv0, ndv) < 0.5.

            lock throttle to 0.
            printm("End burn, remain dv " + round(ndv:mag,1) + "m/s, vdot: " + round(vdot(ndv0, ndv), 1)).
            print "----------TIME!!!!!!! " + (time:seconds - ttt).
            break.
        }

        wait 0.01.
    }
    
    unlock steering.
    unlock throttle.
    wait 1.

    // set throttle to 0 just in case
    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
}