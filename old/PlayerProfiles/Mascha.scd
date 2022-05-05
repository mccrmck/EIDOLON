/* ------ Mascha ------ */

(
//this also needs to change..make into a dictionary or something???

// hardware
~players.add(

	"Mascha" -> (
		inBus: 0,
		outBus: 0,

		compThresh: 1.0, // compressor threshold between 0.0 and 1.0 for inputs
		onsetThreshold: 0.25, // value between 0.0 and 1.0, depends on instrument, microphone, etc. // was 0.18
		silenceThreshold: 0.1,
		pollRate: 4,

		pan: 0,
		inVolume: 0.9, // between 0.0 and 1.0; volume for clean thru signal
		damp: 0.4, // between 0.0 and 1.0; high frequency dampening
		verbAmp: 0.4, // between 0.0 and 1.0; reverb volume
		lpfFreq: 2000, // between 0.0 and 1.0; low-pass filter cutoff frequency scaled between 40-16000 Hz
		hpfFreq: 450, // between 0.0 and 1.0; high-pass filter cutoff frequency scaled between 40-16000 Hz

		// EQ stuff??

	);
);

"Profile \"Mascha\" loaded".postln;
)