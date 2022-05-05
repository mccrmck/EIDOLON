(
brokenRec: {
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

percShiftDelay: {
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

fftFreeze: {
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

shiftDelay: {
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
)