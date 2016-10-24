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

global ready2launch is false.

global menu_mode is "waiting".
global exit is false.

global parameters is lexicon().
if not exists("parameters.json") {
    parameters:add("orbit_altitude", 100000).
    parameters:add("orbit_inclination", 0.0).
    writejson(parameters, "parameters.json").
}

function draw_menu {
    set parameters to readjson("parameters.json").

    clearscreen.
    print "           MENU".
    print "=============================".
    print "1 - launch the 1st rocket".
    
    if exists("0:/missions/LKO_rt_" + parameters["orbit_altitude"] + "_" + parameters["orbit_inclination"] + ".json") {
        print "2 - launch the 2nd rocket".
    }
    print "3 - edit launch parameters".
    print "9 - exit".
    print "0 - update".
    print "=============================".
    print "CURENT PARAMS:".
    print "Orbit altitude: " + round(parameters["orbit_altitude"], 2) + " km".
    print "Orbit inclination: " + round(parameters["orbit_inclination"], 2) + " deg".
}

on ag1 {
    set menu_mode to "launch_1".
}

on ag2 {
    set menu_mode to "launch_2".
}

on ag3 {
    edit "parameters.json".
    preserve.
}

on ag10 {
    draw_menu().
    preserve.
}

on ag9 {
    set exit to true.
}

draw_menu().

function launch_me {
    parameter al, inc.
    parameter is_second is false.

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
    
    launch2orbit(al, al, inc).
    finecircle().
    
    // Deploy solar panels and antennas.
    panels on.
    set antennas to ship:partsdubbed("Communotron 32").
    for antenna in antennas {
        print "    Activating Communotron 32...".
        antenna:getmodule("ModuleRTAntenna"):doevent("activate").
    }
}

function deploy_and_deorbit_me {

    local lock dir to lookdirup(prograde:vector, ship:facing:topvector) .
    rotate2(dir).
    lock steering to dir.
    
    wait 5.

    // deploy satellite.
    printm("Deploying satellite.").
    set decouplers to ship:modulesnamed("ModuleDecouple").
    for dec in decouplers {
        dec:doevent("Decouple").
    }
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

until exit {
    if menu_mode = "launch_1" or menu_mode = "launch_2"{
        set parameters to readjson("parameters.json").
        
        local log_data is lexicon().
        
        if menu_mode = "launch_1" {
            log_data:add("start_time",  time:seconds).
        } else {
            set log_data to readjson("0:/missions/LKO_rt_" + parameters["orbit_altitude"] + "_" + parameters["orbit_inclination"] + ".json").
            local start_time is log_data["start_time"] + log_data["orbit_period"] / 2.
            set start_time to start_time + ceiling((time:seconds - start_time) / log_data["orbit_period"]) * log_data["orbit_period"].
            warpto(start_time - 15).
            wait until start_time <= time:seconds.
        }

        launch_me(parameters["orbit_altitude"], parameters["orbit_inclination"]).

        if menu_mode = "launch_1" {
            log_data:add("orbit_period",  ship:orbit:period).
            // TODO: warp...
            wait until not addons:rt:available or addons:rt:hasconnection(ship).
            writejson(log_data, "0:/missions/LKO_rt_" + parameters["orbit_altitude"] + "_" + parameters["orbit_inclination"] + ".json").
        }
        
        deploy_and_deorbit_me().
        set exit to true.
    }
    wait 0.1.
}

// TODO:
// found burn time.
// exec without add.
// fine circle.
// inclanation.
// inclanation with specified ascent/descent node.
// launch to orbit to position (possible with specified launch time measured by previous launch of this craft).
