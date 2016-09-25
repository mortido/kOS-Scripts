// mission time logger.

set stime to 0.
function printm {
	parameter msg.
	print "[T+" + round(missiontime - stime) + "]: " + msg.
}

function start_mission {
	set stime to missiontime.
	printm("Launch!").
}
