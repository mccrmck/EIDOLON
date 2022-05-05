///////////////////////////////////////////////////////EIDOLON Dictionaries//////////////////////////////////////////////////////////////////////
(
var server = Server.default;
var numChannels = ~config[\numChannels];
var numPlayers = ~config[\numPlayers];

//Allocate Audio and Control Busses
(

// perhaps all Dictionary keys should be symbols instead of strings!??!?!

~audioBus = Dictionary[

	"analyserIn" -> Array.fill(numPlayers,{Bus.audio(server,1)}),

	"switcherBus" -> Bus.audio(server,numChannels),
	"globalInBus" -> Bus.audio(server,numChannels),

];

~controlBus = {
	Dictionary.with(*[
		"ampBus" -> Bus.control(server,1),
		"silenceBus" -> Bus.control(server,1),
		"freqBus" -> Bus.control(server,1),
		"hasFreqBus" -> Bus.control(server,1),
		"onsetsBus" -> Bus.control(server,1),
		"centroidBus" -> Bus.control(server,1),
		"specFlatnessBus" -> Bus.control(server,1),
		"densityBus" -> Bus.control(server,1),
		"meanIOIBus" -> Bus.control(server,1),
		"varianceIOIBus" -> Bus.control(server,1),
	])
} ! numPlayers;

);

//Allocate buffers for recording
~buffers = {Array.fill(12,{Buffer.alloc(server, server.sampleRate * 12, 1)})} ! numPlayers;

//groups
(
~inGroup = Group(server,\addToHead);
~globalOutGroup = Group(server,\addToTail);
~interruptGroup = Group(~globalOutGroup,\addBefore);
);

//median filters for incoming data
(
~memory = {
	Dictionary.with(*[
		"past_amp" -> List(),
		"past_silence" -> List(),
		"past_freq" -> List(),
		"past_hasFreq" -> List(),
		"past_centroid" -> List(),
		"past_specFlatness" -> List(),
		"past_density" -> List(),
		"past_meanIOI" -> List(),
		"past_varianceIOI" -> List(),

		"bufferEvents" -> List(),
		"events" -> List(),
		"state" -> List()

	])
} ! numPlayers;

~globalMemory = Dictionary.with(*[
	"past_amp" -> List(),
	"past_silence" -> List(),
	"past_freq" -> List(),
	"past_hasFreq" -> List(),
	"past_centroid" -> List(),
	"past_specFlatness" -> List(),
	"past_density" -> List(),
	"past_meanIOI" -> List(),
	"past_varianceIOI" -> List(),

	"events" -> List()
])
);

~recorder = Array.fill(numPlayers,{0});
~calibrating = false;

"Data file loaded".postln;

)