(
ringMod: {
	var ctrlIn = In.kr(\ctrlIn.kr).lag(0.1);
	var trigIn = In.kr(\trigIn.kr);

	var dev = TExpRand.kr(0.1,20,trigIn).lag(1);
	var sig = In.ar(\inBus.kr);
	var mod = SinOsc.ar(ctrlIn.linexp(0,1,10,3000) * 2 * SinOsc.ar(dev).range(0.75,0.75.reciprocal));
	sig = sig * mod;
	sig = Pan2.ar(sig,LFNoise2.kr(0.2));
},

pitchShift: {
	var ctrlIn = In.kr(\ctrlIn.kr);
	var trigIn = In.kr(\trigIn.kr);
	var start = Impulse.kr(0);
	var grainSize = 1;
	var	freqDev = Latch.kr(ctrlIn.linexp(0,1,0.5,2),trigIn + start).lag(0.5);
	var	maxDev = Latch.kr(ctrlIn.linlin(0,1,0,grainSize),trigIn + start);
	var sig = In.ar(\inBus.kr);
	sig = PitchShift.ar(sig,grainSize,freqDev,maxDev,grainSize);
	sig = Pan2.ar(sig,LFNoise2.kr(0.2).range(-0.5,0.5));
},

bitz: {
	var ctrlIn = In.kr(\ctrlIn.kr).lag(1);
	var trigIn = In.kr(\trigIn.kr);         // not used??
	var sig = In.ar(\inBus.kr,1);
	sig = Decimator.ar(sig,SampleRate.ir * ctrlIn.linlin(0,1,0.05,0.2), 24 * ctrlIn.linlin(0,1,0.05,0.5));    //add limiter???
	sig = Limiter.ar(sig,1);
	sig = Pan2.ar(sig,LFNoise2.kr(0.2).range(-0.8,0.8),\amp.kr(0.8));
},

)