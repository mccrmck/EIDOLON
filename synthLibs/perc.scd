(
brokenRec: {
	var ctrlIn = In.kr(\ctrlIn.kr);
	var trigIn = In.kr(\trigIn.kr);

	var sig = In.ar(\inBus.kr);
	var gate = Env.sine(0.1).ar(gate:trigIn);
	var rand = Latch.kr(ctrlIn.linlin(0,1,0.05,0.3),trigIn);
	sig = CombC.ar(sig * gate,0.4,rand,Select.kr(Trig1.kr(trigIn,rand-0.01),[inf,0]));
	sig = Pan2.ar(sig,LFNoise2.kr(0.2)) + Pan2.ar(DelayC.ar(sig,0.6,rand*7/5),LFNoise2.kr(0.2));
	sig * \amp.kr(0.7);
},

percShiftDelay: {
	var ctrlIn = In.kr(\ctrlIn.kr);
	var trigIn = In.kr(\trigIn.kr);

	var grainSize = 1.0,freq,hasFreq;
	var freqDev = ctrlIn.linexp(0,1,0.6,1.2);
	var maxDev = ctrlIn.linlin(0,1,0.3,0.8);
	var	sig = In.ar(\inBus.kr);

	sig = sig + LocalIn.ar(1);
	#freq, hasFreq = Pitch.kr(sig, ampThreshold: 0.05, median: 7);
	sig = sig * (1-hasFreq);
	sig = PitchShift.ar(sig,grainSize,freqDev,maxDev,TRand.kr(0.001,grainSize,trigIn));
	LocalOut.ar(sig * 0.7);
	sig = LeakDC.ar(sig);
	sig = Pan2.ar(sig,TRand.kr(-1.0,1.0,trigIn),\amp.kr(1.0));
},

fftFreeze: {
	var ctrlIn = In.kr(\ctrlIn.kr);
	var trigIn = In.kr(\trigIn.kr);
	var frames = TChoose.kr(trigIn,[512,2048,4096]);

	var	sig = In.ar(\inBus.kr);

	var trig = Trig.kr(trigIn,TRand.kr(0.3,0.5,trigIn));
	sig = FFT(LocalBuf(frames), sig);
	sig = PV_Freeze(sig,trig);
	sig = IFFT(sig);
	sig = Pan2.ar(sig * trig,TRand.kr(-1.0,1.0,trig),\amp.kr(1.0));
},

shiftDelay: {
	var ctrlIn = In.kr(\ctrlIn.kr);
	var trigIn = In.kr(\trigIn.kr);

	var speed = ctrlIn.linexp(0,1,0.05,7);

	var sig = In.ar(\inBus.kr);
	var mute = ToggleFF.kr(trigIn);

	var local = LocalIn.ar(2);
	sig = DelayC.ar( (sig * (1-mute)) + local,1.5,LFNoise1.ar(speed!2).range(0.2,ctrlIn.linexp(0,1,0.3,1.5)));
	LocalOut.ar(sig.reverse) * Select.kr(mute,[0.75,1]);
	sig = LeakDC.ar(sig);
	sig = Splay.ar(sig,0.5,\amp.kr(0.3));
},
)