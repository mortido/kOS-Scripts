@lazyglobal off.

// TODO: move to some "common" lib.
global engs is list().

function update_engines {
    list engines in engs.
}

function check_stage {

    local need_stage is true.
    for eng in engs {
        if eng:flameout { //and eng:thrust = 0 {
                set need_stage to true.
                break.
        } else if eng:ignition {
            set need_stage to false.
        }
    }

    if need_stage {
            stage.
            print "Stage separeted.".
            update_engines().
            wait 0.5.
    }
}