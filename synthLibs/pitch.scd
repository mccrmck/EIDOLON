(
ringMod: {
	var ctrlIn = In.kr(\ctrlIn.kr);
	var trigIn = In.kr(\trigIn.kr);

	var dev = TExpRand.kr(0.1,20,trigIn);
	var sig = In.ar(\inBus.kr);
	var mod = SinOsc.ar(ctrlIn.linexp(0,1,10,3000) * 2 * SinOsc.ar(dev).range(0.75,0.75.reciprocal));
	sig = sig * mod;
	sig = Pan2.ar(sig,LFNoise2.kr(0.2));
},

pitchShift: {
	var ctrlIn = In.kr(\ctrlIn.kr);
	var trigIn = In.kr(\trigIn.kr);

	var grainSize = 0.15,maxDev,sig;
	var	freqDev = Drand([7/8,8/7,8/9,9/8,9/10,10/9],inf);
	freqDev = Demand.kr(trigIn,0,freqDev);
	maxDev = SinOsc.kr(ctrlIn).range(0.01,0.05);
	sig = In.ar(\inBus.kr);
	sig = PitchShift.ar(sig,grainSize,freqDev,maxDev,grainSize);
	sig = Pan2.ar(sig,LFNoise2.kr(0.2));
},

bitz: {
	var ctrlIn = In.kr(\ctrlIn.kr);
	var trigIn = In.kr(\trigIn.kr);

	var sig = In.ar(\inBus.kr,1);
	sig = Decimator.ar(sig,SampleRate.ir * ctrlIn.linlin(0,1,0.05,0.2), 24 * ctrlIn.linlin(0,1,0.05,0.5));    //add limiter???
	sig = Limiter.ar(sig,0.3);
	sig = Pan2.ar(sig,LFNoise2.kr(0.2).range(-0.8,0.8),\amp.kr(0.8));
},
)