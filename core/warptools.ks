function warp2physic {
    parameter aimtime.
    local warpmode is "PHYSICS".
    print "Warping with physics!".
    
    until aimtime <= time:seconds {
        // remaining time
        local dt is aimtime - time:seconds.
        local maxwarp is 4.
        if dt < 8     { set maxwarp to 0. }
        else if dt < 25     { set maxwarp to 1. }
        else if dt < 50     { set maxwarp to 2. }
        else if dt < 60     { set maxwarp to 3. }
        if WARP > maxwarp {
            set WARP to maxwarp.
            wait 1.
        } else {
            wait 0.5.
        }
    }
}

function warp2rails {
    parameter aimtime.
    local warpmode is "RAILS".
    print "Warping on rails!".
    
    until aimtime <= time:seconds {
        // remaining time
        local dt is aimtime - time:seconds.
        local maxwarp is 8.
        if dt < 8     { set maxwarp to 0. }
        else if dt < 25     { set maxwarp to 1. }
        else if dt < 50     { set maxwarp to 2. }
        else if dt < 60     { set maxwarp to 3. }
        else if dt < 100    { set maxwarp to 4. }
        else if dt < 1000   { set maxwarp to 5. }
        else if dt < 10000  { set maxwarp to 6. }
        else if dt < 100000 { set maxwarp to 7. }
        if WARP > maxwarp {
            set WARP to maxwarp.
            wait 1.
        } else {
            wait 0.5.
        }
    }
}

function warpdelta2physic {
    parameter delta.
    warp2physic(time:seconds + delta).
}

function warpdelta2rails {
    parameter delta.
    warp2rails(time:seconds + delta).
}
