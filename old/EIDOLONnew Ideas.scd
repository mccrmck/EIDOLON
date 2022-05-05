/*
determining states bug:

if the "first meeting should be carte blanche (therefore state = "ignore")"" thing (line 76) is shorter than the 3 minute state shift
thing (line 79), the length of the ignore time is ignored and it is overwritten to the 3 minutes state thing.

For now, I'll hardcode something, but I must find a better solution for this...

I guess this will all change when I figure out how to change the states more dynamically! :)


~density - how does it relate to SendReply trigRate? Should it relate??
right now OnsetStatistics is just hardcoded with a 3 second window...

Eventually make a SynthDef factory in the style of Mads, wrapping the synth functions in a Pan function (which sits in a library somewhere)

TO ADD:

-some sort of wrap/clip/fold distortion?

*/

// November 18(19?) Test Results/thoughts
// Opening section too long/monotonous (could be solved with time as an argument?)
// slow-panned sound was interesting..consult video
// visual representation: each synth and Ndef also spawns a (algorithmic) visual element
// can EIDOLON make formal decisions?
// GUI -> reverb vol doesn't affect verb unless value is changed...is \Reverb.play missing from somewhere?


// normalize all synthdef args/inputs and bus output
// get rid of the dB stuff -> go to amp!

///////////////////PLUTA'S PROCESSES...AND MORE//////////////












e = EIDOLON([0,1],0,60 * 10)

e.calibrate
e.play
e.reset









//spectralDelay...
PV_BinDelay

(
SynthDef("resonNoise2_mod", {
	arg inBus, outBus=0, transferBus=0, noiseVol=0.1, inOutVol=0.1, centerFreq=1000, lfoFreq=0.01, rq = 0.1, onOff=1, gate=1, pauseGate=1;
	var env, in, noiseOut, inOut, pauseEnv, freq;

	in = SoundIn.ar(0);
	freq = max(centerFreq+SinOsc.ar(lfoFreq, 0, centerFreq*0.8), 40);
	inOut = Resonz.ar(in, freq, rq);
	noiseOut = Resonz.ar(WhiteNoise.ar(1), freq, rq);
	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	noiseOut = Pan2.ar(noiseOut, LFNoise2.kr(lfoFreq+5/20));
	Out.ar(transferBus, inOut*LagUD.kr(onOff, 0.1, 1)*env*pauseEnv*inOutVol);
	Out.ar(outBus, noiseOut*LagUD.kr(onOff, 0.1, 1)*env*pauseEnv*noiseVol);
}).add;
)

x = Synth("resonNoise2_mod")
x.set(\centerFreq,800,\noiseVol,0.7,\inOutVol,0.6,\lfoFreq,0.01)

( //explore a similar idea with Decimator maybe?
SynthDef("noiseGliss2_mod", {
	arg inBus, outBus=0, pulseRate=400, shift=2, vol=1, gate = 1, pauseGate = 1;
	var in, out0, env, pauseEnv;

	pauseEnv = EnvGen.kr(Env.asr(0.01,1,0.01), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0.01,1,0.01), gate, doneAction:2);

	in = SoundIn.ar(0);

	out0 = PitchShift.ar(in, 0.2, shift);

	out0 = Latch.ar(out0, Impulse.ar(LFNoise0.kr(0.1).range(1000, 5000)));//downsampled

	out0 = out0 * Trig1.ar(Dust.kr(LFNoise0.kr(0.2).range(pulseRate, pulseRate*1.5)), LFNoise0.kr(0.3).range(0.025, 0.05)).lag(0.001);

	out0 = Pan2.ar(out0, SinOsc.ar(LFNoise0.kr(0.2).range(0.25, 1), Rand(0, 2pi)));

	Out.ar(outBus, out0*vol*pauseEnv*env);
}).add;
)

