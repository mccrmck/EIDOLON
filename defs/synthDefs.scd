///////////////////////////////////////////////////////EIDOLON Stereo Synths//////////////////////////////////////////////////////////////////////
(
SynthDef(\simenIn,{
	var sig;
	var heart = SoundIn.ar(\heartIn.kr());
	var drum = SoundIn.ar(\drumIn.kr()) * 0.5;

	// drum = BHiShelf.ar(drum,\dFreqHi.kr(3000),\rsHi.kr(0.5),0);
	// drum = BLowShelf.ar(drum,\dFreqLo.kr(80),\rsLo.kr(0.25),0);
	drum = Compander.ar(drum,drum,\compThresh.kr(0.5),1,1/3,0.01,0.1,1) * \drumMute.kr(0);

	heart = HPF.ar(heart,40);
	heart = Compander.ar(heart,HPF.ar(heart,80),0.125,1,1/8,0.01,0.1,8);
	heart = (heart * \hGain.kr(4)).tanh;
	heart = MidEQ.ar(heart,150,1,6);
	heart = Compander.ar(heart,heart,0.125,1,1/4,0.01,0.1,1);
	heart = LPF.ar(heart,150);
	heart = (heart * \hGain.kr(4)).tanh;
	heart = heart * -12.dbamp * \heartMute.kr(1);

	sig = [heart,drum].sum;

	Out.ar(\sendBus.kr,sig);
	sig = Pan2.ar(sig,\pan.kr(0),\amp.kr(1));
	Out.ar(\out.kr,sig);

}).add;

SynthDef(\eidolonIn,{
	var sig = SoundIn.ar(\inBus.kr);
	sig = BHiShelf.ar(sig,\fFreqHi.kr(10000),\rsHi.kr(1),0);
	sig = BLowShelf.ar(sig,\fFreqLo.kr(80),\rsLo.kr(1),0);
	sig = Compander.ar(sig,sig,\compThresh.kr(0.5),1,0.5,0.01,0.1,2);

	Out.ar(\sendBus.kr,sig);
	sig = Pan2.ar(sig,\pan.kr(0),\amp.kr(1));
	Out.ar(\out.kr,sig);

}).add;

SynthDef(\analyser, {
	var density,meanIOI,varianceIOI,freq,hasFreq,specs;

	var sig = In.ar(\inBus.kr,1);
	var amp = Amplitude.kr(sig);
	var silence = DetectSilence.ar(sig + Impulse.ar(0),\silenceThresh.kr(0.01));
	var chain = FFT(LocalBuf(\frames.kr(1024)),sig);
	var onsets = Onsets.kr(chain,\onsetThresh.kr(0.2), \rcomplex);
	var centroid = SpecCentroid.kr(chain);
	var specFlatness = SpecFlatness.kr(chain);

	var time = Sweep.ar(\resetTime.tr);
	var trigRate = \trigRate.kr(4);

	# density, meanIOI, varianceIOI = OnsetStatistics.kr(onsets,2);
	# freq, hasFreq = Pitch.kr(LPF.ar(sig,3000),minFreq: 20,maxFreq: 5000, ampThreshold: 0.02, median: 7);

	specs = [amp,silence,onsets,centroid.explin(20,20000,0,1),specFlatness,freq.explin(20,5000,0.0,1.0),hasFreq,density.linlin(0,20,0,1),meanIOI.clip(0,1),varianceIOI.clip(0,1),time];
	SendReply.kr(Impulse.kr(trigRate), '/analysis', specs);
	Out.kr(\analBus.kr(0),specs);                                                // Must test...also check if DetectSilence.ar needs A2K?

}).add;

SynthDef(\recorder,{
	var sig = In.ar(\inBus.kr);
	sig = Compander.ar(sig,sig,0.5,1,1/4,0.01,0.1,3);
	RecordBuf.ar(sig,\bufnum.kr,loop:0, doneAction: 2);
}).add;

SynthDef(\monoInVerb,{
	var sig = In.ar(\inBus.kr);
	sig = HPF.ar(sig,350);
	sig = FreeVerb.ar(sig,1,0.9,\damp.kr(0.9));
	sig = LPF.ar(sig,\lpfFreq.kr(12000));
	sig = HPF.ar(sig,\hpfFreq.kr(250));
	sig = Pan2.ar(sig,\pan.kr(0),\amp.kr(0.8));
	Out.ar(\out.kr,sig);
}).add;

SynthDef(\outWithVerb,{
	var in = In.ar(\inBus.kr,2);
	var sig = HPF.ar(in,350);
	in = Compander.ar(in,sig,\compThresh.kr(0.5),1,0.5,0.01,0.1,2);
	sig = FreeVerb.ar(sig.sum,1,0.9,\damp.kr(0.9));
	sig = LPF.ar(sig,\lpfFreq.kr(12000));
	sig = HPF.ar(sig,\hpfFreq.kr(250));

	sig = (sig * \verbMix.kr(0.1)) + in;
	sig = HPFSide.ar(sig,40);
	sig = Balance2.ar(sig[0],sig[1],\pan.kr(0),\amp.kr(0.8));
	Out.ar(\out.kr,sig);

}).add;

// oneShots

SynthDef(\snowSines, {
	var rq = \rq.kr(0.5);
	var freq = \freq.kr;

	var sig = SinOsc.ar(freq) * BrownNoise.ar(0.5,0.5);
	sig = RLPF.ar(sig,freq * 1.5,rq,1/rq.sqrt);               // weird amp function...I don't like it.
	sig = Pan2.ar(sig,\pan.kr(0),\amp.kr * 0.7);
	sig = sig * Env([0,1,0],[\atk.kr,\rls.kr]).kr(2,\gate.kr(1));
	Out.ar(\out.kr,sig);

}).add;

SynthDef(\screech,{
	var sig = SinOsc.ar(\freq.kr(80)) * Trig.kr(\trig.kr(1),0.04);
	sig = CombC.ar(sig,0.04,0.04 * LFNoise0.ar(50).abs,6.0,1);
	sig = Limiter.ar(sig,1.0);
	sig = LeakDC.ar(sig);
	sig = Pan2.ar(sig,\pan.kr(0),\amp.kr(0.8));
	DetectSilence.ar(sig,doneAction:2);
	Out.ar(\out.kr,sig);

}).add;

SynthDef(\freezeBells,{
	var ramp = Line.ar(-1.0,-0.001,ExpRand(8.0,14.0),doneAction: 2);
	var sig = In.ar(\inBus.kr);
	sig = FFT(LocalBuf(1024),sig);
	sig = PV_Freeze(sig,1);
	sig = PV_BrickWall(sig,ramp);
	sig = IFFT(sig)!2;
	sig = AllpassC.ar(sig,0.2,0.2,1.0);
	sig = Splay.ar(sig * ramp.abs,ramp.abs.reciprocal / 1000,\amp.kr(0.8));
	Out.ar(\out.kr,sig);

}).add;

SynthDef(\clicks,{
	var freq = \freq.kr;
	var ts = \ts.kr;

	var osc = SinOscFB.ar([freq,freq * 1.005],\feedback.kr);
	var env = EnvGen.kr(Env.perc(),1,timeScale:ts,doneAction: 2);
	var pan = IRand(-1,1);
	var sig = osc*osc+osc;
	sig = LPF.ar(sig*env,8000);
	sig = LeakDC.ar(sig);
	sig = Balance2.ar(sig[0],sig[1],Line.kr(pan,pan.neg,ts),\amp.kr(0.1));
	Out.ar(\out.kr,sig);

}).add;

SynthDef(\noiseBurst,{
	var sig = PinkNoise.ar(1!2);
	sig = sig * Env.perc(0.01,0.6).kr(2);
	sig = HPFSide.ar(sig,40);
	sig = LeakDC.ar(sig);
	sig = Balance2.ar(sig[0],sig[1],\pan.kr(0),\amp.kr(1));
	Out.ar(\out.kr,sig);
}).add;

)