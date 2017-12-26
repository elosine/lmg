s.options.sampleRate = 48000;
s.options.memSize_(65536 * 10);
(
b = Buffer.read(s, "/Users/yangj14/Music/SuperCollider Recordings/SC_171224_231400.aiff");

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

SynthDef(\formletVerb, {
	arg ibs, pchgrate=0.07, out, amp=1, decay=0.02;
	var in, freq, sig;
	in = In.ar(ibs);
	freq = TRand.kr(700, 1000, Dust.kr( pchgrate ) );
	sig = Formlet.ar(in, freq, 0.001, decay);
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
~imps = \gut;
~imps.set(\buf, b, \amp, 3);
ibs, pchgrate=0.07, out, amp=1, decay=0.02;
~fv = \formletVerb;
~fv.set(\pchgrate, \amp, \decay);
~tp = \toypiano
~tp.set(\in, ~imps.bus.index);

~out = ~tp
~out = ~imps
~out = ~imps
s.meter

