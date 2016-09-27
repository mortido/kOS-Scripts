copypath("0:/core", "").
copypath("0:/spec_char.ksm", "").
wait 10.
run spec_char.
cd("1:/core").
run mt.
run warptools.
run nodetools.
run l2o(100000).
