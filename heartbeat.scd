s.options.sampleRate = 48000

(
a={|gate=1| EnvGen.ar(Env.asr(releaseTime:10), gate)*Mix.ar([Greyhole.ar(DynKlank.ar(`[ [SinOsc.kr(0.05).range(27, 34).midicps, SinOsc.kr(0.05).range(27, 34).midicps*2, SinOsc.kr(0.02).range(27, 34).midicps], nil, [SinOsc.kr(0.008).range(0.01, 1.0), SinOsc.kr(0.008).range(0.01, 1.0), SinOsc.kr(0.008).range(0.01, 1.0)] ], RLPF.ar( [SoundIn.ar(), DelayC.ar( SoundIn.ar(), 0.2, SinOsc.kr(0.03).range(0.001, 0.07))], 100, LFTri.kr(0.04).range(0.071, 0.3)))*0.2 , SinOsc.kr(0.05).range(0.1, 1), diff:0.1)*SinOsc.ar(0.04).range(0.01, 0.27),  DynKlank.ar(`[ [SinOsc.kr(0.01).range(27, 34).midicps, SinOsc.kr(0.01).range(27, 34).midicps*2, SinOsc.kr(0.02).range(27, 34).midicps], nil, [SinOsc.kr(0.008).range(0.01, 1.0), SinOsc.kr(0.008).range(0.01, 1.0), SinOsc.kr(0.008).range(0.01, 1.0)] ], RLPF.ar( [SoundIn.ar(), DelayC.ar( SoundIn.ar(), 0.2, SinOsc.kr(0.03).range(0.001, 0.07))], 100, LFTri.kr(0.04).range(0.071, 0.3)))*0.02 ] )}.play(fadeTime:10);

~keycmd = Document.current;
~keycmd.keyDownAction_({
	arg ...args;
	if( args[3].asInteger == 32, {a.set(\gate, 0)}) ;
});

)
