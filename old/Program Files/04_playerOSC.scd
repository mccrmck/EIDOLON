///////////////////////////////////////////////////////EIDOLON////////////////////////////////////////////////////////////////////

/*-----------------------------------------------    analyser     -------------------------------------------*/

(
var players = ~config[\playerProfiles];
var waitBeforeStartTime = ~config[\waitBeforeStartTime].clip(1,inf).asInteger;
var performanceLength = ~config[\performanceLength];
var numChannels = ~config[\numChannels];
var numPlayers = ~config[\numPlayers];
var switcherBus = ~audioBus["switcherBus"];

players.do({ |profileName,playerIndex|
	var verbose = true;
	var analyserIn = ~audioBus["analyserIn"][playerIndex];

	var maxVoices = 1; // degree of polyphony
	var minPhraseLength = 45; // 45 seconds
	var pollRateScale = ~players.asArray[playerIndex][\pollRate]; // this probably needs to change at some point as well...
	var memLength = pollRateScale * 4; // 4 seconds

	OSCdef("listener%".format(playerIndex).asSymbol, { |msg|
		var current_amp = msg[3].ampdb;                                                                           // change here
		var recent_amp = ~memory[playerIndex]["past_amp"][..memLength].median;
		var current_silence = msg[4];
		var recent_silence = ~memory[playerIndex]["past_silence"][..memLength].mean;
		var current_freq = msg[5];
		var recent_freq = ~memory[playerIndex]["past_freq"][..memLength].median;
		var current_hasFreq = msg[6];
		var recent_hasFreq = ~memory[playerIndex]["past_hasFreq"][..memLength].mean;
		var onsets = msg[7];
		var current_centroid = msg[8];
		var recent_centroid = ~memory[playerIndex]["past_centroid"][..memLength].median;
		var current_specFlatness = msg[9];
		var recent_specFlatness = ~memory[playerIndex]["past_specFlatness"][..memLength].median;
		var current_density = msg[10];
		var recent_density = ~memory[playerIndex]["past_density"][..memLength].median;
		var current_meanIOI = msg[11];
		var recent_meanIOI = ~memory[playerIndex]["past_meanIOI"][..memLength].median;
		var current_varianceIOI = msg[12];
		var recent_varianceIOI = ~memory[playerIndex]["past_varianceIOI"][..memLength].median;

		var current_time = msg[13];
		var buffer_event = 0;
		var current_event = 0;

		var keyList = List.newClear();

		var percKey = ~synthKeys[playerIndex]["percSynthKeys"].first;
		var pitchKey = ~synthKeys[playerIndex]["pitchSynthKeys"].first;
		var silenceKey = ~synthKeys[playerIndex]["silenceSynthKeys"].first;
		var bufferKey = ~synthKeys[playerIndex]["bufferSynthKeys"].first;

		var state;
		var fadeTime = 0.8;

		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//determine state!!!!

		case
		{current_time < waitBeforeStartTime}{state = "tacet"} // tacet
		// {current_time > waitBeforeStartTime}{state = "support"} // just for testing....
		{current_time >= waitBeforeStartTime and: {current_time < (performanceLength + waitBeforeStartTime)}}
		{
			if((current_time - waitBeforeStartTime) < (performanceLength * 0.08),{  // relative to performanceLength?
				state = "ignore";
			},{
				if(~memory[playerIndex]["state"].indicesOfEqual(~memory[playerIndex]["state"].first).last % (pollRateScale * performanceLength * 0.075) == 0,{ // minimum state length: related to performanceLength or fixed?
					case
					{~memory[playerIndex]["state"].first == "ignore"}{state = ["support","ignore"].wchoose([0.85,0.15])}
					{~memory[playerIndex]["state"].first == "support"}{state = ["support","tacet"].wchoose([0.85,0.15])}
					// {~memory[playerIndex]["state"].first == "contrast"}{state = ["contrast","ignore"].wchoose([0.65,0.35])}
					{~memory[playerIndex]["state"].first == "tacet"}{state = ["support","ignore"].wchoose([0.75,0.25])}
				},{
					state = ~memory[playerIndex]["state"].first;
				});
			});
		}
		{current_time >= (performanceLength + waitBeforeStartTime)}{state = "tacetDone"}; // this could also call some other function that neatly wraps up the performance?

		if(verbose,{
			"\rPLAYER: %
current_amp: % \rrecent_amp: % \rcurrent_silence: % \rrecent_silence: % \rcurrent_freq: % \rrecent_freq: % \rcurrent_hasFreq: % \rrecent_hasFreq: % \ronsets: % \rcurrent_centroid: % \rrecent_centroid: %
current_specFlatness: % \rrecent_specFlatness: % \rcurrent_density: % \rrecent_density: % \rcurrent_meanIOI: % \rrecent_meanIOI: % \rcurrent_varianceIOI: % \rrecent_varianceIOI: % \rcurrent_time: %"
			.format(profileName,current_amp,recent_amp,current_silence,recent_silence,current_freq,recent_freq,current_hasFreq,recent_hasFreq,onsets,current_centroid,recent_centroid,current_specFlatness,recent_specFlatness,current_density,recent_density,current_meanIOI,recent_meanIOI,current_varianceIOI,recent_varianceIOI,current_time).postln;

			state.postln;
		});

		//determine fadeTime!!!!...maybe this is determined by state?

		/*
		case
		{state == "support"}{fadeTime = 10}
		{state == "contrast"}{fadeTime = 6}
		{state == "ignore"}{fadeTime = 0.08};
		*/

		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//transforms

		~transforms.values.collect({ |subDicts|
			subDicts.keysDo({ |subDictKey|
				if(Ndef((subDictKey ++ playerIndex).asSymbol).isPlaying,{keyList.add(subDictKey)})
			})
		});

		case                  // need to double check this...case will go through each statement in order, prioritizing the first entries, no? Should it be a switch?
		{state == "support"}  // can these each be turned into a function with some args passed in? (conditions, transform key, etc.)
		{
			//"densePerc"
			if(recent_hasFreq <= 0.3 and: {recent_density >= 7} and: {recent_silence <= 0.35} and: {recent_centroid >= 1500} and: {keyList.size <= maxVoices} and: {current_event == 0},{
				var key = (percKey ++ playerIndex);

				if(Ndef(key.asSymbol).isPlaying.not,{
					Ndef(key.asSymbol,~transforms["densePerc"][percKey]).play(switcherBus,numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
					Ndef(key.asSymbol).set(\inBus,analyserIn);
					current_event = key;
					"% ON".format(key).postln
				})
			},{
				var key = (percKey ++ playerIndex);

				if(Ndef(key.asSymbol).isPlaying and: {~memory[playerIndex]["events"].indicesOfEqual(key).first > (pollRateScale * minPhraseLength)},{ // prevents synths from turning off too quickly...
					Ndef(key.asSymbol).end(fadeTime);
					"% OFF".format(key).postln;
				})
			});

			//"pitchTrack"
			if(recent_hasFreq > 0.6 and: {recent_density <= 7} and: {recent_silence < 0.4} and: {keyList.size <= maxVoices} and: {current_event == 0},{
				var key = (pitchKey ++ playerIndex);

				if(Ndef(key.asSymbol).isPlaying.not,{
					Ndef(key.asSymbol,~transforms["pitchTrack"][pitchKey]).play(switcherBus,numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
					Ndef(key.asSymbol).set(\inBus,analyserIn);
					current_event = key;
					"% ON".format(key).postln;
				})
			},{
				var key = (pitchKey ++ playerIndex);

				if(Ndef(key.asSymbol).isPlaying and: {~memory[playerIndex]["events"].indicesOfEqual(key).first > (pollRateScale * minPhraseLength)},{
					Ndef(key.asSymbol).end(fadeTime);
					"% OFF".format(key).postln;
				})
			});

			//"fillSilence"       // change this definition -> something about leading vs. following, coming with new ideas, etc. and shape the conditions accordingly

			if(recent_silence > 0.88 and: {recent_amp <= -24} and: {recent_density < 4} and: {keyList.size <= maxVoices} and: {current_event == 0},{
				var key = (silenceKey ++ playerIndex);

				if(Ndef(key.asSymbol).isPlaying.not,{
					Ndef(key.asSymbol,~transforms["fillSilence"][silenceKey]).play(switcherBus,numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
					Ndef(key.asSymbol).set(\inBus,analyserIn);
					current_event = key;
					"% ON".format(key).postln;
				})
			},{
				var key = (silenceKey ++ playerIndex);

				if(Ndef(key.asSymbol).isPlaying and: {~memory[playerIndex]["events"].indicesOfEqual(key).first > (pollRateScale * minPhraseLength)},{
					Ndef(key.asSymbol).end(fadeTime);
					"% OFF".format(key).postln;
				})
			});

			//"bufTransforms"
			if(~recorder[playerIndex] > 0 and: {recent_amp <= -18} and: {recent_silence > 0.5} and: {keyList.size <= maxVoices} and: {current_event == 0},{
				var key = (bufferKey ++ playerIndex);

				if(Ndef(key.asSymbol).isPlaying.not,{
					Ndef(key.asSymbol,~bufTransforms[bufferKey]).play(switcherBus,numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
					Ndef(key.asSymbol).set(\bufnum,~buffers[playerIndex][~recorder[playerIndex].rand]);
					current_event = key;
					"% ON".format(key).postln
				})
			},{
				var key = (bufferKey ++ playerIndex);

				if(Ndef(key.asSymbol).isPlaying and: {~memory[playerIndex]["events"].indicesOfEqual(key).first > (pollRateScale * minPhraseLength)},{
					Ndef(key.asSymbol).end(fadeTime);
					"% OFF".format(key).postln
				})
			});

			//fix all this - it's soooo messy! Can't they be put in a Dictionary and controlled by Ndefs??
			//  |
			//  |
			//  V

			if(current_density <= 3 and: {recent_amp <= -24} and: (recent_hasFreq > 0.75) and: {current_event == 0},{
				{
					1.do({
						Synth(\snowSines,[\atk,4.0.rrand(6.0),\rls,8.0.rrand(10.0),\pan,1.0.rand2,\amp,0.02.rrand(0.03),\freq,~memory[playerIndex]["past_freq"][..(memLength * 2)].asSet.choose,\outBus,switcherBus]);
						current_event = "snowSines%".format(playerIndex);
						"snowSines%".format(playerIndex).postln;
						10.0.rrand(13.0).wait;
					})
				}.fork;
			});

			if(~memory[playerIndex]["past_amp"][..memLength].maxItem >= -25 and: {current_hasFreq == 1} and: {recent_specFlatness > 0.1} and: {keyList.size <= maxVoices} and: {current_event == 0},{
				Synth(\freezeBells,[\inBus,analyserIn,\outBus,switcherBus], Ndef("input%".format(playerIndex).asSymbol).nodeID,\addAfter);
				current_event = "freezeBells%".format(playerIndex);
				"freezeBells%".format(playerIndex).postln;
			});

			if(current_density >= 10 and: {current_centroid > 3000} and: {current_amp >= -18} and: {keyList.size <= maxVoices} and: {current_event == 0},{
				if(~memory[playerIndex]["events"].indicesOfEqual("screech%".format(playerIndex)).isNil,{
					Synth(\screech,[\freq,1000,\amp,0.18.rrand(0.25),\pan,1.0.rand2,\outBus,switcherBus]);
					current_event = "screech%".format(playerIndex);
					"screech%".format(playerIndex).postln;
				},{
					if(~memory[playerIndex]["events"].indicesOfEqual("screech%".format(playerIndex)).first > (pollRateScale * 1.5),{
						Synth(\screech,[\freq,1000,\amp,0.18.rrand(0.25),\pan,1.0.rand2,\outBus,switcherBus]);
						current_event = "screech%".format(playerIndex);
						"screech%".format(playerIndex).postln;
					})
				});
			});

			if(recent_centroid > 3000 and: {recent_meanIOI < 0.3} and: {recent_varianceIOI < 0.1} and: {keyList.size <= maxVoices} and: {current_event == 0},{
				if(~memory[playerIndex]["events"].indicesOfEqual("crawlers%".format(playerIndex)).isNil,{
					Synth(\clicks,[\ts,1.exprand(4.0),\freq,0.001.exprand(0.01),\feedback,60,\amp,0.06,\outBus,switcherBus]);
					current_event = "crawlers%".format(playerIndex);
					"crawlers%".format(playerIndex).postln;
				},{
					if(~memory[playerIndex]["events"].indicesOfEqual("crawlers%".format(playerIndex)).first > (pollRateScale * 1.5),{
						Synth(\clicks,[\ts,1.exprand(4.0),\freq,0.001.exprand(0.01),\feedback,60,\amp,0.06,\outBus,switcherBus]);
						current_event = "crawlers%".format(playerIndex);
						"crawlers%".format(playerIndex).postln;
					})
				});
			});
		}


		//{state == "contrast"}{} //gotta figure this out!

		{state == "ignore"} // ignore state is, for now, monophonic - this needs to change!! Could use .coin to trigger things? Based on analysis, or just time?
		{
			case
			{(~memory[playerIndex]["state"].indicesOfEqual("ignore") ? 0).asArray.last % (pollRateScale * 60 * 3) == 1} //after 3 minutes(?) it should be silent for a bit?
			{
				~transforms.values.collect({ |subDicts|
					subDicts.keysDo({ |subDictKey|
						if(Ndef((subDictKey ++ playerIndex).asSymbol).isPlaying,{Ndef((subDictKey ++ playerIndex).asSymbol).end(fadeTime)})
					})
				});
			}
			{(~memory[playerIndex]["state"].indicesOfEqual("ignore") ? 0).asArray.last % (pollRateScale * 60 * 1.5) == 2}
			{
				var dict = ~transforms.keys.choose;
				var key = ~transforms[dict].keys.choose;
				var playerKey = (key ++ playerIndex);

				~transforms.values.collect({ |subDicts|
					subDicts.keysDo({ |subDictKey|
						if(Ndef((subDictKey ++ playerIndex).asSymbol).isPlaying,{
							Ndef((subDictKey ++ playerIndex).asSymbol).end(fadeTime);
							"% OFF".format(subDictKey ++ playerIndex).postln;
						});
					})
				});

				if(Ndef(playerKey.asSymbol).isPlaying.not,{
					Ndef(playerKey.asSymbol,~transforms[dict][key]).play(switcherBus,numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
					Ndef(playerKey.asSymbol).set(\inBus,analyserIn);
					current_event = playerKey;
					"% ON".format(playerKey).postln;
				},{
					if(Ndef(playerKey).isPlaying,{
						Ndef(playerKey).end(fadeTime);
						"% OFF".format(playerKey).postln;
					});
				});
			};

			// need to also add a way to use all the other synths here, regardless of input....

		}

		{state == "tacet" || { state == "tacetDone" } } //this doesn't seem to always work...
		{
			// need another conditional - if Ndefs.all(not all though, becase we want to keep our analysers going).do.isPlaying.etc.
			// then kill 'em all
			// otherwise don't do anything and save some CPU

			if((~memory[playerIndex]["state"].indicesOfEqual("tacet").asArray.at(pollRateScale) ? 0) == pollRateScale,{

				~transforms.values.collect({ |subDicts|
					subDicts.keysDo({ |subDictKey|
						if(Ndef((subDictKey ++ playerIndex).asSymbol).isPlaying,{
							Ndef((subDictKey ++ playerIndex).asSymbol).end(fadeTime);
							"% OFF".format(subDictKey ++ playerIndex).postln;
						})
					})
				});

				~bufTransforms.keysDo({ |key|

					if(Ndef((key ++ playerIndex).asSymbol).isPlaying,{
						Ndef((key ++ playerIndex).asSymbol).end(fadeTime);
						"% OFF".format(key ++ playerIndex).postln;
					})
				})
			});

			current_event = 0;

		};

		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//buffer recording

		// this is a bad if statment!!! The logic doesn't really make sense - it should be nested inside another if statement...
		// also - maybe the conditions should be around amp/silence/etc. instead of density/onsets? So as to also record long tones...

		if(current_time > waitBeforeStartTime and: {recent_density > 7} and: {recent_amp > -25} and: {~recorder[playerIndex] < 12},{
			case
			{~recorder[playerIndex] < 1}{
				Synth(\recorder,[\inBus,analyserIn,\bufnum,~buffers[playerIndex][~recorder[playerIndex]]],Ndef("input%".format(playerIndex).asSymbol).nodeID,\addAfter);
				buffer_event = "bufRec" ++ playerIndex;
				"Buffer % full".format(~recorder[playerIndex]).postln;
				~recorder[playerIndex] = (~recorder[playerIndex] + 1);
			}
			{~recorder[playerIndex] >= 1}{
				if((~memory[playerIndex]["bufferEvents"].indicesOfEqual("bufRec" ++ playerIndex) ? 0).asArray.first > (pollRateScale * 60 * 1.5),{    //at least 1.5 min between recordings...
					Synth(\recorder,[\inBus,analyserIn,\bufnum,~buffers[playerIndex][~recorder[playerIndex]]],Ndef("input%".format(playerIndex).asSymbol).nodeID,\addAfter);
					buffer_event = "bufRec" ++ playerIndex;
					"Buffer % full".format(~recorder[playerIndex]).postln;
					~recorder[playerIndex] = (~recorder[playerIndex] + 1);
				})
			}
		});

		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//cycle synths

		// this cycles based on time...should it also be based on number of occurences?
		(
			~synthKeys[playerIndex].keysDo({ |key|
				var synthKey = (~synthKeys[playerIndex][key].first ++ playerIndex);

				if(Ndef(synthKey.asSymbol).isPlaying.not and: {(~memory[playerIndex]["events"].indicesOfEqual(synthKey) ? 0).asArray.last > (pollRateScale * (performanceLength/5))},{
					~synthKeys[playerIndex][key] = ~synthKeys[playerIndex][key].rotate(-1);
					"rotating %, introducing %".format(synthKey,~synthKeys[playerIndex][key].first).postln;
				});
			})
		);

		// can this be rewritten into an iteration / .do statement?

		~memory[playerIndex]["past_amp"] = ~memory[playerIndex]["past_amp"].addFirst(current_amp);
		~memory[playerIndex]["past_silence"] = ~memory[playerIndex]["past_silence"].addFirst(current_silence);
		~memory[playerIndex]["past_freq"] = ~memory[playerIndex]["past_freq"].addFirst(current_freq);
		~memory[playerIndex]["past_hasFreq"] = ~memory[playerIndex]["past_hasFreq"].addFirst(current_hasFreq);
		~memory[playerIndex]["past_centroid"] = ~memory[playerIndex]["past_centroid"].addFirst(current_centroid);
		~memory[playerIndex]["past_specFlatness"] = ~memory[playerIndex]["past_specFlatness"].addFirst(current_specFlatness);
		~memory[playerIndex]["past_density"] = ~memory[playerIndex]["past_density"].addFirst(current_density);
		~memory[playerIndex]["past_meanIOI"] = ~memory[playerIndex]["past_meanIOI"].addFirst(current_meanIOI);
		~memory[playerIndex]["past_varianceIOI"] = ~memory[playerIndex]["past_varianceIOI"].addFirst(current_varianceIOI);

		~memory[playerIndex]["bufferEvents"] = ~memory[playerIndex]["bufferEvents"].addFirst(buffer_event);
		~memory[playerIndex]["events"] = ~memory[playerIndex]["events"].addFirst(current_event);
		~memory[playerIndex]["state"] = ~memory[playerIndex]["state"].addFirst(state);

	},'/analysis');

});

"Analysers loaded".postln;

)