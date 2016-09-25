DECLARE PARAMETER orbitalt.
//DECLARE PARAMETER optimalTWR.
//DECLARE PARAMETER gt0.
//DECLARE PARAMETER gt1.

set thrust to 1.
lock throttle to thrust. 
function get_throttle {
	parameter opt_twr.
	if maxthrust > 0 {
		local heregrav is body:mu/((altitude+body:radius)^2).
		local maxtwr to ship:maxthrust / (heregrav * ship:mass).
        return min(opt_twr / maxtwr, 1).
    } else {
		return 0.
	}
}

list engines in engines.
function check_stage {
	set stageneeded to false.
    for eng in engines {
        if eng:flameout and eng:thrust = 0
            {
                    set stageneeded to true.
            }
    }.
	
    if stageneeded {
	    stage.
		print "Stage separeted.".
		list engines in engines.
        wait 1.
	}
}

print "T-3...".
wait 1.
print "T-2...".
wait 1.
print "T-1...".
wait 1.
print "LAUNCH!".
stage.

// control speed and attitude
set pitch to 0.
set pitch0 to 45.
set optimal_twr to 1.8.
set gt0 to 30000.
set gt1 to 50000.
set launch_altitude to altitude.

//until altitude > body:atm:height or apoapsis > orbitalt {
until true and altitude > body:atm:height and apoapsis > orbitalt {
    check_stage().
	
	//set ar to alt:radar.
	set ar to altitude - launch_altitude.

     if ar < gt0 {
        set arr to ar / gt0.
        set pda to (cos(arr * 180) + 1) / 2.
        set pitch to pitch0 * ( 1 - pda ).
		
		// 0 for NORTH.
        set pitchvector to heading(90, 90-pitch).
        lock steering to lookdirup(pitchvector:vector, ship:facing:topvector).
    }
    
    if ar > gt0 and ar < gt1 {
        //keep the ship's roll always top
        lock steering to lookdirup(srfprograde:vector, ship:facing:topvector).
    }
	
    if ar > gt1 {
        //we can turn orbital prograde now
        lock steering to lookdirup(prograde:vector, ship:facing:topvector).
    }
    
	if apoapsis < orbitalt {
		set thrust_temp to get_throttle(optimal_twr).
		if apoapsis > 0.999 * orbitalt {
			set thrust_temp to 0.01.
		} else if apoapsis > 0.99 * orbitalt {
			set thrust_temp to 0.05 * thrust_temp.
		} else if apoapsis > 0.9 * orbitalt {
			set thrust_temp to 0.8 * thrust_temp.
		}
		set thrust to thrust_temp.
	} else {
		set thrust to 0 .
	}
	wait 0.01.
}.

print "Circularization".

//set initialPeriapsis to ship:periapsis
//until ship:periapsis > orbitalt
//{
//    set etaFraction to ( ship:periapsis - initialPeriapsis)/( ship:apoapsis - initialPeriapsis).
//    set desiredETA to etaFraction*(finalETA - initialETA) + initialETA.
//    set desiredETA to max ( finalETA, min ( initialETA, desiredETA)).
//
//
//
//    set err to ETA:apoapsis - desiredETA.
//    set dT to missiontime - pT.
//    set pT to missiontime .
//    set dErr to (err-pErr)/dT.
//    set errInt to errInt + err*dT.
//
//    set thrust to P*err + I*errInt + D*dErr + 0.5. // plus 0.5 to give it pos and neg at beginning.
//
//    if eta:apoapsis > 10* initialETA // something has gone wrong and we passed apoapsis
//    {
//        break .
//    }
//
//    wait 0.01.
//}

stage.

set antennas to ship:partsdubbed("ommunotron 32").
for antenna in antennas {
	antenna:getmodule("ModuleRTAntenna"):doevent("activate").
}

unlock all.
print "done".