( //must investigate another time
SynthDef("cycleGripper_mod", {
	arg inBus, outBus=0, trigRateDust=0, trigRateImpulse=1, mode=0, inDelay = 0.02, t_trig = 0, gate = 1, pauseGate = 1;
	var trig, div0, div1, switch0, switch1, source, local, delay, delayTime;
	var triga, div0a, div1a, switch0a, switch1a, env, pauseEnv;

	env = EnvGen.kr(Env.asr(0.01,1,0.01), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0.01,1,0.01), pauseGate, doneAction:1);

	trig = Dust.kr(trigRateDust) + Impulse.kr(trigRateImpulse);

	div0 = PulseDivider.kr(trig, 2, 0);
	div1 = PulseDivider.kr(trig, 2, 1);
	switch0 = SetResetFF.kr(div0,div1);
	switch1 = SetResetFF.kr(div1,div0);

	div0a = Trig.kr(t_trig, 0.01);
	div1a = Trig.kr(TDelay.kr(t_trig, inDelay), 0.01);
	switch0a = SetResetFF.kr(div0a,div1a);
	switch1a = SetResetFF.kr(div1a,div0a);

	switch0 = Select.kr(mode, [switch0, switch0a, 1]);
	switch1 = Select.kr(mode, [switch1, switch1a, 0]);

	source = SoundIn.ar([0,1]);

	delayTime = Select.kr(mode, [TRand.kr(64/44100, 1024/44100, trig), inDelay, inDelay]);

	delay = DelayN.ar(LocalIn.ar(2), 8192/44100, delayTime);

	delay = Compander.ar((switch1*delay), (switch1*delay), 1, 1, 0.5, 0.01, 0.01).distort.clip2(0.8);
	//delay = (delay+PitchShift.ar(delay, 0.02, TRand.kr(0.9, 1.1, switch1), 0.01, 0));

	local = Mix.new([(switch0*source),delay]);

	LocalOut.ar(local.reverse*1.2);

	Out.ar(outBus, local*env*pauseEnv);
}).add;
)

// resonating filter that skips along harmonic series of fundamental/detected pitch -> use .nthPrime, prevPrime, nextPrime
// PV_BrickWall or PV_BinRange or PV_BinGap that skips around, cutting out parts of spectrum
// some sort of modulating comb filter - phaser?
//babbling brook filter - on live input???

~bell = Buffer.read(s,"/Users/mikemccormick/Desktop/GHOST samples/mono/05-CLOCHEC3.aif")
~breath = Buffer.readChannel(s,"/Users/mikemccormick/Desktop/GHOST samples/mono/Anders_sax 34 copy.wav",channels: 0);
~voice = Buffer.read(s,"/Users/mikemccormick/Desktop/GHOST samples/mono/speaker-5 copy.wav");
~sustain = Buffer.read(s,"/Users/mikemccormick/Desktop/GHOST samples/mono/throat copy.wav");
~five = Buffer.readChannel(s,"/Users/mikemccormick/Desktop/GHOST samples/mono/five copy.wav",channels: 0)

(
SynthDef(\flanger, {
	arg out=0, in=0, delay=0.1, depth=0.08, rate=0.06, fdbk=0.0, decay=0.0;
	var input, maxdelay, maxrate, dsig, mixed, local;

	maxdelay = 0.013;
	maxrate = 10.0;
	input = SoundIn.ar(0);
	local = LocalIn.ar(1);
	dsig = AllpassL.ar( // the delay (you could use AllpassC (put 0 in decay))
		input + (local * fdbk),
		maxdelay * 2,
		LFPar.kr( // very similar to SinOsc (try to replace it) - Even use LFTri
			rate * maxrate,
			0,
			depth * maxdelay,
			delay * maxdelay),
		decay);
	mixed = input + dsig;
	LocalOut.ar(mixed);
	Out.ar([out, out+1], mixed);
}).add;
)

Synth(\flanger)

//
SynthDef(\chorus, {
	arg inbus=10, outbus=0, predelay=0.08, speed=0.05, depth=0.1, ph_diff=0.5;
	var in, sig, modulators, numDelays = 12;

	in = SoundIn.ar(0);
	modulators = Array.fill(numDelays, {arg i;
		������	LFPar.kr(speed * rrand(0.94, 1.06), ph_diff * i, depth, predelay);});�
	sig = DelayC.ar(in, 0.5, modulators);��
	sig = sig.sum; //Mix(sig);
	Out.ar(outbus, sig!2); // output in stereo

}).load(s)

Synth(\chorus)

