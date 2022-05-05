///////////////////////////////////////////////////////EIDOLON SynthKeys//////////////////////////////////////////////////////////////////////

(
// can this be moved to OSC file???

var numPlayers = ~config[\numPlayers];

~synthKeys = numPlayers.collect({ |playerIndex|

	Dictionary[

		"percSynthKeys" -> ~transforms["densePerc"].keys.asArray.scramble,
		"pitchSynthKeys" -> ~transforms["pitchTrack"].keys.asArray.scramble,
		"silenceSynthKeys" -> ~transforms["fillSilence"].keys.asArray.scramble,
		"bufferSynthKeys" -> ~bufTransforms.keys.asArray.scramble,
	]
});

"Synth keys loaded".postln;

)

//  whole approach needs to be different:
// ~synthKeys = Dictionary(), then
// ~transforms.keysDo synthKeys.add(key -> value)