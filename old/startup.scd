///////////////////////////////////////////////////////EIDOLON////////////////////////////////////////////////////////////////////

(
var server = Server.default;
var options = server.options;

options.numInputBusChannels = 2;
options.numOutputBusChannels = 2;
options.memSize = 2**20;
options.sampleRate = 44100;

// Choose Device
// options.device = "Scarlett 2i2 USB";
// options.device = "OCTA-CAPTURE";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Ndef.all.clear;
OSCdef.freeAll;
server.freeAll;

server.waitForBoot({

	// load config file - could also have different profiles eventually?

	"config.scd".loadRelative;
	// ~buffer = Buffer.read(s, "/Users/mikemccormick/Desktop/07.wav" );
	~buffer = Buffer.read(s, "/Users/mikemccormick/Desktop/10.wav" );

	// load program files
	PathName(PathName(thisProcess.nowExecutingPath).parentPath +/+ "Program Files/").entries.do({ |entry,index|
		var stereo = ~config[\numChannels] < 3;

		switch(index,
			0,{entry.fullPath.load},
			1,{if(stereo,{entry.fullPath.load})},
			2,{if(stereo.not,{entry.fullPath.load})},
			3,{entry.fullPath.load},
			4,{entry.fullPath.load},
			5,{entry.fullPath.load},
			6,{entry.fullPath.load},
			7,{entry.fullPath.load},
			8,{entry.fullPath.load},
		);
	});
});
);


Ndef(\analyser0).set(\onsetThreshold,0.1)


Server.default.options.
ServerOptions.devices



// evaluate the following line to record the performance
Server.default.record(numChannels: ~config[\numChannels]);

~play.value;
~stop.value


Server.default.options.device