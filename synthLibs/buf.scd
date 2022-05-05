(
bufGlitch: {
	var bufnum = \bufnum.kr;
	var freq = (In.kr(~controlBus[0]["specFlatnessBus"])).clip(0.6,1.0);
	var bufFr = BufFrames.kr(bufnum)-1;
	var pointer = LFDNoise1.ar(freq).range(0,bufFr);
	var sig = BufRd.ar(1,bufnum,pointer,1);
	sig = Pan2.ar(sig,pointer.linlin(0,bufFr,-1.0,1.0))
},

bufStutter: {
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

bufAMRing: {
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

tGrains: {
	var sig, bufnum = \bufnum.kr;

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
)