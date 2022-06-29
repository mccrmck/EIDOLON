(
brokenRec:{
	var ctrlIn = In.kr(\ctrlIn.kr);
	var trigIn = In.kr(\trigIn.kr) + Impulse.kr(0);
	var sig = In.ar(\inBus.kr);
	var gate = Env.sine(0.1).ar(gate:trigIn);
	var rand = Latch.kr(ctrlIn.linlin(0,1,0.005,0.15),trigIn);
	sig = CombC.ar(sig * gate,0.4,rand,Select.kr(Trig1.kr(trigIn,rand),[inf,0]));
	sig = Pan2.ar(sig,TRand.kr(-1,1,trigIn),\amp.kr(0.5));
},

percShiftDelay: {
	var ctrlIn = In.kr(\ctrlIn.kr).lag(0.5);
	var trigIn = In.kr(\trigIn.kr);

	var grainSize = 1.0,freq,hasFreq;
	var freqDev = ctrlIn.linexp(0,1,0.5,2);
	var maxDev = ctrlIn.linlin(0,1,0.1,0.8);
	var	sig = In.ar(\inBus.kr);
	#freq, hasFreq = Pitch.kr(sig, ampThreshold: 0.05, median: 7);
	sig = sig + PinkNoise.ar(0.001!2) + LocalIn.ar(2) * (1-hasFreq);
	sig = PitchShift.ar(sig,grainSize,freqDev,maxDev,TRand.kr(0.001,grainSize,trigIn));
	LocalOut.ar(sig.reverse * 0.7);
	sig = LeakDC.ar(sig);
	sig = Balance2.ar(sig[0],sig[1],LFNoise2.ar(0.1),\amp.kr(1));
},

combFreeze: {
	var ctrlIn = In.kr(\ctrlIn.kr).lag(0.2);
	var trigIn = In.kr(\trigIn.kr) + Impulse.kr(0);

	var	sig = In.ar(\inBus.kr);
	var trig = Trig.kr(trigIn,TExpRand.kr(0.3,0.8,trigIn));
	sig = FFT(LocalBuf(2048), sig);
	sig = PV_Freeze(sig,trig);
	sig = PV_RandComb(sig,ctrlIn.linexp(0,1,0.8,0.001),trigIn);
	sig = IFFT(sig);
	sig = Limiter.ar(sig);
	sig = Pan2.ar(sig * trig,TRand.kr(-0.8,0.8,trig),\amp.kr(1.0));
},

shiftDelay: {
	var ctrlIn = In.kr(\ctrlIn.kr).lag(1);
	var trigIn = In.kr(\trigIn.kr);
	var sig = In.ar(\inBus.kr);
	var speed = ctrlIn.linexp(0,1,0.05,3);
	var mute = ToggleFF.kr(trigIn);
	var local = LocalIn.ar(2);
	sig = sig * (1-mute) + local;
	sig = DelayC.ar(sig,1.5,LFNoise2.ar(speed!2).range(0.4,1.5));
	LocalOut.ar(sig.reverse * Select.kr(mute,[0.8,1]));
	sig = LeakDC.ar(sig);
	sig = Limiter.ar(sig);
	sig = Splay.ar(sig,0.5,\amp.kr(0.3));
},
)