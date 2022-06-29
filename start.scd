

// must fix no silence synths in first ignore!
// should poll rate be faster?

// limit freeze bells

e.recIndex

e = EIDOLON([0,1],0,60 * 10,10)

e.sendBus

// start med hjerte, switch to snare, back to heart

Ndef(\input).inspect

// heartAmp == 0 when superballs start
// heartAmp == 1 when mallets start
Ndef(\input).set(\heartAmp,1)

Safety.disable
s.makeGui

s.plotTree
s.sendMsg("/n_free",1132)
e.recIndex

(
Ndef(\test,{
	var sig;
	var heart = SoundIn.ar(\heartIn.kr(0)) * 1;
	var drum = SoundIn.ar(\drumIn.kr(1)) * 0.5;

	// drum = BHiShelf.ar(drum,\dFreqHi.kr(3000),\rsHi.kr(0.5),0);
	// drum = BLowShelf.ar(drum,\dFreqLo.kr(80),\rsLo.kr(0.25),0);
	drum = Compander.ar(drum,drum,\compThresh.kr(0.5),1,1/3,0.01,0.1,1) * 1;

	heart = HPF.ar(heart,40);
	heart = Compander.ar(heart,HPF.ar(heart,80),0.125,1,1/8,0.01,0.1,8);
	heart = (heart * \hGain.kr(4)).tanh;
	heart = MidEQ.ar(heart,150,1,6);
	heart = Compander.ar(heart,heart,0.125,1,1/4,0.01,0.1,1);
	heart = LPF.ar(heart,150);
	heart = (heart * \hGain.kr(4)).tanh;
	heart = heart * -12.dbamp;

	sig = [heart,drum].sum;

	// Out.ar(\sendBus.kr,sig);
	sig = Pan2.ar(sig,\pan.kr(0),\amp.kr(1));
	Out.ar(\out.kr,sig);

}).play
)

