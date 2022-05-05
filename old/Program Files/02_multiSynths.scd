///////////////////////////////////////////////////////EIDOLON MultiChannel Synths//////////////////////////////////////////////////////////////////////
(
var numChannels = ~config[\numChannels];
var orientation = ~config[\orientation];

(
~transforms = Dictionary[

	"densePerc" -> Dictionary[

		"brokenRecord" -> {
			var sig1;

			var sig = In.ar(\inBus.kr,1);
			var trig = In.kr(~onsetsBus) + In.kr(~hasFreqBus);
			var gate = EnvGen.ar(Env.sine(0.1),trig);
			var rand = In.kr(~silenceBus);
			rand = TExpRand.kr(0.05,0.3,rand);
			sig = CombC.ar(sig*gate,0.6,rand,Select.kr(Trig1.kr(trig,rand-0.01),[inf,0]));
			sig1 = DelayN.ar(sig,0.6,rand*7/5);
			sig = PanAz.ar(numChannels,sig,LFNoise2.kr(0.2),\amp.kr(0.7),2,orientation) + PanAz.ar(numChannels,sig1,LFNoise2.kr(0.2),\amp.kr(0.7),2,orientation);
		},

		"percShiftDelay" -> {
			var grainSize=1.0,freq,hasFreq;
			var freqDev = In.kr(~varianceIOIBus).clip(0.6,1.2);
			var maxDev = In.kr(~specFlatnessBus).clip(0.3,0.8);
			var	sig = In.ar(\inBus.kr,1);

			sig = sig + LocalIn.ar(1);
			#freq, hasFreq = Pitch.kr(sig, ampThreshold: 0.05, median: 7);
			sig = sig*(1-hasFreq);
			sig = PitchShift.ar(sig,grainSize,freqDev.clip(0.5,4.0),maxDev.clip(0.0,3.0),grainSize);
			sig = LeakDC.ar(sig);
			LocalOut.ar(sig*0.7);
			sig = PanAz.ar(numChannels,sig,TRand.kr(-1.0,1.0,1-hasFreq).lag(maxDev),\amp.kr(1.0),2,orientation);

		},

		"fftFreeze" -> {
			var chain;
			var frames=4096;

			var	sig = In.ar(\inBus.kr,1);
			var trig = In.kr(~onsetsBus) + In.kr(~hasFreqBus);
			trig = Trig.kr(trig,TRand.kr(0.3,0.5,trig));
			chain = FFT(LocalBuf(frames), sig, 0.5, 0, 1, frames);
			chain = PV_Freeze(chain,trig);
			sig = IFFT(chain);
			sig = PanAz.ar(numChannels,sig*trig,TRand.kr(-1.0,1.0,trig),\amp.kr(1.0),2,orientation);
		},
	],

	/**************************/

	"pitchTrack" -> Dictionary
	[
		"ringMod" -> {
			var dev = TExpRand.kr(0.01,4000,In.kr(~onsetsBus));
			var gate = In.kr(~hasFreqBus);
			var sig = (In.ar(\inBus.kr,1))*gate;
			var mod = SinOsc.ar(In.kr(~freqBus)*2*SinOsc.ar(dev).range(0.75,0.75.reciprocal));
			sig = sig*mod;
			sig = PanAz.ar(numChannels,sig,LFNoise2.kr(0.2).range((2/numChannels).neg,(2/numChannels)),1,2,orientation);
		},

		"pitchShift" -> {
			var grainSize=0.15,maxDev,sig;

			var	freqDev = Drand([7/8,8/7,8/9,9/8,9/10,10/9],inf);
			freqDev = Demand.kr(Dust.kr(In.kr(~specFlatnessBus)*5),0,freqDev);
			maxDev = SinOsc.kr(In.kr(~varianceIOIBus)).clip(0.01,0.05);
			sig = In.ar(\inBus.kr,1);
			sig = PitchShift.ar(sig,grainSize,freqDev,maxDev,grainSize);
			sig = PanAz.ar(numChannels,sig,LFNoise2.kr(0.2).range((2/numChannels).neg,(2/numChannels)),1,2,orientation);
		},

		"bitz" -> {
			var rate = In.kr(~freqBus);
			var bits = In.kr(~specFlatnessBus);

			var sig = In.ar(\inBus.kr,1);
			sig = Decimator.ar(sig,SampleRate.ir * rate.explin(20,20000,0.05,1.0), 24 * bits.clip(0.05,1.0));
			sig = PanAz.ar(numChannels,sig,LFNoise2.kr(0.2).range((2/numChannels).neg,(2/numChannels)),\amp.kr(0.3),2,orientation);
		},

	],

	/**************************/

	"fillSilence" -> Dictionary
	[
		"tesla" -> {
			var carfreq = \carFreq.kr(1.3);

			var mod = SinOscFB.ar(\modfreq.kr(8000) * Dust.ar(LFNoise0.kr(0.3).range(0.2,10)).lag,\modFB.kr(3));
			var car = LFTri.ar([carfreq,carfreq*1.05],pi,0.5,0.5)+mod;
			var sig = car*mod;
			sig = BHiPass4.ar(sig,100,2);
			sig = BLowPass4.ar(sig,\filt.kr(8000),\rq.kr(1));
			sig = LeakDC.ar(sig);
			sig = PanAz.ar(numChannels,sig.sum,LFNoise2.kr(2),\amp.kr(0.08),2,orientation);
		},
	],
];

~bufTransforms = Dictionary[
	"bufGlitch" -> {
		var bufnum = \bufnum.kr;

		var freq = (In.kr(~specFlatnessBus)).clip(0.6,1.0);
		var bufFr = BufFrames.kr(bufnum)-1;
		var pointer = LFDNoise1.ar(freq).range(0,bufFr);
		var sig = BufRd.ar(1,bufnum,pointer,1);
		sig = PanAz.ar(numChannels,sig,pointer.linlin(0,bufFr,-0.5,0.5),1,2,orientation);
	},

	"bufStutter" -> {
		var bufnum = \bufnum.kr;

		var rate = TExpRand.kr(0.7,1.1,In.kr(~silenceBus));
		var speed = In.kr(~hasFreqBus).clip(1.0,6.0);
		var bufFr = BufFrames.kr(bufnum)-1;
		var trig = Impulse.kr(speed.lag(0.5));
		var pointer = Phasor.ar(0,0.05,0,bufFr);
		var rand = TIRand.kr(-1,1,trig);
		var sig = PlayBuf.ar(1,bufnum,rate,trig,pointer,loop: 1).lag(rate.reciprocal*0.066);
		sig = BLowPass4.ar(sig,6000);
		sig = PanAz.ar(numChannels,sig,pointer.linlin(0,bufFr,rand.asFloat,rand.neg.asFloat),0.8,2,orientation);
	},

	"bufAMRing" -> {
		var bufnum = \bufnum.kr;

		var ringfreq = Latch.kr(In.kr(~centroidBus),Impulse.kr(0.8));
		var modfreq = 7;
		var car = BufRd.ar(1,bufnum,LFTri.ar((BufDur.ir(bufnum).reciprocal)*LFNoise2.kr(0.5).range(0.6,0.8)).range(0, BufFrames.ir(bufnum)),1);
		var mod = LFPulse.ar(modfreq*LFNoise2.kr(2).range(0.2,2.0),0,LFNoise0.ar(4).range(0.3,0.8)).abs;
		var sig = car*mod.lag;
		sig = sig * SinOsc.ar(ringfreq);
		sig = BHiShelf.ar(sig,6000,0.5,-6);
		sig = PanAz.ar(numChannels,sig,LFNoise2.kr(0.2).range((2/numChannels).neg,(2/numChannels)),1,2,orientation);
	},

	"tGrainz" -> {
		var bufnum = \bufnum.kr;
		var sig,rate,trig,pointer,posDif=0.5,posLo,posDev=0.03,bufSection,bufDur,grainDur=1.2;

		trig = In.kr(~silenceBus);
		rate = Latch.kr(In.kr(~specFlatnessBus),trig);
		bufDur = BufDur.kr(bufnum);
		posLo = TRand.kr(0.0,0.5,In.kr(~hasFreqBus));
		bufSection = bufDur * posDif;
		pointer = posLo * bufDur +
		(Phasor.ar(trig, BufRateScale.kr(bufnum) / SampleRate.ir,posLo * bufDur,(posLo + posDif) * bufDur)
			+
			(TRand.kr(-0.5 * posDev, 0.5 * posDev, trig) * bufDur)).mod(bufSection);

		sig = TGrains.ar(numChannels,trig,bufnum,rate.clip(0.5,2.0).neg,pointer,grainDur,Latch.kr(LFNoise2.kr(40),trig),\amp.kr(0.8));
	},
]
);

(
SynthDef(\inPlayer,{
	var sig = SoundIn.ar(\inBus.kr);
	sig = BHiShelf.ar(sig,\filtFreqHi.kr(2000),\rsHi.kr(0.25),0);
	sig = BLowShelf.ar(sig,\filtFreqLo.kr(80),\rsLo.kr(0.25),0);
	sig = Compander.ar(sig,sig,\compThresh.kr(0.5),1,0.5,0.01,0.01);
	Out.ar(\analyserOut.kr,sig);
	sig = PanAz.ar(numChannels,sig,\pan.kr(0),1,2,orientation);
	Out.ar(\outBus.kr,sig * \amp.kr(1));

}).add;

SynthDef(\analyser, {
	var freq,hasFreq,density,meanIOI,varianceIOI;

	var sig = In.ar(\inBus.kr,1);

	var amp = Amplitude.kr(sig);
	var silence = DetectSilence.ar(sig + Impulse.ar(0),0.01);
	var chain = FFT(LocalBuf(\frames.kr(1024)),sig);
	var onsets = Onsets.kr(chain,\thresh.kr, \rcomplex);
	var centroid = SpecCentroid.kr(chain);
	var specFlatness = SpecFlatness.kr(chain);

	var time = Sweep.ar;
	var trig = Impulse.kr(\trigRate.kr(4));

	# density, meanIOI, varianceIOI = OnsetStatistics.kr(onsets,3.0);
	# freq, hasFreq = Pitch.kr(LPF.ar(sig,2000), ampThreshold: 0.01, median: 7);

	SendReply.kr(trig, '/analysis', [amp,silence,freq,hasFreq,onsets,centroid,specFlatness,density,meanIOI,varianceIOI,time]);

	Out.kr(\ampBus.kr,amp);
	Out.kr(\silenceBus.kr,silence);
	Out.kr(\freqBus.kr,freq);
	Out.kr(\hasFreqBus.kr,hasFreq);
	Out.kr(\onsetsBus.kr,onsets);
	Out.kr(\centroidBus.kr,centroid);
	Out.kr(\specFlatnessBus.kr,specFlatness);
	Out.kr(\densityBus.kr,density);
	Out.kr(\meanIOIBus.kr,meanIOI);
	Out.kr(\varianceIOIBus.kr,varianceIOI);

}).add;

SynthDef(\switcher,{
	var sig = In.ar(\inBus.kr,numChannels);
	Out.ar(\outBus.kr,sig);
}).add;

SynthDef(\globalOut,{
	var freq,hasFreq,density,meanIOI,varianceIOI;

	var in = In.ar(\inBus.kr,numChannels);
	var sig = Mix(in);

	var amp = Amplitude.kr(sig);
	var silence = DetectSilence.ar(sig + Impulse.ar(0),0.01);
	var chain = FFT(LocalBuf(\frames.kr(1024)),sig);
	var onsets = Onsets.kr(chain,\thresh.kr, \rcomplex);
	var centroid = SpecCentroid.kr(chain);
	var specFlatness = SpecFlatness.kr(chain);

	var time = Sweep.ar;
	var trig = Impulse.kr(\trigRate.kr(4));

	# freq, hasFreq = Pitch.kr(LPF.ar(sig,2000), ampThreshold: 0.01, median: 7);
	# density, meanIOI, varianceIOI = OnsetStatistics.kr(onsets,3.0);

	SendReply.kr(trig, '/globalAnalysis', [amp,silence,freq,hasFreq,onsets,centroid,specFlatness,density,meanIOI,varianceIOI,time]);

	in = Compander.ar(in,in,\compThresh.kr,1,0.5,0.01,0.01,\amp.kr(1));
	Out.ar(\outBus.kr,in);

}).add;

SynthDef(\recorder,{
	var sig = In.ar(\inBus.kr,1);

	RecordBuf.ar(sig,\bufnum.kr,loop:0, doneAction: 2);

}).add;

SynthDef(\reverb,{
	var sig = In.ar(\inBus.kr,1);
	sig = FreeVerb.ar(sig,1,100,\damp.kr(0.4));
	sig = BHiShelf.ar(sig,2250,1,-6); // could eventually allow this to be tuned in a GUI...
	sig = PanAz.ar(numChannels,sig,\pan.kr(0),\amp.kr(0.8),2,orientation);
	Out.ar(\outBus.kr,sig);

}).add;

SynthDef(\snowSines, {
	var rq = \rq.kr(0.5);
	var freq = \freq.kr;
	var env = EnvGen.kr(Env([0,1,0],[\atk.kr,\rls.kr]),\gate.kr(1),doneAction: 2);
	var sig = SinOsc.ar(freq)*BrownNoise.ar(0.5,0.5);
	sig = RLPF.ar(sig,freq * 1.5,rq,1 / rq.sqrt);         // weird amp function...I don't like it.
	sig = PanAz.ar(numChannels,sig,\pan.kr,\amp.kr * 0.7,2,orientation);
	Out.ar(\outBus.kr,sig * env);

}).add;

SynthDef(\screech,{
	var sig = SinOsc.ar(\freq.kr(80))*Trig.kr(\trig.kr(1),0.04);
	sig = CombC.ar(sig,0.04,0.04*LFNoise0.ar(50).abs,6.0,1);
	sig = Limiter.ar(sig,1.0);
	sig = PanAz.ar(numChannels,sig,\pan.kr(0),\amp.kr(0.8),2,orientation);
	sig = LeakDC.ar(sig);
	DetectSilence.ar(sig,doneAction:2);
	Out.ar(\outBus.kr(0),sig);

}).add;

SynthDef(\freezeBells,{
	var ramp = Line.ar(-1.0,-0.001,ExpRand(8.0,14.0),doneAction: 2);
	var sig = In.ar(\inBus.kr,1);
	var chain = FFT(LocalBuf(1024),sig);
	chain = PV_Freeze(chain,1);
	chain = PV_BrickWall(chain,ramp);
	sig = IFFT(chain)!2;
	sig = AllpassC.ar(sig,0.2,0.2,1.0);
	sig = SplayAz.ar(numChannels,sig * ramp.abs,ramp.abs.reciprocal/1000,\amp.kr(0.8),numChannels,0,orientation);
	sig = Out.ar(\outBus.kr,sig);

}).add;

SynthDef(\clicks,{
	var freq = \freq.kr;
	var ts = \ts.kr;

	var osc = SinOscFB.ar([freq,freq*1.005],\feedback.kr);
	var env = EnvGen.kr(Env.new([0.01,1,0.01],[0.05,0.5],\exp),1,timeScale:ts.clip(2,20),doneAction: 2);
	var pan = Rand(0.0,2.0);
	var sig = osc*osc+osc;
	sig = BLowPass.ar(sig,8000*env.lag(ts*0.8),env.reciprocal/4);
	sig = PanAz.ar(numChannels,(sig.sum)*env,Line.kr(pan,pan.neg,ts/4),\amp.kr(0.1),2,orientation);
	sig = LeakDC.ar(sig);
	Out.ar(\outBus.kr,sig);

}).add;

);

"multichannel transforms loaded".postln;

);
);