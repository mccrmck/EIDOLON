///////////////////////////////////////////////////////EIDOLON GUI//////////////////////////////////////////////////////////////////////

(
var bounds = Rect(0,0,280,700).center_( Window.availableBounds.center );
var window = Window("EIDOLON Controls",bounds);
var flow = window.addFlowLayout();

flow.left_(15);

EZSlider(
	parent: window,
	bounds: 60@250,
	label: "Input0\nVolume",
	labelHeight: 30,
	controlSpec: \amp,
	action:{ |slider|
		if(Ndef(\input0).isPlaying,{
			var amp = \db.asSpec.map(slider.value).dbamp;

			Ndef(\input0).set(\amp,amp);
			~players["Mascha"][\inVolume] = amp;

		},{ "input% not playing".format(0).postln; })
	},
	initVal: ~players["Mascha"][\inVolume],
	layout: \vert,
	gap: 8@4,
).numberView.align_(\center);

EZSlider(
	parent: window,
	bounds: 60@250,
	label: "Reverb0\nVolume",
	labelHeight: 30,
	controlSpec: \amp,
	action:{ |slider|
		if(Ndef(\reverb0).isPlaying,{
			var amp = \db.asSpec.map(slider.value).dbamp;

			Ndef(\reverb0).set(\amp,amp);
			~players["Mascha"][\verbAmp] = amp;

		},{ "Reverb% not playing".format(0).postln; })
	},
	initVal: ~players["Mascha"][\verbAmp],
	layout: \vert,
	gap: 8@4,
).numberView.align_(\center);

EZSlider(
	parent: window,
	bounds: 60@250,
	label: "Reverb0\nLPF Freq",
	labelHeight: 30,
	controlSpec: \freq,
	action:{ |slider|
		if(Ndef(\reverb0).isPlaying,{

			Ndef(\reverb0).set(\lpfFreq,slider.value);
			~players["Mascha"][\lpfFreq] = slider.value;

		},{ "Reverb% not playing".format(0).postln; })
	},
	initVal: ~players["Mascha"][\lpfFreq],
	layout: \vert,
	gap: 8@4,
).numberView.align_(\center);

EZSlider(
	parent: window,
	bounds: 60@250,
	label: "Reverb0\nHPF Freq",
	labelHeight: 30,
	controlSpec: \freq,
	action:{ |slider|
		if(Ndef(\reverb0).isPlaying,{

			Ndef(\reverb0).set(\hpfFreq,slider.value);
			~players["Mascha"][\hpfFreq] = slider.value;

		},{ "Reverb% not playing".format(0).postln; })
	},
	initVal: ~players["Mascha"][\hpfFreq],
	layout: \vert,
	gap: 8@4,
).numberView.align_(\center);

flow.nextLine;
flow.left_(15);

EZSlider(
	parent: window,
	bounds: 60@250,
	label: "MASTER\nVolume",
	labelHeight: 30,
	controlSpec: \amp,
	action:{ |slider|
		if(Ndef(\globalOut).isPlaying,{
			var amp = \db.asSpec.map(slider.value).dbamp;

			Ndef(\globalOut).set(\amp,amp);

		},{ "EIDOLON not playing".postln; })
	},
	initVal: ~config[\globalVolume],
	layout: \vert,
	gap: 8@4,
).numberView.align_(\center);

EZSlider(
	parent: window,
	bounds: 60@250,
	label: "MASTER\nVerb Vol",
	labelHeight: 30,
	controlSpec: \amp,
	action:{ |slider|
		if(Ndef(\switcher).isPlaying,{
			var amp = \db.asSpec.map(slider.value).dbamp;

			Ndef(\switcher).set(\mix,amp );

		},{ "EIDOLON not playing".postln; })
	},
	initVal: ~config[\globalMix],
	layout: \vert,
	gap: 8@4,
).numberView.align_(\center);

EZSlider(
	parent: window,
	bounds: 60@250,
	label: "MASTER\nVerb LPF",
	labelHeight: 30,
	controlSpec: \freq,
	action:{ |slider|
		if(Ndef(\switcher).isPlaying,{

			Ndef(\switcher).set(\lpfFreq,slider.value);

		},{ "EIDOLON not playing".postln; })
	},
	initVal: ~config[\lpfFreqGlobal],
	layout: \vert,
	gap: 8@4,
).numberView.align_(\center);

EZSlider(
	parent: window,
	bounds: 60@250,
	label: "MASTER\nVerb HPF",
	labelHeight: 30,
	controlSpec: \freq,
	action:{ |slider|
		if(Ndef(\switcher).isPlaying,{

			Ndef(\switcher).set(\hpfFreq,slider.value);

		},{ "EIDOLON not playing".postln; })
	},
	initVal: ~config[\hpfFreqGlobal],
	layout: \vert,
	gap: 8@4,
).numberView.align_(\center);

flow.nextLine;
flow.left_(15);

CheckBox(window,Rect(0,0,125,50),"Player0 Verbose").action_({
	"doesn't do anything yet...".postln;
});

CheckBox(window,Rect(0,0,125,50),"Calibrate").action_({

	if(Ndef(\globalOut).isPlaying.not,{
		case
		{~calibrating == false}{
			~calibrating = true;
			Ndef(\calibrate,\tester).play;
			Ndef(\calibrate).set(\inBus,~audioBus["analyserIn"][0]);
		}
		{~calibrating == true}{
			~calibrating = false;
			Ndef(\calibrate,\tester).end;
			OSCdef(\silenceReceiver).clear;
			OSCdef(\onsetReceiver).clear;
		}
	},{
		~calibrating == false;
		"Can't adjust during performance".postln;
	})
});

flow.nextLine;
flow.left_(15);

/* ---- ----- ----- testing ----- ------ ---- */

/*
Eventually - the slider values can also be assigned to the dictionary values
so they can be saved/recalled from other places during performance?
*/

EZSlider(
	parent: window,
	bounds: 250@40,
	label: "Input0 SilenceThresh",
	labelHeight: 20,
	controlSpec: \amp,
	action:{ |slider|
		if(~calibrating == true,{

			// Ndef(\analyser0).set(\silenceThresh, slider.value);
			Ndef(\calibrate).set(\silenceThresh, slider.value);
			~players["Mascha"][\silenceThreshold] = slider.value;
			"SilenceThresh: %".format(slider.value).postln;

		},{ "Can't adjust during performance".postln; })
	},
	initVal: ~players["Mascha"][\silenceThreshold],
	layout: \line2,
	gap: 8@4,
).numberView.align_(\center);

flow.nextLine;
flow.left_(15);

EZSlider(
	parent: window,
	bounds: 250@40,
	label: "Input0 OnsetThresh",
	labelHeight: 20,
	controlSpec: \amp,
	action:{ |slider|
		if(~calibrating == true,{

			// Ndef(\analyser0).set(\onsetThresh, slider.value);
			Ndef(\calibrate).set(\onsetThresh, slider.value);
			~players["Mascha"][\onsetThreshold] = slider.value;
			"OnsetThresh: %".format(slider.value).postln;

		},{ "Can't adjust during performance".postln; })
	},
	initVal: ~players["Mascha"][\onsetThreshold],
	layout: \line2,
	gap: 8@4,
).numberView.align_(\center);

flow.nextLine;
flow.left_(15);

/* ---- ----- ----- start/stop/record ----- ------ ---- */

Button(window.view,125@30)
.states_([["START EIDOLON",Color.black, Color.green],["STOP EIDOLON",Color.black, Color.red]])
.action_({ |state|
	var val = state.value;

	case
	{val == 0}{
		~stop.value;
	}
	{val == 1}{
		~play.value;
	}
});

Button(window.view,125@30)
.states_([["START RECORD",Color.black, Color.green],["STOP RECORD",Color.black, Color.red]])
.action_({ |state|
	var val = state.value;

	case
	{val == 0}{
		Server.default.stopRecording;
		"Recording stopped".postln;
	}
	{val == 1}{
		Server.default.record(numChannels: ~config[\numChannels]);
		"Recording starting".postln;
	}
});

window.view.background = Color.rand(0.25,1.0); // Color(0.6,0.8,0.8);
window.onClose({~stop.value;});

window.front;
)