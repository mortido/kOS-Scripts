// loading.
print "LOADING...".
wait 10.
clearscreen.

if not exist("1:/mt.ksm") {
    copypath("0:/spec_char.ksm", "").
    compile("0:/core/l2o.ks", "1:/l2o.ksm").
    compile("0:/core/warptools.ks", "1:/warptools.ksm").
    compile("0:/core/nodetools.ks", "1:/nodetools.ksm").
    compile("0:/core/mt.ks", "1:/mt.ksm").
}

run spec_char.
run mt.
run warptools.
run nodetools.
run l2o.

on ag1 {
    launch2circle(100000, 0.0).
}