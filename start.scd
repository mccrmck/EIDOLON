




// must fix no Buf synths in first ignore!
// double check synth rotation condition...does it make more sense now? If it ends one synth, maybe it should start the next one immediately?
// too much tacet - oscillating between support and tacet nearly...should maybe make things fade?
// should poll rate be faster?


// tacet doesn't always work!! both buf ugens and shiftReg
// shift delay doesn't work?
// prioritize buf synths!!
// linexp inf??
// check all the toggles...
// add long lags to ctrlIn signals?

e.recIndex

e = EIDOLON(0,0,60 * 7,10)


// start med hjerte, switch to snare, back to heart


Ndef(\input).inspect
Ndef(\input).set()
Ndef(\input).set(\heartMute,0,\drumMute,1)

s.plotTree


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