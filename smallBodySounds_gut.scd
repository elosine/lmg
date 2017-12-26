s.options.sampleRate = 48000;

(
b = Buffer.read(s, "/Users/yangj14/Music/SuperCollider Recordings/SC_171224_231400.aiff");

/*SynthDef(\gut, {
	arg buf, amp=1, out=0, hpf=750, bpq=0.0001, sat=0.95, lpf=3000, bpf=1000, ffreq=350, chgrate=0.1, tfreq=7, ramp=0.3;
	var dsig, freq, rsig, drsig, onset;
	var sig = PlayBuf.ar(1, buf, loop:1);
	sig = RHPF.ar(sig, hpf);
	sig = RLPF.ar(sig, lpf);
	sig = BMoog.ar(sig, bpf, bpq, 2, sat);
	freq = TRand.kr(700, 1000, Dust.kr( chgrate ) ).poll;
	sig = Formlet.ar(sig*0.4, freq, 0.001, 0.02);

	onset = Coyote.kr(sig);
	sig = sig*onset;
	//sig = Pluck.ar(sig, onset);
	rsig = JPverb.ar(sig, SinOsc.kr(0.03).range(0.0, 3) );
	dsig = DelayC.ar(sig, 0.03, 0.03);
	// ramp = SinOsc.kr(0.05).range(0.0, 0.4);
	// ramp = 0;
	Out.ar(out, ( [sig, dsig] + (rsig*ramp) ) * amp);
}).add;*/
SynthDef(\gut, {
	arg buf, amp=13, out=0, hpf=750, bpq=0.0001, sat=0.95, lpf=3000, bpf=1000, ffreq=350, chgrate=0.1, tfreq=7, ramp=0.3,  trackFall=0.2, slowLag=0.2, fastLag= 0.01, fastMul= 0.5, thresh= 0.05, minDur= 0.1, dt=1, atk=0.03, rel=0.1, crv= -6, othresh = 0.3;
	var dsig, freq, rsig, drsig, onset, fft;
	var sig = PlayBuf.ar(1, buf, loop:1);


	sig = RHPF.ar(sig, hpf);
	sig = RLPF.ar(sig, lpf);
	freq = TRand.kr(700, 1000, Dust.kr( chgrate ) ).poll;
	sig = Formlet.ar(sig*0.4, freq, 0.001, 0.02);


	onset = Coyote.kr(sig, trackFall, slowLag, fastLag, fastMul, thresh, minDur);

	sig = sig*Decay.ar( sig*K2A.ar(onset), dt);

	rsig = JPverb.ar(sig, SinOsc.kr(0.03).range(0.0, 3) );

	dsig = DelayC.ar(sig, 0.03, 0.03);

	Out.ar(out, ( [sig, dsig] + (rsig*ramp) ) * amp);
}).add;
)


a = Synth(\gut, [\buf, b, \amp, 6]);
a.set(\amp, 4, \trackFall, 0.2, \slowLag, 0.2, \fastLag, 0.01, \fastMul, 0.9, \thresh, 0.05, \minDur, 0.1, \dt, 1.0, \lpf, 3000)


a.set(\amp, 18, \atk, 0.05, \rel, 0.3,\crv, -6)

(
    {Pluck.ar(WhiteNoise.ar(0.1), Impulse.kr(2), 440.reciprocal, 440.reciprocal, 10,
        coef:MouseX.kr(-0.999, 0.999))
    }.play(s)
)