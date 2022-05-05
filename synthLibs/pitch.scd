(
ringMod: {
	var dev = TExpRand.kr(0.01,4000,In.kr(~controlBus[0]["onsetsBus"]));
	var gate = In.kr(~controlBus[0]["hasFreqBus"]);
	var sig = (In.ar(\inBus.kr,1))*gate;
	var mod = SinOsc.ar(In.kr(~controlBus[0]["freqBus"])*2*SinOsc.ar(dev).range(0.75,0.75.reciprocal));
	sig = sig * mod;
	sig = Pan2.ar(sig,LFNoise2.kr(0.2));
},

pitchShift: {
	var grainSize = 0.15,maxDev,sig;
	var	freqDev = Drand([7/8,8/7,8/9,9/8,9/10,10/9],inf);
	freqDev = Demand.kr(Dust.kr(In.kr(~controlBus[0]["specFlatnessBus"]) * 5),0,freqDev);
	maxDev = SinOsc.kr(In.kr(~controlBus[0]["varianceIOIBus"])).clip(0.01,0.05);
	sig = In.ar(\inBus.kr,1);
	sig = PitchShift.ar(sig,grainSize,freqDev,maxDev,grainSize);
	sig = Pan2.ar(sig,LFNoise2.kr(0.2));
},

bitz: {
	var rate = In.kr(~controlBus[0]["freqBus"]);
	var bits = In.kr(~controlBus[0]["specFlatnessBus"]);

	var sig = In.ar(\inBus.kr,1);
	sig = Decimator.ar(sig,SampleRate.ir * rate.explin(20,20000,0.05,0.2), 24 * bits.linlin(0,1.0,0.05,0.5));    //add limiter???
	sig = Pan2.ar(sig,LFNoise2.kr(0.2).range(-0.8,0.8),\amp.kr(0.3));
},
)