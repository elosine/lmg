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



SynthDef(\livein, {
	arg in=0, amp=1, out=0, hpf=750, lpf=3000;
	var dsig;
	var sig = SoundIn.ar(in);
	sig = RHPF.ar(sig, hpf);
	sig = RLPF.ar(sig, lpf);
	dsig = DelayC.ar(sig, 0.2, 0.021);
	Out.ar(out, [sig, dsig]*amp);
}).add;

SynthDef(\formletVerb, {
	arg in, out, amp=1, decay=0.5;
	var input, freq, sig, onsetTr, dsig;
	input = In.ar(in);
	onsetTr = Coyote.kr(input, fastMul:0.9, thresh:0.07, minDur:0.01);
	freq = TChoose.kr(onsetTr, [71, 72, 73, 74, 76, 77, 78, 79, 80, 82, 83, 84, 85, 86, 88, 89, 90, 91, 92, 94, 95, 96, 97, 98, 100, 101, 102, 103, 104, 106]).midicps;
	// freq = TIRand.kr(70, 90, onsetTr ).midicps;
	sig = Formlet.ar(K2A.ar(onsetTr), freq, 0.001, decay);
	sig  = (sig*Amplitude.ar(input));
	sig = JPverb.ar( sig, SinOsc.kr(0.03).range(0.0, 3) );
	Out.ar(out, sig* amp);
}).add;


SynthDef(\toypiano, {
	arg out=0, in, lfospd=0.5, thresh=0.05, minDur= 0.1;
	var amp = \amp.kr(0.85, 0.01);
	var input = In.ar(in);
	var onset = Coyote.kr(input, fastMul:0.9, thresh:thresh, minDur:minDur);
	var freq = TChoose.kr(onset, [71, 72, 73, 74, 76, 77, 78, 79, 80, 82, 83, 84, 85, 86, 88, 89, 90, 91, 92, 94, 95, 96, 97, 98, 100, 101, 102, 103, 104, 106]).midicps;
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
		K2A.ar(onset));

	sig  = (sig*Amplitude.ar(input))*8;
	sig = Pan2.ar( sig, TRand.kr(-1, 1,onset), 1, 2, 0.5);
	sig = JPverb.ar( sig, SinOsc.kr(0.05).range(0.0, 3) );

	Out.ar(out, sig*amp);
}).add;

SynthDef(\dist, {|out=99 in=4 drive=0.9 type=2 amp=1|
	var sig;
	sig = In.ar(in, 2)*(((drive**2)+0.02)*50);
	sig= SelectX.ar( type, [sig.softclip, sig.distort, sig.clip(-1,1), sig.fold(-1,1)]);
	sig = sig * ((amp**2)*(1-(drive/2.6)));
	Out.ar(out, sig);
}).add;
)

p = ProxySpace.push(s);
~out.ar(2);
~out.play;
~raw = \livein;
~raw.set(\amp, 8);

~fv = \formletVerb
~fv.set(\in, ~raw.bus.index, \amp, 0.3, \decay, 1);

~tp7 = \toypiano
~tp7.set(\in, ~raw.bus.index, \thresh, 0.1, \amp, 0.5, \minDur, 2);

~dist = \dist
out=99 in=4 drive=0.9 type=2 amp=1
~dist.set(\in, ~tp7.bus.index, \type, 1, \amp, 0.25);

~dist2 = \dist
~dist2.set(\in, ~fv.bus.index, \type, 2, \amp, 0.3);
~lf = {SinOsc.kr(0.01).range(0, 0.3)};
~dist2.map(\amp, ~lf);


~out.fadeTime = 3
~out = ~raw
~out = ~fv
~out = nil

~out2.ar(2);
~out2.play;
~out2 = nil
~out2 = ~dist

~out3.ar(2);
~out3.play;
~out3 = ~tp7

~out4.ar(2);
~out4.play;
~out4 = ~dist2

