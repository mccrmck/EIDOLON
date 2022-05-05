///////////////////////////////////////////////////////EIDOLON //////////////////////////////////////////////////////////////////////

(
OSCdef(\silenceReceiver,{ |msg, time, addr, recvPort|

	var silence = msg[3];

	if(silence == 1,{"silence detected\n".postln});

},'/silenceReply');

OSCdef(\onsetReceiver,{ |msg, time, addr, recvPort|

	var onsets = msg[3];

	if(onsets == 1,{"onset detected\n".postln});

},'/onsetReply');

"Calibration OSCdefs loaded".postln;
)
