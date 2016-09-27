// loading.
print "LOADING...".
wait 10.
clearscreen.

if true or not exists("1:/mt.ksm") {
    copypath("0:/spec_char.ksm", "").
    compile "0:/core/l2o.ks" to "1:/l2o.ksm".
    compile "0:/core/warptools.ks" to "1:/warptools.ksm".
    compile "0:/core/nodetools.ks" to "1:/nodetools.ksm".
    compile "0:/core/mt.ks" to "1:/mt.ksm".
    copypath("0:/core", "").
}

run spec_char.
//cd("1:/core").
run mt.
run warptools.
run nodetools.
//run l2o.

cd("1:/core").
run l2o.

on ag1 {
    print "1".
    launch2circle(100000, 0.0).
}

launch2circle(100000, 0.0).