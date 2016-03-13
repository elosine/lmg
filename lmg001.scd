//LANGUAGE MUSICS GRANULIZATION
////Short Attacks
SynthDef(\shortAttacks, {
	arg ibs, obs=0, amp=1, pan=0, dcrv=1,
	mindurL=0.02, mindurH=0.04, maxdurL=(1/7), maxdurH=0.5,
	minrateL=1.85, minrateH=4.0, maxrateL=9.0, maxrateH=15.0,
	ebf= -1;
	var sig, env, gtr, mtrig, dur, rcrv;
	var mindur, maxdur, minrate, maxrate;
	rcrv = \rcrv.kr(9, 0.05);
	mtrig = Impulse.kr(maxrateH);
	mindur = TRand.kr(mindurL, mindurH, mtrig);
	maxdur = TRand.kr(maxdurL, maxdurH, mtrig);
	minrate = TRand.kr(minrateL, minrateH, mtrig);
	maxrate = TRand.kr(maxrateL, maxrateH, mtrig);
	dur = pow( TRand.kr( 0.0, 1.0, mtrig), dcrv ).linlin(0.0, 1.0, mindur, maxdur);
	gtr = Impulse.kr( pow( TRand.kr( 0.0, 1.0, mtrig), rcrv ).linlin(0.0, 1.0, minrate, maxrate));
	sig = In.ar(ibs);
	sig = GrainIn.ar(1, gtr,dur,sig,pan,ebf);
	Out.ar(1, sig*amp);
}).add;


////SAMPLE TRILL
SynthDef(\shortAttacks_st, {
	arg obs, ibs1, ibs2, dur1=0.25, dur2=0.25, pan1=0, pan2=0, gr1envbuf= -1, gr2envbuf= -1, rate=0.5, amp=0.85;
	var in1, in2, gr1, gr2, stsig, g1trig, g2trig;
	in1 = In.ar(ibs1, 2);
	in2 = In.ar(ibs2, 2);
	g1trig = Impulse.kr(rate);
	g2trig = Impulse.kr(rate, 0.5);
	gr1 = GrainIn.ar(2, g1trig, dur1, in1, pan1, gr1envbuf);
	gr2 = GrainIn.ar(2, g2trig, dur2, in2, pan2, gr2envbuf);
	Out.ar( obs, (gr1+gr2)*amp);

}).add;

~g1 = Group.new;
~g2 = Group.after(~g1);
{Out.ar(50, WhiteNoise.ar());Out.ar(52, SinOsc.ar())}.play(~g1)
s.queryAllNodes

a = Synth(\shortAttacks_st, [\ibs1, 50, \ibs2,52], ~g2);
a.set(\rate, 2)