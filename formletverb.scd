(
SynthDef(\formletVerb, {
	arg in, out, amp=1, decay=0.02;
	var input, freq, sig, onsetTr, dsig;
	input = SoundIn.ar(0);
	onsetTr = Coyote.kr(input);
	// freq = TIRand.kr(77, 83, onsetTr ).midicps;
	freq = TChoose.kr(onsetTr, [83, 84, 85, 86, 88, 89, 90, 91, 92, 94, 95, 96, 97, 98, 100, 101, 102, 103, 104, 106]).midicps;
	// freq = TIRand.kr(70, 90, onsetTr ).midicps;
	sig = Formlet.ar(K2A.ar(onsetTr), freq, 0.001, decay);
	sig  = sig*Amplitude.ar(input);
	dsig = DelayC.ar(sig, 0.2, 0.02);
	sig = JPverb.ar( [sig, dsig], SinOsc.kr(0.03).range(0.0, 3) );
	Out.ar(out, sig* amp);
}).add;
)

a = Synth(\formletVerb)

a.set(\decay, 0.5)

1000.cpsmidi

{ Formlet.ar(Impulse.ar(20, 0.5), 1000, 0.01, 0.1) }.play;

{ Formlet.ar(Blip.ar(XLine.kr(10,400,8),1000, 0.1), 1000, 0.01, 0.1) }.play;

(
// modulating formant frequency
{
    var in;
    in = Blip.ar(SinOsc.kr(5,0,20,300), 1000, 0.1);
    Formlet.ar(in, XLine.kr(1500,700,8), 0.005, 0.04);
}.play;
)

83, 84, 85, 86, 88, 89, 90, 91, 92, 94