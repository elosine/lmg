
(
s.options.sampleRate = 48000;
s.options.memSize = (8192*30);

s.options.numOutputBusChannels = 8;
s.waitForBoot{
	fork{
		var syn, insyn, keycmd;
		s.options.memSize = (8192*30);
		s.options.numOutputBusChannels = 8;
		~g0 = Group.new(s);
		~g1 = Group.after(~g0);
		~g2 = Group.after(~g1);
		0.1.wait;

		SynthDef(\liveinfilt, {
			arg in=0, amp=1, out=0, hpf=750, lpf=3000;
			var dsig;
			var sig = SoundIn.ar(in);
			sig = RHPF.ar(sig, hpf);
			sig = RLPF.ar(sig, lpf);
			dsig = DelayC.ar(sig, 0.2, 0.021);
			Out.ar(out, [sig, dsig]*amp);
		}).add;

		SynthDef(\livein, {
			arg in=0, amp=1, out=0;
			var sig = SoundIn.ar(in);
			Out.ar(out, sig*amp);
		}).add;

		SynthDef(\rot8, {
			arg in, out, amp, chgrate=(1/30), spdlo=0.1, spdhi=1, gate = 1;
			var input = In.ar(in);
			var env = EnvGen.ar( Env.asr(5, 1, 7), gate, doneAction:2);
			Out.ar(out, PanAz.ar(4, input, SinOsc.kr( LFTri.kr(chgrate).range(spdlo, spdhi) ) ) *env);
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

		//// Petals Of Resonance
		SynthDef("petalsOfResonance", {
			arg amp=1.0, inamp=1.0, ibs=0, obs=0, pobs, fund=80, firstPartial=1, bank2MidiOffset=0.37, spread=1.33, ringL1=17.75, ringL2=27.5, inputLen=0.5, trig=1, inatk = 20, inrel = 5.0, gate=1, tunerate=0.07, itrate=10.5, rel=11, pAmp= -15.0.dbamp;
			var	partialTunedA, partialTunedB, input, output, outArrayA, outArrayA1, outArrayA2, outArray, inenv, ltdOutput, ltdOutput1, ltdOutput2, masterEnv, finalOut,
			p1a, p2a, p3a, p4a, p5a, p6a, p7a, p8a, p9a, p10a, p11a, p12a, p13a,
			p1b, p2b, p3b, p4b, p5b, p6b, p7b, p8b, p9b, p10b, p11b, p12b, p13b,
			resA1, resA2, resA3, resA4, resA5, resA6, resA7, resA8, resA9, resA10, resA11, resA12, resA13,
			resB1, resB2, resB3, resB4, resB5, resB6, resB7, resB8, resB9, resB10, resB11, resB12, resB13;
			var outenv, sig2, inputcancel, itr;
			var outArrayB = Array.newClear(8);
			//pAmp = -10.dbamp;
			//Two functions to create two sets of partials
			partialTunedA = 	{
				arg partialNum;
				var freq, freqMidi, tuner, freqTunedMidi, freqTuned;
				//firstPartial allows you to start the series at a higher partial than the fund
				//the fund and spread work together (maybe redundantly)
				//to determine the space between each partial
				freq = fund *( firstPartial + (spread*partialNum) );
				freqMidi = freq.cpsmidi;
				//constantly shifting tuner for each partial
				//so the sound is constantly shifting
				tuner = SinOsc.kr(rrand(0.07, 0.013), 0, 0.5);
				//tuner = SinOsc.kr(tunerate, 0, 0.5);
				freqTunedMidi = freqMidi + tuner;
				freqTuned = freqTunedMidi.midicps;
			};
			partialTunedB = 	{
				arg partialNum;
				var freq, freqMidi, tuner, freqTunedMidi, freqTuned;
				freq = fund *( firstPartial + (spread*partialNum) );
				freqMidi = freq.cpsmidi;
				tuner = SinOsc.kr(rrand(0.07, 0.013), 0, 0.5);
				//tuner = SinOsc.kr(tunerate+rrand(0.01, 0.013), 0, 0.5);
				freqTunedMidi = freqMidi + tuner + bank2MidiOffset;
				freqTuned = freqTunedMidi.midicps;
			};
			p1a= partialTunedA.value(0);
			p2a= partialTunedA.value(1);
			p3a= partialTunedA.value(2);
			p4a= partialTunedA.value(3);
			p5a= partialTunedA.value(4);
			p6a= partialTunedA.value(5);
			p7a= partialTunedA.value(6);
			p8a= partialTunedA.value(7);
			p9a= partialTunedA.value(8);
			p10a= partialTunedA.value(9);
			p11a= partialTunedA.value(10);
			p12a= partialTunedA.value(11);
			p13a= partialTunedA.value(12);
			p1b= partialTunedB.value(0);
			p2b= partialTunedB.value(1);
			p3b= partialTunedB.value(2);
			p4b= partialTunedB.value(3);
			p5b= partialTunedB.value(4);
			p6b= partialTunedB.value(5);
			p7b= partialTunedB.value(6);
			p8b= partialTunedB.value(7);
			p9b= partialTunedB.value(8);
			p10b= partialTunedB.value(9);
			p11b= partialTunedB.value(10);
			p12b= partialTunedB.value(11);
			p13b= partialTunedB.value(12);
			input = In.ar(ibs);
			//inenv = EnvGen.ar( Env.perc(0.02, inputLen, 1.0, -1), t_tr);
			inenv = EnvGen.ar( Env.asr(inatk, 1, inrel, 10), trig);
			// itr = Impulse.kr(itrate);
			//	inenv = EnvGen.ar( Env.perc(0.02, inputLen, 0.1, -1), itr);
			input =  input * inamp * inenv;
			//inputcancel = input* -1;
			//Form 13 resonators for each bank/spectrum
			resA1 = DynKlank.ar(`[[p1a], nil, [rrand(ringL1, ringL2)]], input);
			resA2 = DynKlank.ar(`[[p2a], nil, [rrand(ringL1, ringL2)]], input);
			resA3 = DynKlank.ar(`[[p3a], nil, [rrand(ringL1, ringL2)]], input);
			resA4 = DynKlank.ar(`[[p4a], nil, [rrand(ringL1, ringL2)]], input);
			resA5 = DynKlank.ar(`[[p5a], nil, [rrand(ringL1, ringL2)]], input);
			resA6 = DynKlank.ar(`[[p6a], nil, [rrand(ringL1, ringL2)]], input);
			resA7 = DynKlank.ar(`[[p7a], nil, [rrand(ringL1, ringL2)]], input);
			resA8 = DynKlank.ar(`[[p8a], nil, [rrand(ringL1, ringL2)]], input);
			resA9 = DynKlank.ar(`[[p9a], nil, [rrand(ringL1, ringL2)]], input);
			resA10 = DynKlank.ar(`[[p10a], nil, [rrand(ringL1, ringL2)]], input);
			resA11 = DynKlank.ar(`[[p11a], nil, [rrand(ringL1, ringL2)]], input);
			resA12 = DynKlank.ar(`[[p12a], nil, [rrand(ringL1, ringL2)]], input);
			resA13 = DynKlank.ar(`[[p13a], nil, [rrand(ringL1, ringL2)]], input);
			resB1 = DynKlank.ar(`[[p1b], nil, [rrand(ringL1, ringL2)]], input);
			resB2 = DynKlank.ar(`[[p2b], nil, [rrand(ringL1, ringL2)]], input);
			resB3 = DynKlank.ar(`[[p3b], nil, [rrand(ringL1, ringL2)]], input);
			resB4 = DynKlank.ar(`[[p4b], nil, [rrand(ringL1, ringL2)]], input);
			resB5 = DynKlank.ar(`[[p5b], nil, [rrand(ringL1, ringL2)]], input);
			resB6 = DynKlank.ar(`[[p6b], nil, [rrand(ringL1, ringL2)]], input);
			resB7 = DynKlank.ar(`[[p7b], nil, [rrand(ringL1, ringL2)]], input);
			resB8 = DynKlank.ar(`[[p8b], nil, [rrand(ringL1, ringL2)]], input);
			resB9 = DynKlank.ar(`[[p9b], nil, [rrand(ringL1, ringL2)]], input);
			resB10 = DynKlank.ar(`[[p10b], nil, [rrand(ringL1, ringL2)]], input);
			resB11 = DynKlank.ar(`[[p11b], nil, [rrand(ringL1, ringL2)]], input);
			resB12 = DynKlank.ar(`[[p12b], nil, [rrand(ringL1, ringL2)]], input);
			resB13 = DynKlank.ar(`[[p13b], nil, [rrand(ringL1, ringL2)]], input);
			//Make an array of resonators and scramble them up
			outArrayA = [ resA1*pAmp, resA2*pAmp, resA3*pAmp, resA4*pAmp, resA5*pAmp, resA6*pAmp, resA7*pAmp, resA8*pAmp, resA9*pAmp, resA10*pAmp,resA11*pAmp, resA12*pAmp, resA13*pAmp, resB1*pAmp, resB2*pAmp, resB3*pAmp, resB4*pAmp, resB5*pAmp, resB6*pAmp, resB7*pAmp, resB8*pAmp, resB9*pAmp, resB10*pAmp, resB11*pAmp, resB12*pAmp, resB13*pAmp ].scramble;

			//For Stereo or Multichannel
			outArrayA1 = Array.newFrom(outArrayA);
			outArrayA1 = outArrayA1.copyRange(0, (outArrayA1.size/2).asInteger);
			outArrayA2 = Array.newFrom(outArrayA);
			outArrayA2 = outArrayA2.copyRange( (outArrayA2.size/2).asInteger, outArrayA2.size );
			outArrayA1 = Mix.ar(outArrayA1);
			outArrayA2 = Mix.ar(outArrayA2);
			//STEREO
			ltdOutput1 = Limiter.ar( outArrayA1, 0.98, 0.01 );
			ltdOutput2 = Limiter.ar( outArrayA2, 0.98, 0.01 );
			outenv = EnvGen.ar(Env.asr(0.01, 1, rel), gate, doneAction:2);
			//Out.ar(pobs, [ltdOutput1,ltdOutput2]*amp*outenv); //out to private (stereo)bus
			Out.ar(obs, [ltdOutput1, ltdOutput2, ltdOutput2, ltdOutput1, ltdOutput2, ltdOutput1, ltdOutput1, ltdOutput1]*amp*outenv); //8 channels
		}, [0.069]
		).add;

		SynthDef(\heart, 	{ |gate=1 out=0 amp=0.2|
			var env= EnvGen.ar(Env.asr(releaseTime:10), gate, doneAction:2);
			var sig =  Mix.ar([Greyhole.ar(DynKlank.ar(`[ [SinOsc.kr(0.05).range(27, 34).midicps, SinOsc.kr(0.05).range(27, 34).midicps*2, SinOsc.kr(0.02).range(27, 34).midicps], nil, [SinOsc.kr(0.008).range(0.01, 1.0), SinOsc.kr(0.008).range(0.01, 1.0), SinOsc.kr(0.008).range(0.01, 1.0)] ], RLPF.ar( [SoundIn.ar(), DelayC.ar( SoundIn.ar(), 0.2, SinOsc.kr(0.03).range(0.001, 0.07))], 100, LFTri.kr(0.04).range(0.071, 0.3)))*0.2 , SinOsc.kr(0.05).range(0.1, 1), diff:0.1)*SinOsc.ar(0.04).range(0.01, 0.27),  DynKlank.ar(`[ [SinOsc.kr(0.01).range(27, 34).midicps, SinOsc.kr(0.01).range(27, 34).midicps*2, SinOsc.kr(0.02).range(27, 34).midicps], nil, [SinOsc.kr(0.008).range(0.01, 1.0), SinOsc.kr(0.008).range(0.01, 1.0), SinOsc.kr(0.008).range(0.01, 1.0)] ], RLPF.ar( [SoundIn.ar(), DelayC.ar( SoundIn.ar(), 0.2, SinOsc.kr(0.03).range(0.001, 0.07))], 100, LFTri.kr(0.04).range(0.071, 0.3)))*0.02 ]*amp );

			var sig2 = Mix.ar([Greyhole.ar(DynKlank.ar(`[ [SinOsc.kr(0.04).range(27, 34).midicps, SinOsc.kr(0.04).range(27, 34).midicps*2, SinOsc.kr(0.03).range(27, 34).midicps], nil, [SinOsc.kr(0.007).range(0.01, 1.0), SinOsc.kr(0.009).range(0.01, 1.0), SinOsc.kr(0.005).range(0.01, 1.0)] ], RLPF.ar( [SoundIn.ar(), DelayC.ar( SoundIn.ar(), 0.2, SinOsc.kr(0.04).range(0.001, 0.07))], 100, LFTri.kr(0.03).range(0.071, 0.3)))*0.2 , SinOsc.kr(0.06).range(0.1, 1), diff:0.1)*SinOsc.ar(0.02).range(0.01, 0.27),  DynKlank.ar(`[ [SinOsc.kr(0.005).range(27, 34).midicps, SinOsc.kr(0.015).range(27, 34).midicps*2, SinOsc.kr(0.023).range(27, 34).midicps], nil, [SinOsc.kr(0.007).range(0.01, 1.0), SinOsc.kr(0.009).range(0.01, 1.0), SinOsc.kr(0.004).range(0.01, 1.0)] ], RLPF.ar( [SoundIn.ar(), DelayC.ar( SoundIn.ar(), 0.2, SinOsc.kr(0.05).range(0.001, 0.07))], 100, LFTri.kr(0.055).range(0.071, 0.3)))*0.02 ] *amp);

			var sig3 =  Mix.ar([Greyhole.ar(DynKlank.ar(`[ [SinOsc.kr(0.05).range(27, 34).midicps, SinOsc.kr(0.077).range(27, 34).midicps*2, SinOsc.kr(0.022).range(27, 34).midicps], nil, [SinOsc.kr(0.0064).range(0.01, 1.0), SinOsc.kr(0.0077).range(0.01, 1.0), SinOsc.kr(0.0032).range(0.01, 1.0)] ], RLPF.ar( [SoundIn.ar(), DelayC.ar( SoundIn.ar(), 0.2, SinOsc.kr(0.053).range(0.001, 0.07))], 100, LFTri.kr(0.039).range(0.071, 0.3)))*0.2 , SinOsc.kr(0.072).range(0.1, 1), diff:0.1)*SinOsc.ar(0.018).range(0.01, 0.27),  DynKlank.ar(`[ [SinOsc.kr(0.0046).range(27, 34).midicps, SinOsc.kr(0.027).range(27, 34).midicps*2, SinOsc.kr(0.032).range(27, 34).midicps], nil, [SinOsc.kr(0.0059).range(0.01, 1.0), SinOsc.kr(0.0072).range(0.01, 1.0), SinOsc.kr(0.006).range(0.01, 1.0)] ], RLPF.ar( [SoundIn.ar(), DelayC.ar( SoundIn.ar(), 0.2, SinOsc.kr(0.068).range(0.001, 0.07))], 100, LFTri.kr(0.045).range(0.071, 0.3)))*0.02 ]*amp );


			var sig4 =  Mix.ar([Greyhole.ar(DynKlank.ar(`[ [SinOsc.kr(0.08).range(27, 34).midicps, SinOsc.kr(0.073).range(27, 34).midicps*2, SinOsc.kr(0.034).range(27, 34).midicps], nil, [SinOsc.kr(0.0091).range(0.01, 1.0), SinOsc.kr(0.0105).range(0.01, 1.0), SinOsc.kr(0.0102).range(0.01, 1.0)] ], RLPF.ar( [SoundIn.ar(), DelayC.ar( SoundIn.ar(), 0.2, SinOsc.kr(0.057).range(0.001, 0.07))], 100, LFTri.kr(0.069).range(0.071, 0.3)))*0.2 , SinOsc.kr(0.08).range(0.1, 1), diff:0.1)*SinOsc.ar(0.073).range(0.01, 0.27),  DynKlank.ar(`[ [SinOsc.kr(0.024).range(27, 34).midicps, SinOsc.kr(0.027).range(27, 34).midicps*2, SinOsc.kr(0.037).range(27, 34).midicps], nil, [SinOsc.kr(0.018).range(0.01, 1.0), SinOsc.kr(0.011).range(0.01, 1.0), SinOsc.kr(0.0094).range(0.01, 1.0)] ], RLPF.ar( [SoundIn.ar(), DelayC.ar( SoundIn.ar(), 0.2, SinOsc.kr(0.054).range(0.001, 0.07))], 100, LFTri.kr(0.055).range(0.071, 0.3)))*0.02 ]*amp );

			Out.ar(out, sig*env); Out.ar(out+2, sig2*env); Out.ar(out+4, sig3*env); Out.ar(out+6, sig4*env);

		}).add;
		0.35.wait;

		keycmd = Document.current;
		keycmd.keyDownAction_({
			arg ...args;
			if( args[3].asInteger == 32, {
				fork{

									//start petals
					"START THROAT".postln;

					s.sendMsg(\s_new,\petalsOfResonance, 3200, 0, ~g1.nodeID, \ibs, 30, \inamp, 1.0, \fund, 60, \firstPartial, 1, \bank2MidiOffset, 0.37, \spread, 1.33, \pAmp, -20.dbamp, \amp, 0.4);
					0.1.wait;
					s.sendMsg(\s_new, \livein, 3202, 0, ~g0.nodeID, \in, 0, \amp, 1, \out, 30);

					(60*4.5).wait;
					// (60*1.1).wait;
					"STOP THROAT".postln;

					s.sendMsg(\n_set, 3200,\trig, 0); //end throat
					11.wait;
					s.sendMsg(\n_free,  3202);
					10.wait;

					//heart
					"START HEART".postln;
					s.sendMsg(\s_new, \heart, 3209, 0, ~g0.nodeID, \amp, 0.0075);

					(60*2.5).wait;

					// (60*1.2).wait;
					"STOP HEART".postln;

					s.sendMsg(\n_set, 3209, \gate, 0); //cut heart

					20.wait;

					//gut
					"START GUT".postln;
					s.sendMsg(\s_new, \liveinfilt, 3105, 0, ~g0.nodeID, \in, 0, \amp, 8, \out, 55);
					s.sendMsg(\s_new, \formletVerb, 3107, 0, ~g1.nodeID, \in, 55, \amp, 0.3, \decay, 1, \out, 57);
					s.sendMsg(\s_new, \toypiano, 3109, 0, ~g1.nodeID, \in, 55, \thresh, 0.1, \amp, 0.5, \minDur, 2, \out, 59 );
					s.sendMsg(\s_new, \dist, 3111, 0, ~g1.nodeID, \in, 59, \type, 1, \amp, 0.25, \out, 61 );
					s.sendMsg(\s_new, \dist, 3113, 0, ~g1.nodeID, \in, 57, \type, 2, \amp, 0.3, \out, 63 );

					s.sendMsg(\s_new, \rot8, 3115, 0, ~g2.nodeID, \in, 57, \out, 0, \amp, 0.25, \chgrate, (1/30), \spdlo, 0.1, \spdhi, 1 );
					s.sendMsg(\s_new, \rot8, 3117, 0, ~g2.nodeID, \in, 59, \out, 0, \amp, 0.25, \chgrate, (1/42), \spdlo, 0.08, \spdhi, 0.7 );
					s.sendMsg(\s_new, \rot8, 3119, 0, ~g2.nodeID, \in, 61, \out, 0, \amp, 0.25, \chgrate, (1/26), \spdlo, 0.05, \spdhi, 2.2 );
					s.sendMsg(\s_new, \rot8, 3121, 0, ~g2.nodeID, \in, 63, \out, 0, \amp, 0.25, \chgrate, (1/55), \spdlo, 0.21, \spdhi, 0.92 );

					(60*2.2).wait;
					// (60*1.2).wait;
					"STOP GUT".postln;

					s.sendMsg(\n_set, 3115, \gate, 0);
					s.sendMsg(\n_set, 3117, \gate, 0);
					s.sendMsg(\n_set, 3119, \gate, 0);
					s.sendMsg(\n_set, 3121, \gate, 0);
				};
			}
			);
		});
}}

)