//tweak this!!! Change the reverb for sure...maybe this can have RandComb or some other FFT stuff?
(
// for fun: a noisegater with a bit of reverb (controlled by mouseY)
// better use headphones - danger of feedback!
{
	var in, compander;
	var predelay=0.048, combdecay=3.7, allpassdecay=0.21, revVol=0.21;
	in = SoundIn.ar(0);
	compander = Compander.ar(in, in, MouseX.kr(0.005, 1, 1), 10, 1, 0.01, 0.01);
	z = DelayN.ar(compander, 0.1, predelay);
	y = Mix.ar(Array.fill(7,{ CombL.ar(z, 0.05, rrand(0.03, 0.05), MouseY.kr(1,20, 1)) }));
	6.do({ y = AllpassN.ar(y, 0.050, rrand(0.03, 0.05), allpassdecay) });
	y!2
}.play
)

//brings up all quiet sounds, removes loud ones...
(
// sustainer - Audio In
{
	var in, compander;
	in = SoundIn.ar(0);
	compander = Compander.ar(in,in,MouseX.kr(0.001, 1, 1), 0.1, 1, 0.01, 0.01);
	compander ! 2 // stereo
}.play
)

(
Ndef(\randCombDelay,{
	arg inBus=0,dustTrig,impulseTrig,t_trig,amp=0.7;
	var in,chain,frames=4096,wipe=0.91,trig,sig;

	trig = Dust.kr(dustTrig) + Impulse.kr(impulseTrig) + t_trig;
	in = SoundIn.ar(inBus);
	in = DelayC.ar(in,3.0,3.0*LFNoise2.kr(0.2).range(0.25,1.0));
	chain = FFT(LocalBuf(frames),in);
	chain = PV_RandComb(chain,wipe,trig);
	sig = IFFT(chain);
	sig = AllpassC.ar(sig,0.5,0.5,1.5);
	sig = Pan2.ar(sig,Latch.kr(LFNoise2.kr(0.3),trig),amp);

}).play;
)

Ndef(\randCombDelay).fadeTime = 3
Ndef(\randCombDelay).xset(\dustTrig,0,\impulseTrig,0,\t_trig,1)

(
Ndef(\twinkle,{ //freq can be controlled by tap tempos and also a Trand
	arg inBus,freq=0.1,amp=0.8;
	var sig,bufnum;

	sig = SoundIn.ar(inBus);
	sig = Ringz.ar(sig,LFNoise0.ar(freq+(0.1,0.2..0.8)).range(40,3000),2.0,0.1);
	sig = Splay.ar(sig.scramble,1,amp*0.1);

}).play
)

Ndef(\twinkle).clear

b = ~voice

(
x = { var trig, rate, framesInBuffer;
	rate = XLine.ar(0.1,200,20);
	trig = Impulse.ar(rate);
	framesInBuffer = BufFrames.kr(b.bufnum);
	x = Phasor.ar(trig, BufRateScale.kr(b.bufnum), 0, framesInBuffer,
		[framesInBuffer/(LFNoise0.kr(8)), MouseY.kr(0, framesInBuffer)]);
	BufRd.ar(2, b.bufnum, x);
}.play;
)


/* Notes from Goodbye Intuition workshop */


// if buffers == 0 and recent_silence == 0, {sythesis}, or prioritize this for {state == ignore}

// motion tracker (armband)can be used to signal ending of performance

// more sampled/transformed material/synthdefs w/ unique spectromorphologies that are predictable
// so as to be able to decide if they are "supporting" or "contrasting"

// time as development argument -> SUPER IMPORTANT!!! PRIORITY TASK, especially when developing new synths
// this can be a variable - something that can be changed in the GUI (sensitivity??)
// a modulo value that determines how frequently the synth changes activity/density/mix/etc.

// maybe sensitivity can also be a result of SendReply trigger frequency...?

// use input as control signals -> current_amp could be used as amp.reciprocal for synthesis synths?

// time as an element of exhaustion? Can this be programmed? Like, the longer/more it plays, the less
// "creative" it gets? Or the less dense it gets? What happens when musicians play for > 60 minutes?
// maybe this affects the "sensitivity" argument? Like responses to silence are not so immediate, for example?

// "soundcheck mode" should show running averages of analyzed input, but not during performance
// these must be different OSCdefs, I think...

// I need a better way of classifying synthesized/processed sounds...some intermediate analysis???
// something before the \globalListener??? for each individual synth?


