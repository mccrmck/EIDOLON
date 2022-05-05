///////////////////////////////////////////////////////EIDOLON Stereo Synths//////////////////////////////////////////////////////////////////////
(
var numChannels = ~config[\numChannels];

(
~transforms = Dictionary[

	// use the event type syntax (brokenRecord: {function}) instead of Dictionaries within Dictionaries
	// check the help file for Event Type and NodeProxy to make sure it doesn't do some weird shit...

	// synths have to take busses as arguments!
	// normalize all synth args!!
	// need to also accomodate current_time...perhaps add this at the end!

	"densePerc" -> Dictionary[

		"brokenRecord" -> {
			var sig1;
			var sig = In.ar(\inBus.kr,1);
			var trig = In.kr(~controlBus[0]["onsetsBus"]) + In.kr(~controlBus[0]["hasFreqBus"]);
			var gate = EnvGen.ar(Env.sine(0.1),trig);
			var rand = In.kr(~controlBus[0]["silenceBus"]);
			rand = TExpRand.kr(0.05,0.3,rand);
			sig = CombC.ar(sig*gate,0.6,rand,Select.kr(Trig1.kr(trig,rand-0.01),[inf,0]));
			sig1 = DelayN.ar(sig,0.6,rand*7/5);
			sig = Pan2.ar(sig,LFNoise2.kr(0.2)) + Pan2.ar(sig1,LFNoise2.kr(0.2));
			sig * \amp.kr(0.7);
		},

		"percShiftDelay" -> {
			var grainSize=1.0,freq,hasFreq;
			var freqDev = In.kr(~controlBus[0]["varianceIOIBus"]).clip(0.6,1.2);
			var maxDev = In.kr(~controlBus[0]["specFlatnessBus"]).clip(0.3,0.8);
			var	sig = In.ar(\inBus.kr,1);

			sig = sig + LocalIn.ar(1);
			#freq, hasFreq = Pitch.kr(sig, ampThreshold: 0.05, median: 7);
			sig = sig*(1-hasFreq);
			sig = PitchShift.ar(sig,grainSize,freqDev,maxDev,grainSize);
			sig = LeakDC.ar(sig);
			LocalOut.ar(sig*0.7);
			sig = Pan2.ar(sig,TRand.kr(-1.0,1.0,1-hasFreq).lag(maxDev),\amp.kr(1.0));
		},

		"fftFreeze" -> {
			var chain;
			var frames=4096;

			var	sig = In.ar(\inBus.kr,1);
			var trig = In.kr(~controlBus[0]["onsetsBus"]) + In.kr(~controlBus[0]["hasFreqBus"]);
			trig = Trig.kr(trig,TRand.kr(0.3,0.5,trig));
			chain = FFT(LocalBuf(frames), sig, 0.5, 0, 1, frames);
			chain = PV_Freeze(chain,trig);
			sig = IFFT(chain);
			sig = Pan2.ar(sig*trig,TRand.kr(-1.0,1.0,trig),\amp.kr(1.0));
		},

		"shiftDelay" -> {
			var speed = In.kr(~controlBus[0]["specFlatnessBus"]).linexp(0.0,1.0,0.05,7);
			var delay = In.kr(~controlBus[0]["densityBus"]).linexp(0.0,12.0,0.3,1.5);
			var trig = In.kr(~controlBus[0]["silenceBus"]);

			var sig = In.ar(\inBus.kr,1);
			var mute = ToggleFF.kr(trig);

			var local = LocalIn.ar(2);
			sig = DelayC.ar((sig*(1-mute))+local,1.5,LFNoise1.ar(speed!2).range(0.2,delay));
			LocalOut.ar((sig.reverse)*Select.kr(mute,[0.75,1]));
			sig = LeakDC.ar(sig);
			sig = Splay.ar(sig,0.5,\amp.kr(0.3));
		},
	],

	/**************************/

	"pitchTrack" -> Dictionary
	[
		"ringMod" -> {
			var dev = TExpRand.kr(0.01,4000,In.kr(~controlBus[0]["onsetsBus"]));
			var gate = In.kr(~controlBus[0]["hasFreqBus"]);
			var sig = (In.ar(\inBus.kr,1))*gate;
			var mod = SinOsc.ar(In.kr(~controlBus[0]["freqBus"])*2*SinOsc.ar(dev).range(0.75,0.75.reciprocal));
			sig = sig*mod;
			sig = Pan2.ar(sig,LFNoise2.kr(0.2));
		},

		"pitchShift" -> {
			var grainSize=0.15,maxDev,sig;

			var	freqDev = Drand([7/8,8/7,8/9,9/8,9/10,10/9],inf);
			freqDev = Demand.kr(Dust.kr(In.kr(~controlBus[0]["specFlatnessBus"])*5),0,freqDev);
			maxDev = SinOsc.kr(In.kr(~controlBus[0]["varianceIOIBus"])).clip(0.01,0.05);
			sig = In.ar(\inBus.kr,1);
			sig = PitchShift.ar(sig,grainSize,freqDev,maxDev,grainSize);
			sig = Pan2.ar(sig,LFNoise2.kr(0.2));
		},

		"bitz" -> {
			var rate = In.kr(~controlBus[0]["freqBus"]);
			var bits = In.kr(~controlBus[0]["specFlatnessBus"]);

			var sig = In.ar(\inBus.kr,1);
			sig = Decimator.ar(sig,SampleRate.ir * rate.explin(20,20000,0.05,0.2), 24 * bits.linlin(0,1.0,0.05,0.5));    //add limiter???
			sig = Pan2.ar(sig,LFNoise2.kr(0.2).range(-0.8,0.8),\amp.kr(0.3));
		},
	],

	/**************************/

	"fillSilence" -> Dictionary[
		"tesla" -> {
			var carfreq = \carFreq.kr(1.3);

			var mod = SinOscFB.ar(\modfreq.kr(8000) * Dust.ar(LFNoise0.kr(0.3).range(0.2,10)).lag,\modFB.kr(3));
			var car = LFTri.ar([carfreq,carfreq*1.05],pi,0.5,0.5)+mod;
			var sig = car*mod;
			sig = BHiPass4.ar(sig,100,2);
			sig = BLowPass4.ar(sig,\filt.kr(8000),\rq.kr(1));
			sig = LeakDC.ar(sig);
			sig = sig * \amp.kr(0.08);
		},

		"bitShift" -> {
			var freq = In.kr(~controlBus[0]["specFlatnessBus"]).linlin(0,1.0,0.1,8.0);
			var counter = In.kr(~controlBus[0]["silenceBus"]).linlin(0,1.0,1,10);
			var sr = SampleRate.ir/ \sampleRate.kr(12);
			var n = 12;     // bit resolution: bits.clip(12,24);
			var t= Phasor.ar(1,freq*((2**n)/sr),0,((2**n)-1));

			counter = LFNoise0.kr(counter).range(0,7).floor;

			t = Select.ar(counter,[

				t*(((t>>64)|(t>>8))&(63&(t>>4))),
				t*(((t>>9)|(t>>13))&(25&(t>>6))),
				t*(((t>>5)|(t>>8)) & 63),
				t*(((t>>11)&(t>>8))&(123&(t>>3))),
				t*(t>>8*((t>>15)|(t>>8))&(20|(t>>19)*5>>t|(t>>3))),
				t*(t>>((t>>9)|(t>>8))&(63&(t>>4))),
				(t>>7|t|t>>6)*10+4*(t&t>>13|t>>6)
			]);

			t = t % (2**(n));
			t = t*(0.5**(n-1)) - 1; //scaling to -1, 1
			t = Pan2.ar(t,Latch.kr(LFNoise2.kr(0.4).range(-0.8,0.8),Changed.kr(A2K.kr(t))),\amp.kr(0.1));
			t = LeakDC.ar(t);
		},
	],
];

~bufTransforms = Dictionary[
	"bufGlitch" -> {
		var bufnum = \bufnum.kr;

		var freq = (In.kr(~controlBus[0]["specFlatnessBus"])).clip(0.6,1.0);
		var bufFr = BufFrames.kr(bufnum)-1;
		var pointer = LFDNoise1.ar(freq).range(0,bufFr);
		var sig = BufRd.ar(1,bufnum,pointer,1);
		sig = Pan2.ar(sig,pointer.linlin(0,bufFr,-1.0,1.0))

	},

	"bufStutter" -> {
		var bufnum = \bufnum.kr;

		var rate = TExpRand.kr(0.7,1.1,In.kr(~controlBus[0]["silenceBus"]));
		var speed = In.kr(~controlBus[0]["hasFreqBus"]).linlin(0,1.0,1.0,6.0);
		var bufFr = BufFrames.kr(bufnum)-1;
		var trig = Impulse.kr(speed.lag(0.5));
		var pointer = Phasor.ar(0,0.05,0,bufFr);
		var rand = TIRand.kr(-1,1,trig);
		var sig = PlayBuf.ar(1,bufnum,rate,trig,pointer,loop: 1).lag(rate.reciprocal*0.066);
		sig = BLowPass4.ar(sig,6000);
		sig = Pan2.ar(sig,pointer.linlin(0,bufFr,rand.asFloat,rand.neg.asFloat),0.8);
	},

	"bufAMRing" -> {
		var bufnum = \bufnum.kr;

		var ringfreq = Latch.kr(In.kr(~controlBus[0]["centroidBus"]),Impulse.kr(0.8));
		var modfreq = 7;
		var car = BufRd.ar(1,bufnum,LFTri.ar((BufDur.ir(bufnum).reciprocal)*LFNoise2.kr(0.5).range(0.6,0.8)).range(0, BufFrames.ir(bufnum)),1);
		var mod = LFPulse.ar(modfreq*LFNoise2.kr(2).range(0.2,2.0),0,LFNoise0.ar(4).range(0.3,0.8)).abs;
		var sig = car*mod.lag;
		sig = sig * SinOsc.ar(ringfreq);
		sig = BHiShelf.ar(sig,6000,0.5,-6);
		sig = Pan2.ar(sig,LFNoise2.kr(0.2));
	},

	"tGrainz" -> {
		var bufnum = \bufnum.kr;
		var sig;

		var rate = In.kr(~controlBus[0]["specFlatnessBus"]).linexp(0,1,0.5,2.0);
		var bufRate = BufRateScale.kr(bufnum);

		var trigRate = In.kr(~controlBus[0]["densityBus"]).linlin(12,1,0.3,12.0);
		var noise = trigRate.linexp(0.3,12.0,0.2,0.001);                // this must change when I normalize all bus inputs!!
		var trig = Impulse.kr(trigRate);

		var bufDur = BufDur.kr(bufnum);
		var offset = Rand(0,bufDur);
		var pointer = Phasor.kr(0,ControlDur.ir * 0.08,0,bufDur);
		pointer = pointer + Latch.kr(LFNoise1.kr(12,noise,offset),trig);

		sig = TGrains.ar(2,trig,bufnum,bufRate * rate.neg,(pointer % bufDur),1.5,Latch.kr(LFNoise2.kr(0.1),trig),\amp.kr(0.8));
	},
]
);

(
SynthDef(\inPlayer,{
	var sig = SoundIn.ar(\inBus.kr);

	sig = BHiShelf.ar(sig,\filtFreqHi.kr(3000),\rsHi.kr(0.5),0);
	sig = BLowShelf.ar(sig,\filtFreqLo.kr(80),\rsLo.kr(0.25),0);
	sig = Compander.ar(sig,sig,\compThresh.kr(0.5),1,0.5,0.01,0.01);

	Out.ar(\analyserOut.kr,sig);
	sig = Pan2.ar(sig,\pan.kr(0),\amp.kr(1));
	Out.ar(\outBus.kr,sig);

}).add;

SynthDef(\analyser, {
	var freq,hasFreq,density,meanIOI,varianceIOI;

	var sig = In.ar(\inBus.kr,1);

	var amp = Amplitude.kr(sig);
	var silence = DetectSilence.ar(sig + Impulse.ar(0),\silenceThresh.kr(0.01));
	var chain = FFT(LocalBuf(\frames.kr(1024)),sig);
	var onsets = Onsets.kr(chain,\onsetThresh.kr, \rcomplex);
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
	var in = In.ar(\inBus.kr,numChannels);
	var sig = FreeVerb.ar(HPF.ar(in,250),1,0.9,\damp.kr(0.7));

	sig = LPF.ar(sig,\lpfFreq.kr().clip(20,20000));
	sig = HPF.ar(sig,\hpfFreq.kr().clip(20,20000));

	sig = in + (sig * \mix.kr(0.1));

	Out.ar(\outBus.kr,sig);
}).add;

SynthDef(\globalOut,{
	var freq,hasFreq,density,meanIOI,varianceIOI;

	var in = In.ar(\inBus.kr,numChannels);
	var sig = Mix(in);

	var amp = Amplitude.kr(sig);
	var silence = DetectSilence.ar(sig + Impulse.ar(0),\silenceThresh.kr(0.01));
	var chain = FFT(LocalBuf(\frames.kr(1024)),sig);
	var onsets = Onsets.kr(chain,\onsetThresh.kr, \rcomplex);
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
	sig = HPF.ar(sig,350);
	sig = FreeVerb.ar(sig,1,0.9,\damp.kr(0.7));

	sig = LPF.ar(sig,\lpfFreq.kr().clip(20,20000));
	sig = HPF.ar(sig,\hpfFreq.kr().clip(20,20000));

	sig = Pan2.ar(sig,\pan.kr(0),\amp.kr(0.8) / 2); // amp scaling because this reverb is ridiculous....
	Out.ar(\outBus.kr,sig);

}).add;

SynthDef(\snowSines, {
	var rq = \rq.kr(0.5);
	var freq = \freq.kr;

	var env = EnvGen.kr(Env([0,1,0],[\atk.kr,\rls.kr]),\gate.kr(1),doneAction: 2);
	var sig = SinOsc.ar(freq)*BrownNoise.ar(0.5,0.5);
	sig = RLPF.ar(sig,freq*1.5,rq,1/rq.sqrt);  // weird amp function...I don't like it.
	sig = Pan2.ar(sig,\pan.kr(0),\amp.kr * 0.7);
	sig = sig * env;
	Out.ar(\outBus.kr,sig);

}).add;

SynthDef(\screech,{
	var sig = SinOsc.ar(\freq.kr(80)) * Trig.kr(\trig.kr(1),0.04);
	sig = CombC.ar(sig,0.04,0.04*LFNoise0.ar(50).abs,6.0,1);
	sig = Limiter.ar(sig,1.0);
	sig = Pan2.ar(sig,\pan.kr(0),\amp.kr(0.8));
	sig = LeakDC.ar(sig);
	DetectSilence.ar(sig,doneAction:2);
	Out.ar(\outBus.kr,sig);

}).add;

SynthDef(\freezeBells,{

	var ramp = Line.ar(-1.0,-0.001,ExpRand(8.0,14.0),doneAction: 2);
	var sig = In.ar(\inBus.kr,1);
	var chain = FFT(LocalBuf(1024),sig);
	chain = PV_Freeze(chain,1);
	chain = PV_BrickWall(chain,ramp);
	sig = IFFT(chain)!2;
	sig = AllpassC.ar(sig,0.2,0.2,1.0);
	sig = Splay.ar(sig * ramp.abs,ramp.abs.reciprocal / 1000,\amp.kr(0.8));
	sig = Out.ar(\outBus.kr,sig);

}).add;

SynthDef(\clicks,{
	var freq = \freq.kr;
	var ts = \ts.kr;

	var osc = SinOscFB.ar([freq,freq*1.005],\feedback.kr);
	var env = EnvGen.kr(Env.perc(),1,timeScale:ts,doneAction: 2);
	var pan = IRand(-1,1);
	var sig = osc*osc+osc;
	sig = LPF.ar(sig*env,8000);
	sig = LeakDC.ar(sig);
	sig = Balance2.ar(sig[0],sig[1],Line.kr(pan,pan.neg,ts),\amp.kr(0.1));
	Out.ar(\outBus.kr,sig);

}).add;

SynthDef(\tester,{

	var sig = In.ar(\inBus.kr,1);
	// var sig = SoundIn.ar(0);
	var silence = DetectSilence.ar(sig + Impulse.ar(0),\silenceThresh.kr(0.1));
	var chain = FFT(LocalBuf(\frames.kr(1024)),sig);
	var onsets = Onsets.kr(chain,\onsetThresh.kr, \rcomplex);

	SendReply.kr(Impulse.kr(20),'/silenceReply',[silence]);
	SendReply.kr(Impulse.kr(20),'/onsetReply',[onsets]);

}).add;

);

"Stereo transforms loaded".postln;
)