s.options.sampleRate = 48000;
s.options.memSize_(65536 * 10);
(
b = Buffer.read(s, "/Users/yangj14/Music/SuperCollider Recordings/SC_171224_231400.aiff");

SynthDef(\playbuf, {
	arg buf, amp=1, out=0, hpf=750, lpf=3000;
	var dsig;
	var sig = PlayBuf.ar(1, buf, loop:1);
	sig = RHPF.ar(sig, hpf);
	sig = RLPF.ar(sig, lpf);
	dsig = DelayC.ar(sig, 0.2, 0.021);
	Out.ar(out, [sig, dsig]*amp);
}).add;

SynthDef(\gut, {
	arg buf, amp=13, out=0, hpf=750, lpf=3000, dt=1.5;
	var onset;
	var sig = PlayBuf.ar(1, buf, loop:1);
	sig = RHPF.ar(sig, hpf);
	sig = RLPF.ar(sig, lpf);
	onset = Coyote.kr(sig, fastMul:0.9);
	sig = sig*Decay.ar( sig*K2A.ar(onset), dt);
	Out.ar(out, sig*amp);
}).add;

SynthDef(\onsetTr, {
	arg in, out=0, trIn, thresh=0.07, mindur=0.01;
	var onset, sig, input, trInput;
	input = In.ar(in);
	trInput = In.kr(trIn);
	onset = Coyote.kr(input, fastMul:0.9, thresh: thresh, minDur: mindur);
	Out.kr(out, onset);
}).add;


// SynthDef(\formletVerb, {
// 	arg in, out, amp=1, decay=0.02;
// 	var input, freq, sig, onsetTr;
// 	input = In.ar(in);
// 	onsetTr = Coyote.kr(input);
// 	freq = TRand.kr(700, 1000, onsetTr );
// 	sig = Formlet.ar(input, freq, 0.001, decay);
// 	sig = JPverb.ar( sig, SinOsc.kr(0.03).range(0.0, 3) );
// 	Out.ar(out, sig* amp);
// }).add;

// SynthDef(\formletVerb, {
// 	arg in, out, amp=1, decay=0.02, thresh=0.07, mindur=0.01;
// 	var input, freq, sig, onset;
// 	input = In.ar(in);
// 	onset = Coyote.kr(input, fastMul:0.9, thresh: thresh, minDur: mindur);
// 	freq = TRand.kr(700, 1000, onset );
// 	sig = Formlet.ar(K2A(onset), freq, 0.001, decay);
// 	sig = JPverb.ar( sig, SinOsc.kr(0.03).range(0.0, 3) );
// 	Out.ar(out, sig* amp);
// }).add;

SynthDef(\formletVerb, {
	arg in, out, amp=1, decay=0.02;
	var input, freq, sig, onsetTr;
	input = In.ar(in);
	onsetTr = Coyote.kr(input);
	freq = TRand.kr(700, 1000, onsetTr );
	// sig = Formlet.ar(K2A.ar(onsetTr), freq, 0.001, decay);
	sig = Formlet.ar(input*EnvGen.ar(Env.linen(0.01, 0.05, 0.1),onsetTr), freq, 0.001, decay);
	sig = JPverb.ar( sig, SinOsc.kr(0.03).range(0.0, 3) );
	Out.ar(out, sig* amp);
}).add;

SynthDef(\toypiano, {
		arg out=0, lfospd=0.5, pos, t_tr=0, in;
		var amp = \amp.kr(0.85, 0.01);
	// var env = EnvGen.ar(Env.perc(0.01, 6.0, curve: -6), t_tr, doneAction:2);
	var imp = In.ar(in);
	var pitch = TIRand.kr(40, 75, Dust.kr(0.08) );
		var freq = pitch.midicps;
		var sig = DynKlank.ar(
			`[
				[
					1*freq,
					1.0526645678458*freq,
					1.0722177540716*freq,
					1.1173842322068*freq,
					3.2137255202035*freq,
					6.4619017331061*freq,
					( (6.523014752975*freq).cpsmidi + SinOsc.kr(0.05*lfospd) ).midicps,
					10.754460040742*freq,
					( (10.872643827698*freq).cpsmidi + SinOsc.kr(0.03*lfospd) ).midicps,
					22.34655484674*freq
				],
				[
					0.18875469647576,
					0.58145809091593,
					0.69866162462817,
					0.13283592569299,
					1,
					0.88929800059361+LFTri.kr(0.05*lfospd).range(-0.2, 0.2),
					0.46474200944761+LFTri.kr(0.03*lfospd).range(-0.2, 0.2),
					0.4771785852636+LFTri.kr(0.08*lfospd).range(-0.2, 0.2),
					0.44083819263811+LFTri.kr(0.1*lfospd).range(-0.2, 0.2),
					0.1543129814717+LFTri.kr(0.04*lfospd).range(-0.05, 0.05)
				]*0.1,
				[
					2.7874822816943,
					3.0044616469429,
					3.0818892662019,
					2.7804810119127,
					1.3462578280856,
					2.6210993045158,
					2.3655306128538,
					1.5798209670323,
					2.4811880715523,
					1.4092510528673
				]
			],
			imp);
	// sig = PanAz.ar(8, sig, pos, 1, 2, 0.5);
	Out.ar(out, [sig, DelayC.ar(sig, 0.2, 0.01)]*amp);
	}).add;
)

p = ProxySpace.push(s);
~out.ar(2);
~out.play;
~raw = \playbuf;
~raw.set(\buf, b, \amp, 8);

~trs = \onsetTr;
arg in, out=0, thresh=0.07, mindur=0.01;
~trs.set(\in, ~raw.bus.index);

~fv1 = \formletVerb
arg in, out, amp=1, decay=0.02, trIn;
~fv1.set(\in, ~raw.bus.index);

~fv3 = \formletVerb
arg in, out, amp=1, decay=0.02, trIn;
~fv3.set(\in, ~raw.bus.index);




~onset = \onsetAtk;
in, amp=1, out=0, dt=1.5, thresh=0.5, mindur=0.1;
~onset.set(\in, ~raw.bus.index, \amp, 1, \thresh, 0.07, \mindur, 0.001);



~imps = \gut;
~imps.set(\buf, b, \amp, 2);
~fv = \formletVerb;
~fv.set(\amp, 1, \decay, 0.5);
~fv.set(\in, ~imps.bus.index);
~fv.set(\in, ~raw.bus.index);
~tp = \toypiano
~tp.set(\in, ~imps.bus.index);


~out = ~raw
~out = ~fv2
~out = ~onset
~out = ~grs
~out = ~imps
~out = ~fv
~out = ~tp
~out = nil;
s.meter

