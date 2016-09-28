@lazyglobal off.

global mt_stime to 0.
function printm {
    parameter msg.

    print "[T+" + round(missiontime - mt_stime) + "]: " + msg.
}

function start_mission {
    set mt_stime to missiontime.
    printm("Launch!").
}
