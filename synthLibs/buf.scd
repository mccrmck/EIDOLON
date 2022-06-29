(
bufGlitch: {
	var ctrlIn = In.kr(\ctrlIn.kr);
	var trigIn = In.kr(\trigIn.kr);            // this isn't being used...
	var bufnum = \bufnum.kr;

	var freq = ctrlIn.linlin(0,1,0.3,1.2);
	var bufFr = BufFrames.kr(bufnum)-1;
	var pointer = LFDNoise1.ar(freq).range(0,bufFr);
	var sig = BufRd.ar(1,bufnum,pointer,1);
	sig = Pan2.ar(sig,pointer.linlin(0,bufFr,-1.0,1.0))
},

bufStutter: {
	var ctrlIn = In.kr(\ctrlIn.kr).lag(1);
	var trigIn = In.kr(\trigIn.kr);
	var bufnum = \bufnum.kr;

	var bufFrames = BufFrames.kr(bufnum);
	var rate = TRand.kr(0.5,1.4,trigIn);
	var speed = ctrlIn.linlin(0,1,2,20);
	var trig = Impulse.kr(speed);
	var offset = TRand.kr(0,bufFrames,trigIn);
	var frontBack = TChoose.kr(trigIn,[-1,1]);
	var sig = PlayBuf.ar(1,bufnum,rate * frontBack,trig,offset,loop: 1);
	sig = sig * Env.perc(0.01,speed.reciprocal-0.01,1,4).kr(gate:trig);
	sig = Pan2.ar(sig,0,\amp.kr(0.5));
},

bufAMRing: {
	var ctrlIn = In.kr(\ctrlIn.kr).lag(0.5);
	var trigIn = In.kr(\trigIn.kr);
	var bufnum = \bufnum.kr;

	var ringfreq = Latch.kr(ctrlIn.linexp(0,1,4,300),trigIn + Impulse.kr(0));
	var pointer = LFTri.ar(LFNoise2.kr(0.2).range(0.25,3));
	var car = BufRd.ar(1,bufnum,pointer.range(0, BufFrames.kr(bufnum)),4);
	var mod = LFPulse.ar(LFNoise2.kr(ctrlIn).range(1.4,14),0,LFNoise0.kr(4).range(0.5,0.8));
	var sig = car * mod.lag;
	sig = sig * SinOsc.ar(ringfreq);
	sig = LPF.ar(sig,6000);
	sig = Pan2.ar(sig,pointer * 0.5,\amp.kr(1));
},

tGrains: {
	var ctrlIn = In.kr(\ctrlIn.kr).lag(2);
	var trigIn = In.kr(\trigIn.kr);
	var sig, bufnum = \bufnum.kr;

	var trigRate = ctrlIn.linexp(0,1,0.4,20);
	var trig = Impulse.kr(trigRate);
	var rate = TRand.kr(0.3,1.6,trigIn);
	var bufDur = BufDur.kr(bufnum);
	var pointer = TRand.kr(0,bufDur,trigIn);
	var noise = PinkNoise.kr(ctrlIn.linexp(0,1,0.4,0.003));
	var grainDur = 1.5;
	sig = TGrains.ar(2,trig,bufnum,BufRateScale.kr(bufnum) * rate.neg,pointer + noise,grainDur,LFNoise2.kr(ctrlIn.linexp(0,1,0.4,0.1),0.6),\amp.kr(0.8));
},
)