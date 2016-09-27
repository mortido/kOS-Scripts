function get_azimuth {
    parameter orbitincl.

    return 90.
}

function check_stage {
    parameter engs.

    for eng in engs {
        if eng:flameout and eng:thrust = 0
            {
                return true.
            }
    }.
    return false.
}

function get_throttle {
    parameter opt_twr.

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
    parameter displaynodes.
    
    // trajectory parameters
    local gt0 is 0.
    local gt1 is 0.
    local gt2 is 0.
    local pitch1 is 0.

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

    // events log
    local ramp to altitude + 25.
    when altitude > ramp then {
        printm("Liftoff.").
    }
    when altitude > gt0 then {
        printm("Beginning gravity turn."). 
    }
    when altitude > gt1 then {
        printm("Stop pitching.").
        //printm("Navigating surface prograde."). 
    }
    when altitude > gt2 then {
        printm("Navigating orbit prograde."). 
    }
    when altitude <= body:atm:height and apoapsis > orbitalt1 then {
        printm("Leaving atmosphere. Maintaining apoapsis altitude.").
    }

    clearscreen.
    print "Launch2Orbit start".
    print "[T-1]:  All systems GO. Ignition!". 
    wait 1.
    start_mission().
    stage.

    local tset is 1.
    local sset is up + R(0, 0, -180).
    lock throttle to tset. 
    lock steering to sset.
    list engines in engs.
    
    until altitude > body:atm:height and apoapsis > orbitalt1 {
        if check_stage(engs) {
            stage.
            print "Stage separeted.".
            list engines in engs.
            wait 1.
        }

        if altitude > gt0 and altitude < gt1 {
            local arr is (altitude - gt0) / (gt1 - gt0).
            local pda is (cos(arr * 180) + 1) / 2.
            local pitch is pitch1 * ( 1 - pda ).

            // 0 for NORTH.
            local pitchvector is heading(get_azimuth(orbitincl), 90-pitch).
            set sset to lookdirup(pitchvector:vector, ship:facing:topvector).
        } else if altitude > gt1 and altitude < gt2 {
            // lock steering to lookdirup(srfprograde:vector, ship:facing:topvector).
        } else if altitude > gt2 {
            // we can turn orbital prograde now
            set sset to lookdirup(prograde:vector, ship:facing:topvector).
        }

        if apoapsis < orbitalt1 {
            local ttemp is get_throttle(opt_twr).
            if apoapsis > 0.9995 * orbitalt1 {
                set ttemp to 0.01.
            } else if apoapsis > 0.995 * orbitalt1 {
                set ttemp to 0.05 * ttemp.
            }
            set tset to ttemp.
        } else {
            set tset to 0.
        }
        wait 0.1.
    }.
    set tset to 0.
    wait 1.
    unlock all.
    
    set nd to anode(apoapsis).
    if displaynodes { add nd. }
    execnode(nd).
    if displaynodes { remove nd. }
    printm(round(orbitalt1/1000) + "km - " + round(orbitalt2/1000) + " km orbit is reached!").
}

function launch2circle {
    parameter orbitalt.
    parameter orbitincl.
    
    launch2orbit(orbitalt, orbitalt, orbitincl, true).
}
