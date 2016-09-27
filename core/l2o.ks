parameter orbitalt.

list engines in engs.
function check_stage {
    local stageneeded is false.
    for eng in engs {
        if eng:flameout and eng:thrust = 0
            {
                set stageneeded to true.
            }
    }.
    
    if stageneeded {
        stage.
        print "Stage separeted.".
        list engines in ens.
        wait 1.
    }
}

if body:name = "Kerbin" {

    // trajectory parameters
    set gt0 to 1000.
    set gt1 to 30000.
    set gt2 to 40000.
    set pitch1 to 45.

    // velocity parameters
    set opt_twr to 1.8.
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

// adjust altitudes to start position
set launch_altitude to altitude.
set gt0 to gt0 + launch_altitude.
set gt1 to gt1 + launch_altitude.
set gt2 to gt2 + launch_altitude.

// events log
set ramp to altitude + 25.
when altitude > ramp then {
    printm("Liftoff.").
}
when altitude > gt0 then {
    printm("Beginning gravity turn."). 
}
//when altitude > gt1 then {
//    printm("Navigating surface prograde."). 
//}
when altitude > gt2 then {
    printm("Navigating orbit prograde."). 
}

when altitude <= body:atm:height and apoapsis > orbitalt then {
    printm("Leaving atmosphere. Maintaining apoapsis altitude.").
}


clearscreen.
print "Launch2Orbit start".
print "[T-1]:  All systems GO. Ignition!". 
wait 1.
start_mission().
stage.

set thrust to 1.
lock throttle to thrust. 
lock steering to up + R(0, 0, -180).

//until altitude > body:atm:height or apoapsis > orbitalt {
until altitude > body:atm:height and apoapsis > orbitalt {
    check_stage().

     if altitude > gt0 and altitude < gt1 {
        local arr is (altitude - gt0) / (gt1 - gt0).
        local pda is (cos(arr * 180) + 1) / 2.
        local pitch is pitch1 * ( 1 - pda ).
        
        // 0 for NORTH.
        local pitchvector is heading(90, 90-pitch).
        lock steering to lookdirup(pitchvector:vector, ship:facing:topvector).
    } else if altitude > gt1 and altitude < gt2 {
        //keep the ship's roll always top
        //lock steering to lookdirup(srfprograde:vector, ship:facing:topvector).
    } else if altitude > gt2 {
        //we can turn orbital prograde now
        lock steering to lookdirup(prograde:vector, ship:facing:topvector).
    }
    
    if apoapsis < orbitalt {
        local ttemp is get_throttle(opt_twr).
        if apoapsis > 0.9995 * orbitalt {
            set ttemp to 0.01.
        } else if apoapsis > 0.995 * orbitalt {
            set ttemp to 0.05 * ttemp.
        }
        set thrust to ttemp.
    } else {
        set thrust to 0.
    }
    wait 0.1.
}.
set thrust to 0.
wait 1.

unlock all.
set nd to anode(apoapsis).
add nd.
execnode(nd).
remove nd.

//lock throttle to 0.
//wait 1.
//stage.


//set antennas to ship:partsdubbed("Communotron 32").
//for antenna in antennas {
//    printm("Deploying antenna.").
//    antenna:getmodule("ModuleRTAntenna"):doevent("activate").
//}

unlock all.
printm(round(orbitalt/1000) + "km orbit is reached!").
