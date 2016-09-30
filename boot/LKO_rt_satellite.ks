core:part:getmodule("kOSProcessor"):doevent("Open Terminal").

clearscreen.
print "                    LOADING" at (0, 10).
wait 1. print "." at (27, 10).
wait 1. print "." at (28, 10).
wait 1. print "." at (29, 10).

if not addons:rt:available or addons:rt:hasconnection(ship) {
    copypath("0:/spec_char.ksm", "").
    compile "0:/core/logging.ks" to "1:/logging.ksm".
    compile "0:/core/miscellaneous.ks" to "1:/miscellaneous.ksm".
    compile "0:/core/warp_tools.ks" to "1:/warp_tools.ksm".
    compile "0:/core/maneuver_tools.ks" to "1:/maneuver_tools.ksm".
    compile "0:/core/orbit_tools.ks" to "1:/orbit_tools.ksm".
}

run spec_char.
run logging.
run miscellaneous.
run warp_tools.
run maneuver_tools.
run orbit_tools.

global parameters is lexicon().
global ready2launch is false.
parameters:add("orbit_altitude", 100000).
parameters:add("orbit_inclination", 0.0).
writejson(parameters, "parameters.json").

function draw_menu {
    set parameters to readjson("parameters.json").

    clearscreen.
    print "           MENU".
    print "=============================".
    print "1 - launch the rocket".
    print "2 - edit launch parameters".
    print "=============================".
    print "CURENT PARAMS:".
    print "Orbit altitude: " + round(parameters["orbit_altitude"], 2) + " km".
    print "Orbit inclination: " + round(parameters["orbit_inclination"], 2) + " deg".
}

function launch_me {
    parameter al, inc.

    clearscreen.
    print "Launch RT satellite to " + al + " km with inclination " + inc + " deg.".
    print "".
    wait 3.
    
    when altitude > body:atm:height then {
        printm("Leaved atmosphere. Droping protection shell.").
        set firings to ship:modulesnamed("ModuleProceduralFairing").
        for firing in firings {
            firing:doevent("Deploy").
        }
    }
    
    launch2circle(al, inc).
    finecircle().
    
    // Deploy solar panels and antennas.
    panels on.
    set antennas to ship:partsdubbed("Communotron 32").
    for antenna in antennas {
        print "    Activating Communotron 32...".
        antenna:getmodule("ModuleRTAntenna"):doevent("activate").
    }
    
    wait 30.

    // deploy satellite.
    core:part:getmodule("ModuleDecouple"):doevent("Decouple").
    wait 1.
    
    // rcs to start deorbit.
    lock steering to prograde.
    wait 1.
    rcs on.
    set ship:control:fore to -1.
    wait 5.
    set ship:control:fore to 0.
    rcs off.
    wait 1.
    unlock steering.

    deorbit().
    printm("Mission completed! Bye!").
}

on ag1 {
    set parameters to readjson("parameters.json").
    set ready2launch to true.
}

on ag2 {
    edit "parameters.json".
    preserve.
}

draw_menu().

wait until ready2launch.
launch_me(parameters["orbit_altitude"], parameters["orbit_inclination"]).

// TODO:
// found burn time.
// exec without add.
// fine circle.
// inclanation.
// inclanation with correct ascent node.

