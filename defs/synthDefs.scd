///////////////////////////////////////////////////////EIDOLON Stereo Synths//////////////////////////////////////////////////////////////////////
(
SynthDef(\inSimen,{
	var sig;
	var heart = SoundIn.ar(\inBus.kr);
	var drum  = SoundIn.ar(\inBus.kr);

	drum = BHiShelf.ar(drum,\dFreqHi.kr(3000),\rsHi.kr(0.5),0);
	drum = BLowShelf.ar(drum,\dFreqLo.kr(80),\rsLo.kr(0.25),0);
	drum = Compander.ar(drum,drum,\compThresh.kr(0.5),1,1/3,0.01,0.1);

	heart = (heart * \hGain.kr(1)).tanh;
	heart = BPF.ar(heart,\hFreq.kr(80),\rq.kr(0.5));
	heart = Compander.ar(heart,heart,\compThresh.kr(0.5),1,1/4,0.01,0.1,);

	sig = [heart,drum].sum;

	Out.ar(\sendBus.kr,sig);
	sig = Pan2.ar(sig,\pan.kr(0),\amp.kr(1));
	Out.ar(\out.kr,sig);

}).add;

SynthDef(\inPlayer,{
	var sig = SoundIn.ar(\inBus.kr);
	sig = BHiShelf.ar(sig,\fFreqHi.kr(3000),\rsHi.kr(0.5),0);
	sig = BLowShelf.ar(sig,\fFreqLo.kr(80),\rsLo.kr(0.25),0);
	sig = Compander.ar(sig,sig,\compThresh.kr(0.5),1,0.5,0.01,0.11);

	Out.ar(\sendBus.kr,sig);
	sig = Pan2.ar(sig,\pan.kr(0),\amp.kr(1));
	Out.ar(\out.kr,sig);

}).add;

SynthDef(\analyser, {
	var freq,hasFreq,density,meanIOI,varianceIOI;

	var sig = In.ar(\inBus.kr,1);
	var amp = Amplitude.kr(sig);
	var silence = DetectSilence.ar(sig + Impulse.ar(0),\silenceThresh.kr(0.01));
	var chain = FFT(LocalBuf(\frames.kr(1024)),sig);
	var onsets = Onsets.kr(chain,\onsetThresh.kr(0.2), \rcomplex);
	var centroid = SpecCentroid.kr(chain);
	var specFlatness = SpecFlatness.kr(chain);

	var time = Sweep.ar;
	var trigRate = \trigRate.kr(4);

	# density, meanIOI, varianceIOI = OnsetStatistics.kr(onsets,trigRate * 2);   // scaled to trigRate == 2 seconds...or?
	# freq, hasFreq = Pitch.kr(LPF.ar(sig,3000),minFreq: 20,maxFreq: 5000, ampThreshold: 0.02, median: 7);

	specs = [amp,silence,onsets,centroid,specFlatness,freq.explin(20,5000,0.0,1.0),hasFreq,density,meanIOI,varianceIOI];
	SendReply.kr(Impulse.kr(trigRate), '/analysis', specs);
	Out.kr(\analBus.kr(0),specs);                                                // Must test...also check if DetectSilence.ar needs A2K?

}).add;

/*

// what do we do here, hmmmmm?

SynthDef(\switcher,{
var in = In.ar(\inBus.kr,2);
var sig = FreeVerb.ar(HPF.ar(in,250),1,0.9,\damp.kr(0.7));

sig = LPF.ar(sig,\lpfFreq.kr().clip(20,20000));
sig = HPF.ar(sig,\hpfFreq.kr().clip(20,20000));

sig = in + (sig * \mix.kr(0.1));

Out.ar(\out.kr,sig);
}).add;

SynthDef(\globalOut,{
var freq,hasFreq,density,meanIOI,varianceIOI;

var in = In.ar(\inBus.kr,2);
var sig = Mix(in);

var amp = Amplitude.kr(sig);
var silence = DetectSilence.ar(sig + Impulse.ar(0),\silenceThresh.kr(0.01));
var chain = FFT(LocalBuf(\frames.kr(1024)),sig);
var onsets = Onsets.kr(chain,\onsetThresh.kr, \rcomplex);
var centroid = SpecCentroid.kr(chain);
var specFlatness = SpecFlatness.kr(chain);

var time = Sweep.ar;
var trig = Impulse.kr(\trigRate.kr(4));

# freq, hasFreq = Pitch.kr(LPF.ar(sig,2000), ampThreshold: 0.01, median: 7);
# density, meanIOI, varianceIOI = OnsetStatistics.kr(onsets,3.0);

SendReply.kr(trig, '/globalAnalysis', [amp,silence,freq,hasFreq,onsets,centroid,specFlatness,density,meanIOI,varianceIOI,time]);

in = Compander.ar(in,in,\compThresh.kr,1,0.5,0.01,0.01,\amp.kr(1));
Out.ar(\out.kr,in);

}).add;

*/

SynthDef(\recorder,{
	var sig = In.ar(\inBus.kr);
	sig = Compander.ar(sig,sig,0.5,1,1/4,0.01,0.1,3);
	RecordBuf.ar(sig,\bufnum.kr, doneAction: 2);
}).add;

SynthDef(\reverb,{
	var sig = In.ar(\inBus.kr);
	sig = HPF.ar(sig,350);
	sig = FreeVerb.ar(sig,1,0.9,\damp.kr(0.7));

	sig = LPF.ar(sig,\lpfFreq.kr().linexp(0,1,20,20000));
	sig = HPF.ar(sig,\hpfFreq.kr().linexp(0,1,20,20000));

	sig = Pan2.ar(sig,\pan.kr(0),\amp.kr(0.8) / 2); // amp scaling because this reverb is ridiculous....
	Out.ar(\out.kr,sig);

}).add;

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
	sig = IFFT(chain)!2;
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

SynthDef(\tester,{
	var sig = In.ar(\inBus.kr);
	var silence = DetectSilence.ar(sig + Impulse.ar(0),\silenceThresh.kr(0.1));
	var chain = FFT(LocalBuf(\frames.kr(1024)),sig);
	var onsets = Onsets.kr(chain,\onsetThresh.kr(0.2), \rcomplex);

	SendReply.kr(Impulse.kr(20),'/calibrate',[silence, onsets]);

}).add;

"Stereo transforms loaded".postln;
)