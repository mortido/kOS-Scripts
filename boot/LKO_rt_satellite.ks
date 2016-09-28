// loading.
print "LOADING...".
wait 10.
clearscreen.

if true or not exists("1:/mt.ksm") {
    copypath("0:/spec_char.ksm", "").
    compile "0:/core/logging.ks" to "1:/logging.ksm".
    compile "0:/core/warp_tools.ks" to "1:/warp_tools.ksm".
    compile "0:/core/maneuver_tools.ks" to "1:/maneuver_tools.ksm".
    compile "0:/core/orbit_ttols.ks" to "1:/orbit_ttols.ksm".
    //copypath("0:/core", "").
}

run spec_char.
//cd("1:/core").
run logging.
run warp_tools.
run maneuver_tools.
run orbit_ttols.

print "You can set lko_launch_altitude variable. Default is 100km".
global lko_launch_altitude is 100000.

//cd("1:/core").
//run l2o.

function launch_me {
    parameter al, inc.
    print "Launch RT satellite to " + al + " km with inclination " + inc + " deg.".
    wait 3.
    launch2circle(al, inc).
    
    // TODO:
    //finecircle().
    
    // Deploy solar panels and antennas.
    panels on.
    set antennas to ship:partsdubbed("Communotron 32").
    for antenna in antennas {
        print "Activating Communotron 32...".
        antenna:getmodule("ModuleRTAntenna"):doevent("activate").
    }
    
    // deploy satellite.
    stage.
    wait 1.
    
    // rcs to start deorbit.
    lock steering to prograde.
    rcs on.
    set ship:control:fore to -1
    wait 3.
    set ship:control:fore to 0.
    rcs off.
    wait 1.
    unlock steering.

    deorbit().
}

on ag1 {
    launch2circle(lko_launch_altitude, 0.0).
}

launch2circle(lko_launch_altitude, 0.0).

// TODO:
// found burn time.
// fine circle.
// inclanation.
// inclanation with correct ascent node.
// add more predefined orbits.

