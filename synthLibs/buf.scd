(
bufGlitch: {
	var ctrlIn = In.kr(\ctrlIn.kr);
	var trigIn = In.kr(\trigIn.kr);            // this isn't being used...
	var bufnum = \bufnum.kr;

	var freq = ctrlIn.linexp(0,1,0.5,2);
	var bufFr = BufFrames.kr(bufnum)-1;
	var pointer = LFDNoise1.ar(freq).range(0,bufFr);
	var sig = BufRd.ar(1,bufnum,pointer,1);
	sig = Pan2.ar(sig,pointer.linlin(0,bufFr,-1.0,1.0))
},

bufStutter: {                                                // maybe clean this synth up a bit??
	var ctrlIn = In.kr(\ctrlIn.kr);
	var trigIn = In.kr(\trigIn.kr);
	var bufnum = \bufnum.kr;

	var rate = TExpRand.kr(0.7,1.1,trigIn);
	var speed = ctrlIn.linlin(0,1,1,6);
	var bufFr = BufFrames.kr(bufnum)-1;
	var trig = Impulse.kr(speed.lag(0.5));
	var pointer = Phasor.ar(0,0.05,0,bufFr);
	var rand = TIRand.kr(-1,1,trig);
	var sig = PlayBuf.ar(1,bufnum,rate,trig,pointer,loop: 1).lag(rate.reciprocal * 0.066); // what does this lag do?? does it help with clicks maybe?
	sig = LPF.ar(sig,6000);
	sig = Pan2.ar(sig,pointer.linlin(0,bufFr,rand.asFloat,rand.neg.asFloat),0.8);
},

bufAMRing: {
	var ctrlIn = In.kr(\ctrlIn.kr);
	var trigIn = In.kr(\trigIn.kr);
	var bufnum = \bufnum.kr;

	var ringfreq = Latch.kr(ctrlIn.linexp(0,1,10,500),trigIn);
	var car = BufRd.ar(1,bufnum,LFTri.ar(LFNoise2.kr(0.5).range(0.6,0.8)).range(0, BufFrames.kr(bufnum)));
	var mod = LFPulse.ar(LFNoise2.kr(2).range(1.4,14),0,LFNoise0.ar(4).range(0.3,0.8)).abs;
	var sig = car * mod.lag;
	sig = sig * SinOsc.ar(ringfreq);
	sig = BHiShelf.ar(sig,6000,0.5,-6);
	sig = Pan2.ar(sig,LFNoise2.kr(0.2));
},

tGrains: {
	var ctrlIn = In.kr(\ctrlIn.kr);
	var trigIn = In.kr(\trigIn.kr);
	var sig, bufnum = \bufnum.kr;

	var rate = ctrlIn.linexp(0,1,0.5,2.0);
	var bufDur = BufDur.kr(bufnum);
	var offset = Rand(0,bufDur);
	var pointer = Phasor.ar(0,1,0,bufDur);
	pointer = pointer + Latch.kr(PinkNoise.kr(ctrlIn.linlin(0,1,0.2,0.001)),trigIn);
	sig = TGrains.ar(2,trigIn,bufnum,BufRateScale.kr(bufnum) * rate.neg,pointer,TRand.kr(0.1,1.0,trigIn),Latch.kr(LFNoise2.kr(0.1),trigIn),\amp.kr(0.8));
},
)