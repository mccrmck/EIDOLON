EIDOLON {

	var <sendBus, <analBus, <memory;
	var <synthLib, <synthArrays;
	var <recBuffers, <recIndex = 0;
	var <listener, <calibrator;

	*new { |playerIn, outBus, performanceLength, waitBeforeStart, synthLibs|
		^super.new.init(synthLibs)
	}

	init { |synthLibs_ |
		var server = Server.default;
		var path = Platform.userExtensionDir +/+ "EIDOLON";
		var synthArrays = IdentityDictionary();

		server.waitForBoot({


			// should I clear all busses, oscDefs.. here and then redeclare them?

			// fix the order of things here...

			sendBus = Bus.control(server,1);


			// am I doing the switcher thing to get a global reverb happening in addition to reverb on the inputChannel? Or is there a better way...individual sends for each synth?!?!?!
			// verbBus = Bus.control(server,2); ?? how many channels??

			analBus = Bus.control(server,10);

			recBuffers = Array.fill(12,{ Buffer.alloc(server, server.sampleRate * 12) });  // should I add a completion message??
			server.sync;

			memory = Dictionary[
				'pastAmp' -> List(),
				'pastSilence' -> List(),
				'pastFreq' -> List(),
				'pastHasFreq' -> List(),
				'pastCentroid' -> List(),
				'pastFlatness' -> List(),
				'pastDensity' -> List(),
				'pastMeanIOI' -> List(),
				'pastVarianceIOI' -> List(),

				'bufferEvents' -> List(),
				'events' -> List(),
				'state' -> List(),
			];

			/*
			globalMemory = Dictionary[
			'pastAmp' -> List(),
			'pastSilence' -> List(),
			'pastFreq' -> List(),
			'pastHasFreq' -> List(),
			'pastCentroid' -> List(),
			'pastFlatness' -> List(),
			'pastDensity' -> List(),
			'pastMeanIOI' -> List(),
			'pastVarianceIOI' -> List(),

			'bufferEvents' -> List(),
			'events' -> List(),
			'state' -> List(),
			];
			*/



			synthLib = EIDOLONSynthLib(synthLibs_);
			synthLib.subLibs.keysValuesDo({ |subLibKey,subLib| synthArrays.put(subLibKey,subLib.keys.asArray) });



			// this should start the input Ndefs and create the gui, so .calibrate, .play, etc. can be called

		});
	}

	makeListener { |verbose = true|
		var pollRate = 4;                             // this gets passed in? It should be the same arg as trigRate in the \analysis Ndef
		var memLength = pollRate * 4 * 4;
		var waitBeforeStartTime = 10;                 // in seconds
		var performanceLength = 60 * 10;              // in seconds
		var minPhraseLength = 45;                     // in seconds

		var maxVoices = 3;                            // polyphony; this can be passed in as an argument also!

		listener = OSCFunc({ |msg, time, addr, recvPort|
			var currentAmp         = msg[3].ampdb;
			var recentAmp          = memory['pastAmp'][..memLength].median;
			var currentSilence     = msg[4];
			var recentSilence      = memory['pastSilence'][..memLength].mean;
			var currentFreq        = msg[5];
			var recentFreq         = memory['pastFreq'][..memLength].median;
			var currentHasFreq     = msg[6];
			var recentHasFreq      = memory['pastHasFreq'][..memLength].mean;
			var onsets             = msg[7];
			var currentCentroid    = msg[8];
			var recentCentroid     = memory['pastCentroid'][..memLength].median;
			var currentFlatness    = msg[9];
			var recentFlatness     = memory['pastFlatness'][..memLength].median;
			var currentDensity     = msg[10];
			var recentDensity      = memory['pastDensity'][..memLength].median;
			var currentMeanIOI     = msg[11];
			var recentMeanIOI      = memory['pastMeanIOI'][..memLength].median;
			var currentVarianceIOI = msg[12];
			var recentVarianceIOI  = memory['pastVarianceIOI'][..memLength].median;
			var currentTime        = msg[13] - waitBeforeStartTime;

			var currentEvent = 0, bufferEvent = 0, state;
			var keyList = List.newClear();
			var fadeTime = 0.08;

			/* =======  determine state  ========= */

			case
			{currentTime < 0}{state = "tacet"} // tacet
			{currentTime >= 0 and: {currentTime < performanceLength} }{
				if(currentTime < (performanceLength * 0.08),{  // relative to performanceLength?
					state = "ignore";
				},{
					if(memory['state'].indicesOfEqual(memory['state'].first).last % (pollRate * performanceLength * 0.075) == 0,{ // minimum state length: related to performanceLength or fixed?
						case
						{memory['state'].first == "ignore"}{state = ["support","ignore"].wchoose([0.85,0.15])}
						{memory['state'].first == "support"}{state = ["support","tacet"].wchoose([0.85,0.15])}
						// {~memory[playerIndex]["state"].first == "contrast"}{state = ["contrast","ignore"].wchoose([0.65,0.35])}
						{memory['state'].first == "tacet"}{state = ["support","ignore"].wchoose([0.75,0.25])}
					},{
						state = memory['state'].first;
					});
				});
			}
			{currentTime >= performanceLength}{state = "tacetDone"};  // this could also call some other function that neatly wraps up the performance?

			if(verbose,{
				"currentAmp: % \rrecentAmp: % \rcurrentAilence: % \rrecentAilence: % \rcurrentFreq: % \rrecentFreq: % \rcurrentHasFreq: %
\rrecentHasFreq: % \ronsets: % \rcurrentCentroid: % \rrecentCentroid: % currentFlatness: % \rrecentFlatness: % \rcurrentDensity: % \rrecentDensity: %
\rcurrentMeanIOI: % \rrecentMeanIOI: % \rcurrentVarianceIOI: % \rrecentVarianceIOI: % \rcurrentTime: %".format(currentAmp, recentAmp, currentSilence,
					recentSilence, currentFreq, recentFreq, currentHasFreq, recentHasFreq, onsets, currentCentroid,recentCentroid, currentFlatness,
					recentFlatness, currentDensity, recentDensity, currentMeanIOI, recentMeanIOI, currentVarianceIOI, recentVarianceIOI, currentTime).postln;

				state.postln;
			});

			/* =======  state behaviour ========= */

			synthArrays.keysValuesDo({ |key,array|
				array.keysDo({ |synthKey|
					var key = synthKey.asSymbol;
					if(Ndef(key).isPlaying,{ keyList.add(key) })
				})
			});

			switch(state,
				"support",{

					// parse the analysis to determine if material is predominantely pitch, transients, silence, etc. Maybe these classifiers need to be better??
					// is there a way to account for <= maxVoices and currentEvent == 0 for all classifiers?



					// these statements should be created via iteration depending on which synthSubLibs are included in the EIDOLONSynthLib...


					//"densePerc"
					if(recentHasFreq <= 0.3
						and: { recentDensity >= 7 }
						and: { recentSilence <= 0.35 }
						and: { recentCentroid >= 1500 }             // are all these values normalized now??
						and: { keyList.size <= maxVoices }
						and: { currentEvent == 0 },{
							var key = synthArrays['perc'][0].asSymbol;

							if(Ndef(key).isPlaying.not,{
								Ndef(key,synthLib.subLibs['perc'][key])
								.set(\inBus,sendBus)
								// .play(switcherBus,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
								;  // this is here while things are commented out...
								currentEvent = key;
								"% ON".format(key).postln
							})
						},{
							var key = synthArrays['perc'][0];

							if(Ndef(key).isPlaying
								and: { memory['events'].indicesOfEqual(key).first > (pollRate * minPhraseLength) },{     // prevents synths from turning off too quickly...
									Ndef(key).end(fadeTime);
									"% OFF".format(key).postln;
							})
					});


					//"pitchTrack"
					if(recentHasFreq > 0.6
						and: { recentDensity <= 7 }
						and: { recentSilence < 0.4 }
						and: { keyList.size <= maxVoices }
						and: { currentEvent == 0 },{
							var key = synthArrays['pitch'][0].asSymbol;

							if(Ndef(key).isPlaying.not,{
								Ndef(key,synthLib.subLibs['pitch'][key])
								.set(\inBus,sendBus)
								// .play(switcherBus,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
								;  // this is here while things are commented out...
								currentEvent = key;
								"% ON".format(key).postln;
							})
						},{
							var key = synthArrays['pitch'][0].asSymbol;

							if(Ndef(key.asSymbol).isPlaying
								and: { memory['events'].indicesOfEqual(key).first > (pollRate * minPhraseLength) },{
									Ndef(key).end(fadeTime);
									"% OFF".format(key).postln;
							})
					});

					//"fillSilence"       // change this definition -> something about leading vs. following, coming with new ideas, etc. and shape the conditions accordingly
					if(recentSilence > 0.88
						and: {recentAmp <= -24}
						and: {recentDensity < 4}
						and: {keyList.size <= maxVoices}
						and: {currentEvent == 0},{
							var key = synthArrays['silence'][0].asSymbol;

							if(Ndef(key).isPlaying.not,{
								Ndef(key,synthLib.subLibs['silence'][key])
								.set(\inBus,sendBus)                                                                                     // do these have an \inBus argument?
								// .play(switcherBus,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
								;  // this is here while things are commented out...
								currentEvent = key;
								"% ON".format(key).postln;
							})
						},{
							var key = synthArrays['silence'][0].asSymbol;

							if(Ndef(key.asSymbol).isPlaying
								and: { memory['events'].indicesOfEqual(key).first > (pollRate * minPhraseLength) },{
									Ndef(key).end(fadeTime);
									"% OFF".format(key).postln;
							})
					});


					//"bufTransforms"
					if(recIndex > 0
						and: {recentAmp <= -18}
						and: {recentSilence > 0.5}
						and: {keyList.size <= maxVoices}
						and: {currentEvent == 0},{
							var key = synthArrays['buf'][0].asSymbol;

							if(Ndef(key).isPlaying.not,{
								Ndef(key,synthLib.subLibs['buf'][key])
								.set(\bufnum,recBuffers[ (recIndex % recBuffers.size).rand ])
								// .play(switcherBus,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
								;  // this is here while things are commented out...
								currentEvent = key;
								"% ON".format(key).postln
							})
						},{
							var key = synthArrays['buf'][0].asSymbol;

							if(Ndef(key.asSymbol).isPlaying
								and: { memory['events'].indicesOfEqual(key).first > (pollRate * minPhraseLength) },{
									Ndef(key).end(fadeTime);
									"% OFF".format(key).postln
							})
					});







				},
				"contrast",{},
				"ignore",{

					case                                                                                                  // should this have a default case??
					{ (memory['state'].indicesOfEqual("ignore") ? 0).asArray.last % (pollRate * 60 * 3) == 1 }{      // after 3 minutes(?) it should be silent for a bit?

						synthArrays.keysValuesDo({ |key,array|
							array.keysDo({ |synthKey|
								var key = synthKey.asSymbol;
								if(Ndef(key).isPlaying,{ Ndef(key).end(fadeTime) })
							})
						});
					}
					{ (memory['state'].indicesOfEqual("ignore") ? 0).asArray.last % (pollRate * 60 * 1.5) == 2 }{
						var subLibKey = synthLib.keys.choose;
						var synthKey = synthLib[subLibKey].keys.choose;

						synthArrays.keysValuesDo({ |subLibKeys,keyArrays|
							keyArrays.keysDo({ |synthKey|
								if(Ndef(synthKey.asSymbol).isPlaying,{
									Ndef(synthKey.asSymbol).end(fadeTime);
									"% OFF".format(synthKey).postln;
								});
							})
						});

						if(Ndef(synthKey).isPlaying.not,{
							Ndef(synthKey,synthLib[subLibKey][synthKey])
							.set(\inBus,sendBus)
							// .play(switcherBus,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail)               // must fix this outBus arg
							;  // this is here while things are commented out...
							currentEvent = synthKey.asString;
							"% ON".format(synthKey).postln;
						},{
							if(Ndef(synthKey).isPlaying,{
								Ndef(synthKey).end(fadeTime);
								"% OFF".format(synthKey).postln;
							});
						});
					};

					// need to also add a way to use all the other synths here, regardless of input....

				},
				"tacet",{                                                            //this doesn't seem to always work...

					if((memory['state'].indicesOfEqual("tacet").asArray.at(pollRate) ? 0) == pollRate,{                 // what is this???

						synthArrays.keysValuesDo({ |key,array|
							array.keysDo({ |synthKey|
								var key = synthKey.asSymbol;
								if(Ndef(key).isPlaying,{ Ndef(key).end(fadeTime) })
							})
						});
					});
				},
				"tacetDone",{                                                         // should this be different ???

					if((memory['state'].indicesOfEqual("tacet").asArray.at(pollRate) ? 0) == pollRate,{                 // what is this???

						synthArrays.keysValuesDo({ |key,array|
							array.keysDo({ |synthKey|
								var key = synthKey.asSymbol;
								if(Ndef(key).isPlaying,{ Ndef(key).end(fadeTime) })
							})
						});
					});
				};
			);


			/* =======  buffer recording ========= */

			// maybe the conditions should be around amp/silence/etc. instead of density/onsets? So as to also record long tones...

			if( currentTime > 0
				and: { recentDensity > 4 }
				and: { recentAmp > -25 }
				and: { (memory['bufferEvents'].indicesOfEqual("bufRec") ? 0).asArray.first > (pollRate * 60 * 1.5) },{    //at least 1.5 min between recordings...

					Synth(\recorder,[\inBus,sendBus,\bufnum,recBuffers[recIndex % recBuffers.size]], Ndef(\input).nodeID,\addAfter);            // gotta fix this Ndef key!! and the inBus arg!
					bufferEvent = "bufRec";
					"Buffer % recording".format(recIndex).postln;
					recIndex = recIndex + 1;
			});

			/* =======  cycle synths ========= */

			synthArrays.keysValuesDo({ |subLibKey,synthKeyArray|
				synthKeyArray.do({ |synthKey|
					if(Ndef(synthKey.asSymbol).isPlaying.not and: { (memory['events'].indicesOfEqual(synthKey) ? 0).asArray.last > (pollRate * (performanceLength/5)) },{
						var nowSynth = synthKey;
						var newSynth = subLibKey[1];

						"rotating %, introducing %".format(nowSynth, newSynth).postln;
						synthArrays.keysValuesChange({ |key,array| array.rotate(-1) });
					})
				})
			});

			/* =======  update memory ========= */


		},'/analysis');

	}

	play { |verbose = true|


	}

	stop {
		listener.free;
		synthArrays.keysValuesDo({ |key,array|
			array.keysDo({ |synthKey|
				var key = synthKey.asSymbol;
				if(Ndef(key).isPlaying,{ Ndef(key).clear })
			})
		});
		"EIDOLON Stopped".postln;
	}


	reset {

	/*
		if some Ndefs, etc. are running:
		set busses to appropriate values
		clear/reinitialize memory
		zero values like bufferIndex, etc.

	*/
	}




	calibrate {

		calibrator = OSCFunc({ |msg, time, addr, recvPort|
			var silence = msg[3];
			var onsets = msg[4];

			if(silence == 1,{"silence detected".postln});
			if(onsets == 1,{"onset detected".postln});

		},'/calibrate');

	}

	stopCalibrate { calibrator.free; }

}

/*
spatMode Arg:
0 = equal power panning (channel check for stereo or PanAz)
1 = VBAP...how would this work? does it get addressed in interface?
2 = ambisonics...how would this work? does it get addressed in interface?
*/