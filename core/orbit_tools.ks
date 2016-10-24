@lazyglobal off.

function get_azimuth {
    parameter orbitincl.

    return 90.
}

function get_throttle {
    parameter opt_twr.

    // TODO: depend on atmosphere and gravitation (+pitch).
    if maxthrust > 0 {
        local heregrav is body:mu/((altitude + body:radius)^2).
        local maxtwr is ship:maxthrust / (heregrav * ship:mass).
        return min(opt_twr / maxtwr, 1).
    } else {
        return 0.
    }
}

function launch2orbit{
    parameter orbitalt1.
    parameter orbitalt2.
    parameter orbitincl.

    // trajectory parameters
    local ramp is altitude + 25.
    local pitch1 is 0.
    local gt0 is 0.
    local gt1 is 0.
    local gt2 is 0.

    // velocity parameters
    local opt_twr is 0.

    if body:name = "Kerbin" {
        set gt0 to 1000.
        set gt1 to 30000.
        set gt2 to 40000.
        set pitch1 to 45.
        set opt_twr to 1.8.
    }

    // adjust altitudes to start position
    local launch_altitude is altitude.
    set gt0 to gt0 + launch_altitude.
    set gt1 to gt1 + launch_altitude.
    set gt2 to gt2 + launch_altitude.

    print "[T-1]:  All systems GO. Ignition!". 
    wait 1.
    start_mission().
    stage.

    lock steering to up + R(0, 0, -180).
    update_engines().

    local calc_t is {
        if apoapsis >= orbitalt1 {
            return 0.
        }
        if apoapsis > 0.9995 * orbitalt1 {
                return 0.01 * get_throttle(opt_twr).
        } else if apoapsis > 0.995 * orbitalt1 {
                return 0.05 * get_throttle(opt_twr).
        }
        return get_throttle(opt_twr).
    }.
    
    lock throttle to calc_t().
    
    until altitude >= ramp { check_stage(). }
    printm("Liftoff!"). 
    
    until altitude >= gt0 { check_stage(). }
    printm("Beginning gravity turn."). 
    local lock arr to (altitude - gt0) / (gt1 - gt0).
    local lock pda to (cos(arr * 180) + 1) / 2.
    local lock pt to pitch1 * ( 1 - pda ).
    local lock pitchvector to heading(get_azimuth(orbitincl), 90-pt).
    lock steering to lookdirup(pitchvector:vector, ship:facing:topvector).
    
    until altitude >= gt1 { check_stage(). }
    printm("Stop pitching."). 
    local sset is lookdirup(pitchvector:vector, ship:facing:topvector).
    lock steering to sset.
    
    until altitude >= gt2 { check_stage(). }
    printm("Navigating orbit prograde."). 
    lock steering to lookdirup(prograde:vector, ship:facing:topvector).
    
    if altitude < body:atm:height {
        until altitude > body:atm:height { check_stage(). }
        printm("Leaving atmosphere.").
    }

    until apoapsis > orbitalt1 { check_stage(). }

    lock throttle to 0.
    wait 1.
    unlock throttle. 
    unlock steering.
    
    local nd is anode(apoapsis).
    add nd.
    execute_current_node().
    remove nd.
    printm(round(apoapsis/1000, 2) + "km - " + round(periapsis/1000, 2) + " km orbit is reached!").
}

function deorbit {
    
    printm("Deorbiting...").
    rotate2(lookdirup(retrograde:vector, ship:facing:topvector)).

    // burn retrograde until done
    lock throttle to 1.
    until periapsis < 0 or ship:liquidfuel = 0 and ship:solidfuel = 0 {
        check_stage().
    }
    
    unlock throttle.
    unlock steering.
}
