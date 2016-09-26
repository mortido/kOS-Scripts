function execnode {
    parameter nd.
    parameter accuracy.

    printm("Node in: " + round(nd:eta) + ", DeltaV: " + round(nd:deltav:mag)).

    local startvel is ship:velocity:orbit.
    local oldtime is time:seconds.
    
    local dvapplied is 0.
    local gravdv is V(0,0,0).
    local lock dv to ship:velocity:orbit - startvel - gravdv.
    local lock heregrav to body:mu/((altitude + body:radius)^2).
    local lock ndv to nd:deltav - dv.
    local ndv0 is nd:deltav.
    
    // lets try to 'auto' correct if node direction is changed
    //lock steering to lookdirup(ndv, ship:facing:topvector).
    
    // lets not....
    lock steering to lookdirup(ndv0, ship:facing:topvector).
    
    // now we need to wait until the burn vector and ship's facing are aligned
    wait until abs(ndv0:pitch - facing:pitch) < 0.15 and abs(ndv0:yaw - facing:yaw) < 0.15.
    
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













//calculate ship's max acceleration
set max_acc to ship:maxthrust/ship:mass.

set burn_duration to nd:deltav:mag/max_acc.
print "Crude Estimated burn duration: " + round(burn_duration) + "s".

// TODO: warp to
wait until node:eta <= (burn_duration/2 + 60).

// rotate.


//the ship is facing the right direction, let's wait for our burn time
wait until node:eta <= (burn_duration/2)








