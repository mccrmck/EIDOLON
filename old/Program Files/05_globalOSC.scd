/*-----------------------------------------    global analyser     -------------------------------------------*/
(
var memoryScale = ~config[\pollRateGlobal]; // this probably needs to change at some point as well...
var memLength = memoryScale * 6; // 6 seconds

OSCdef(\globalListener, { |msg|
	var current_amp = msg[3].ampdb;
	var recent_amp = ~globalMemory["past_amp"][..memLength].median;
	var current_silence = msg[4];
	var recent_silence = ~globalMemory["past_silence"][..memLength].mean;
	var current_freq = msg[5];
	var recent_freq = ~globalMemory["past_freq"][..memLength].median;
	var current_hasFreq = msg[6];
	var recent_hasFreq = ~globalMemory["past_hasFreq"][..memLength].mean;
	var onsets = msg[7];
	var current_centroid = msg[8];
	var recent_centroid = ~globalMemory["past_centroid"][..memLength].median;
	var current_specFlatness = msg[9];
	var recent_specFlatness = ~globalMemory["past_specFlatness"][..memLength].median;
	var current_density = msg[10];
	var recent_density = ~globalMemory["past_density"][..memLength].median;
	var current_meanIOI = msg[11];
	var recent_meanIOI = ~globalMemory["past_meanIOI"][..memLength].median;
	var current_varianceIOI = msg[12];
	var recent_varianceIOI = ~globalMemory["past_varianceIOI"][..memLength].median;

	var current_time = msg[13];
	var current_event = 0;

	/*
	"\rGLOBAL
	current_amp: % \rrecent_amp: % \rcurrent_silence: % \rrecent_silence: % \rcurrent_freq: % \rrecent_freq: % \rcurrent_hasFreq: % \rrecent_hasFreq: % \ronsets: % \rcurrent_centroid: % \rrecent_centroid: %
	current_specFlatness: % \rrecent_specFlatness: % \rcurrent_density: % \rrecent_density: % \rcurrent_meanIOI: % \rrecent_meanIOI: % \rcurrent_varianceIOI: % \rrecent_varianceIOI: %

	current_time: %".format(current_amp,recent_amp,current_silence,recent_silence,current_freq,recent_freq,current_hasFreq,recent_hasFreq,onsets,current_centroid,recent_centroid,current_specFlatness,
	recent_specFlatness,current_density,recent_density,current_meanIOI,recent_meanIOI,current_varianceIOI,recent_varianceIOI,current_time).postln;
	*/

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//interrupt layer

	// if(current_time > 3.0 and: {current_time < 3.2},{Ndef(\switcher,\reverb)});

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


	// can this be rewritten into an iteration /.do statement?

	~globalMemory["past_amp"] = ~globalMemory["past_amp"].addFirst(current_amp);
	~globalMemory["past_silence"] = ~globalMemory["past_silence"].addFirst(current_silence);
	~globalMemory["past_freq"] = ~globalMemory["past_freq"].addFirst(current_freq);
	~globalMemory["past_hasFreq"] = ~globalMemory["past_hasFreq"].addFirst(current_hasFreq);
	~globalMemory["past_centroid"] = ~globalMemory["past_centroid"].addFirst(current_centroid);
	~globalMemory["past_specFlatness"] = ~globalMemory["past_specFlatness"].addFirst(current_specFlatness);
	~globalMemory["past_density"] = ~globalMemory["past_density"].addFirst(current_density);
	~globalMemory["past_meanIOI"] = ~globalMemory["past_meanIOI"].addFirst(current_meanIOI);
	~globalMemory["past_varianceIOI"] = ~globalMemory["past_varianceIOI"].addFirst(current_varianceIOI);

	~globalMemory["events"] = ~globalMemory["events"].addFirst(current_event);

}, '/globalAnalysis');

"Global Analyser loaded".postln;
)