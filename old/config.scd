(
~config = ( //should become .init method? Need to order/arrange these a bit better!

	Dictionary[

		\performanceLength -> (60 * 5), // in seconds
		\numChannels -> 2, // number of output channels or speakers
		// \spatMode -> "VBAP", eventually include SynthDefs w/ different modes???

		\orientation -> 0.5, // 0 if center front, 0.5, if bisecting a  vertex
		// \width -> 3; should perhaps change if \numChannels > 2 and \orientation == 0
		\waitBeforeStartTime -> 5, // in seconds

		\globalVolume -> 0.8, // between 0.0 and 1.0
		\compThreshGlobal -> 0.5, // compressor threshold between 0.0 and 1.0 for ouput
		\onsetThreshGlobal -> 0.5,
		\silenceThreshold -> 0.01,

		\globalDamp -> 0.5, // between 0.0 and 1.0; high frequency dampening
		\globalMix -> 0.02, // between 0.0 and 1.0; wet/dry reverb mix
		\lpfFreqGlobal -> 2000,
		\hpfFreqGlobal -> 450,

		\pollRateGlobal -> 4,
		\hardwareOut -> 0,

		\playerProfiles -> ["Mascha"],
	]
);

~players = Dictionary();

~config[\playerProfiles].do({ |string|  	              // load player profiles, eventually a drag and drop thing in a GUI?
	var path = PathName(thisProcess.nowExecutingPath).parentPath +/+ "PlayerProfiles/" ++ string ++ ".scd";

	path.load;

});

~config.add(\numPlayers -> ~config[\playerProfiles].size); // this can be much cleaner...

"config file loaded".postln;

)