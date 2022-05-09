(
noise: {
	var ctrlIn0 = In.kr(\ctrlIn0.kr);
	var ctrlIn1 = In.kr(\ctrlIn1.kr);
	var trigIn = In.kr(\trigIn.kr);

	var sig = LFNoise0.ar(ctrlIn0.linexp(0,1,10,200));
	var toggle = ToggleFF.kr(trigIn) * 2 - 1;
	sig = CombC.ar(sig,0.2,ctrlIn1.linexp(0,1,200,60).reciprocal,ctrlIn0 * toggle);
	sig = (sig * \gain.kr(3)).fold2;
	sig = LeakDC.ar(sig);
	sig = Pan2.ar(sig,\pan.kr(0),\amp.kr(1));
},

shiftReg: {
	var ctrlIn0 = In.kr(\ctrlIn0.kr);
	var ctrlIn1 = In.kr(\ctrlIn1.kr);
	var trigIn = In.kr(\trigIn.kr);

	var freq = ctrlIn0.linexp(0,1,0.1,8);
	var bits = ctrlIn0.linlin(0,1,0.1,8);
	var sRate = ctrlIn1.linexp(0,1,12,1);
	var counter = TChoose.kr(trigIn,(0..6));
	var sr = SampleRate.ir/ sRate;
	var n = 12;                                            // bit resolution: bits.clip(12,24);
	var t= Phasor.ar(1,freq * ((2**n)/sr),0,((2**n)-1));

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
	t = Pan2.ar(t,0,\amp.kr(0.25));
	t = LeakDC.ar(t);
},
)