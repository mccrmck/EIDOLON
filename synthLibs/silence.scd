(
tesla: {
	var carfreq = \carFreq.kr(1.3);
	var mod = SinOscFB.ar(\modfreq.kr(8000) * Dust.ar(LFNoise0.kr(0.3).range(0.2,10)).lag,\modFB.kr(3));
	var car = LFTri.ar([carfreq,carfreq*1.05],pi,0.5,0.5)+mod;
	var sig = car*mod;
	sig = BHiPass4.ar(sig,100,2);
	sig = BLowPass4.ar(sig,\filt.kr(8000),\rq.kr(1));
	sig = LeakDC.ar(sig);
	sig = sig * \amp.kr(0.08);
},

shiftReg: {
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
	t = t * (0.5**(n-1)) - 1;
	t = Pan2.ar(t,Latch.kr(LFNoise2.kr(0.4).range(-0.8,0.8),Changed.kr(A2K.kr(t))),\amp.kr(0.1));
	t = LeakDC.ar(t);
},
)