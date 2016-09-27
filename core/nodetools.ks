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

set g0 to 9.82.
function burn_duration {
    parameter dv.

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
    //return (m0 * ve / thrustSum) * (1 - constant:e^(-dv/ve)).
    return (m0 * g0 / denomSum) * (1 - constant:e^(-dv/ve))+1.
}

function execnode {
    parameter nd.

    printm("Executing node.").
    print "    Node in: " + round(nd:eta) + ", DeltaV: " + round(nd:deltav:mag).

    local startvel is ship:velocity:orbit.
    local oldtime is time:seconds.
    
    local dvapplied is 0.
    local gravdv is V(0,0,0).
    local lock dv to ship:velocity:orbit - startvel - gravdv.
    local lock heregrav to body:mu/((altitude + body:radius)^2).
    local ndv0 is nd:deltav.
    //local lock ndv to ndv0 - dv. // TODO: add ability to use without setting the node
    local lock ndv to nd:deltav.
    
    local burn is burn_duration (ndv0:mag).
    print "    Estimated burn duration: " + round(burn) + "s".

    local offset is 60.
    warp2rails(nd:eta - burn / 2 - offset).
    
    printm("Navigating node target.").

    // lets try to 'auto' correct if node direction is changed
    lock steering to lookdirup(ndv, ship:facing:topvector).
    // lets not.... TODO: ndv affected by changing in orbital speed.
    //lock steering to lookdirup(ndv0, ship:facing:topvector).

    // now we need to wait until the burn vector and ship's facing are aligned
    // TODO: check that we can rotate!
    local ndd0 is ndv0:direction.
    wait until abs(ndd0:pitch - facing:pitch) < 0.15 and abs(ndd0:yaw - facing:yaw) < 0.15.
    
    //the ship is facing the right direction, let's wait for our burn time
    wait until nd:eta <= (burn / 2).

    printm("Burn!.").
    
    local tset is 0.
    lock throttle to tset.

    until false {
        local newtime is time:seconds.
        local dtime is newtime - oldtime.
        set oldtime to newtime.

        // apply gravity to start velocity to exclude it from applied deltav calculation
        // TODO: down vector!
        // set gravdv to gravdv + heregrav * dtime * down_vector

        // recalculate current max_acceleration, as it changes while we burn through fuel
        local max_acc is ship:maxthrust / ship:mass.
        
        // throttle is 100% until there is less than 1 second of time left to burn
        // when there is less than 1 second - decrease the throttle linearly
        set tset to min(ndv:mag/max_acc, 1).
        
        // here's the tricky part, we need to cut the throttle
        // as soon as our nd:deltav and initial deltav start facing opposite directions
        // this check is done via checking the dot product of those 2 vectors
        if vdot(ndv0, ndv) < 0
        {
            printm("Overburn.").
            printm("End burn, remain dv " + round(ndv:mag,1) + "m/s, vdot: " + round(vdot(ndv0, ndv), 1)).
            lock throttle to 0.
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
            break.
        }

        wait 0.01.
    }
    
    unlock steering.
    unlock throttle.
    wait 1.

    //set throttle to 0 just in case.
    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
}