EIDOLON {

	var <inBus, <outBus, <performanceLength, <waitBeforeStartTime;
	var <sendBus, <verbBus, <analBus, <memory;
	var <synthLib, <synthArrays;
	var <recBuffers, <>recIndex = 0;
	var <inGroup, <outGroup;
	var <listener, <calibrator;

	/*
	could eventually add an .initClass method with an .all Dict = each instance gets a hash Key that gets added to all ndef keys??
	*/

	*new { |playerIn, speakerOut, dur, waitBeforeStart, synthLibs, gui = true|
		^super.newCopyArgs(playerIn, speakerOut, dur,waitBeforeStart).init(synthLibs,gui.asBoolean)
	}

	init { |synthLibs_,gui|
		var server = Server.default;
		var path = Platform.userExtensionDir +/+ "EIDOLON";
		synthArrays = IdentityDictionary();

		server.waitForBoot({

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
			server.sync;

			// globalMemory = Dictionary[];

			// should I clear all busses, oscDefs.. here and then redeclare them?

			// fix the order of things here...
			inGroup  = Group(server,\addToHead);
			outGroup = Group(server,\addToTail);

			sendBus = Bus.audio(server,1);
			verbBus = Bus.audio(server,2);
			analBus = Bus.control(server,10);

			recBuffers = Array.fill(12,{ Buffer.alloc(server, server.sampleRate * 8) });  // should I add a completion message??
			server.sync;

			File.readAllString(path +/+ "defs" +/+ "synthDefs.scd").interpret;

			synthLib = EIDOLONSynthLib(synthLibs_);
			synthLib.subLibs.keysValuesDo({ |subLibKey,subLib| synthArrays.put(subLibKey,subLib.keys.asArray.scramble) });
			server.sync;

			this.arm;
			server.sync;

			if(gui,{ this.gui(server) });
		});
	}

	arm {
		// Ndef(\input,\eidolonIn).set( // all Ndef keys need to be given better names...maybe using hashes or something??? What if I want to run multiple instances??!?!
		Ndef(\input,\simenIn).set( // need to have a Simen version here!!!
			\amp,0,
			\compThresh,0.5,
			// \inBus,inBus,
			\heartIn,inBus[0],
			\drumIn,inBus[1],
			\sendBus,sendBus,
			\out,outBus,
		).play(group:inGroup);

		Ndef(\playerVerb,\monoInVerb).set(
			\inBus,sendBus,
			\amp,0,
			\out,outBus,
		).play(group:inGroup,addAction:\addToTail);

		Ndef(\listener,\analyser).set(
			\inBus,sendBus,
			\onsetThresh,0,
			\silenceThresh,0,
			\trigRate,4,                                             // this has to get passed into a few different places...find a solution!!!
			\analBus,analBus,
		).play(group:inGroup,addAction:\addToTail);

		Ndef(\mainVerb,\outWithVerb).set(
			\inBus,verbBus,
			\verbMix,0,
			\amp,0,
			\out,outBus,
		).play(group:outGroup,addAction:\addToTail);
	}

	play { |verbose = true|
		Routine({                        // can I find a slick solution w/ CondVar here?
			Ndef(\listener).set(\resetTime,1);
			this.stopCalibrate;
			1.wait;
			this.makeListener;
		}).play
	}

	stop {
		//free the groups?
		this.stopCalibrate;
		listener.free;
		synthArrays.keysValuesDo({ |key,array|
			array.do({ |synthKey|
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

		Ndef(\listener).set(\trigRate,10);
		calibrator = OSCFunc({ |msg, time, addr, recvPort|
			var silence = msg[4];
			var onsets = msg[5];

			"silence: % \nonset: % \n".format(silence.asBoolean,onsets.asBoolean).postln;

		},'/analysis');
	}

	stopCalibrate {
		Ndef(\listener).set(\trigRate,4);                       // pass original pollRate
		calibrator.free;
	}

	makeListener { |verbose = true|
		var pollRateSec = 4;                        // this gets passed in? It should be the same arg as trigRate in the \analysis Ndef
		var memLength = pollRateSec * 4;              // in seconds
		var minPhraseLength = 45;                     // in seconds
		var minStateLength = pollRateSec * performanceLength * 0.05;  // min state length

		var maxVoices = 3;                            // polyphony; this can be passed in as an argument also!
		var ctrlBusArray = [0,3,4,5,7,8,9].collect({|i| analBus.subBus(i) });
		var trigBusArray = [1,2,6].collect({|i| analBus.subBus(i) });

		listener = OSCFunc({ |msg, time, addr, recvPort|
			var currentAmp         = msg[3].ampdb;
			var recentAmp          = memory['pastAmp'][..memLength].median;
			var currentSilence     = msg[4];
			var recentSilence      = memory['pastSilence'][..memLength].mean;
			var onsets             = msg[5];
			var currentCentroid    = msg[6];
			var recentCentroid     = memory['pastCentroid'][..memLength].median;
			var currentFlatness    = msg[7];
			var recentFlatness     = memory['pastFlatness'][..memLength].median;
			var currentFreq        = msg[8];
			var recentFreq         = memory['pastFreq'][..memLength].median;
			var currentHasFreq     = msg[9];
			var recentHasFreq      = memory['pastHasFreq'][..memLength].mean;
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

			/* =======  timeLine  ========= */

			case
			{currentTime < 0}{state = "tacet" } // tacet
			{currentTime >= 0 and: {currentTime < performanceLength} }{

				if(currentTime < 60,{
					state = "tacet";
				},{
					state = "EIDOLON";

					synthArrays.keysValuesDo({ |key,array|
						array.do({ |synthKey|
							var key = synthKey.asSymbol;
							if(Ndef(key).isPlaying,{ keyList.add(key) })
						})
					});

					// "densePerc"
					if(recentAmp >= -30
						and: { recentDensity >= 0.3 }
						and: { recentSilence <= 0.35 }
						and: { keyList.size <= maxVoices }
						and: { currentEvent == 0 },{
							var key = synthArrays['perc'][0].asSymbol;

							if(Ndef(key).isPlaying.not,{
								Ndef(key,synthLib.subLibs['perc'][key])
								.set(\inBus,sendBus,\ctrlIn,ctrlBusArray.choose,\trigIn,trigBusArray.choose)
								.play(verbBus,fadeTime:fadeTime,group:inGroup,addAction:\addToTail);
								currentEvent = key;
								"% ON".format(key).postln
							})
						},{
							var key = synthArrays['perc'][0];

							if(Ndef(key).isPlaying
								and: { memory['events'].indicesOfEqual(key).first ? 0 > (pollRateSec * minPhraseLength) },{     // prevents synths from turning off too quickly...
									Ndef(key).end(fadeTime);
									"% OFF".format(key).postln;
							})
					});

					// "pitchTrack"
					if(recentHasFreq > 0.6
						and: { recentDensity >= 0.35 }
						and: { recentSilence < 0.4 }
						and: { keyList.size <= maxVoices }
						and: { currentEvent == 0 },{
							var key = synthArrays['pitch'][0].asSymbol;

							if(Ndef(key).isPlaying.not,{
								Ndef(key,synthLib.subLibs['pitch'][key])
								.set(\inBus,sendBus,\ctrlIn,ctrlBusArray.choose,\trigIn,trigBusArray.choose)
								.play(verbBus,fadeTime:fadeTime,group:inGroup,addAction:\addToTail);
								currentEvent = key;
								"% ON".format(key).postln;
							})
						},{
							var key = synthArrays['pitch'][0].asSymbol;

							if(Ndef(key.asSymbol).isPlaying
								and: { memory['events'].indicesOfEqual(key).first ? 0 > (pollRateSec * minPhraseLength) },{
									Ndef(key).end(fadeTime);
									"% OFF".format(key).postln;
							})
					});

					/*
					// "fillSilence"
					if(recentSilence > 0.88
					and: {recentAmp <= -24}
					and: {recentDensity < 0.2}
					and: {keyList.size <= maxVoices}
					and: {currentEvent == 0},{
					var key = synthArrays['silence'][0].asSymbol;

					if(Ndef(key).isPlaying.not,{
					Ndef(key,synthLib.subLibs['silence'][key])
					// .set(\inBus,sendBus)                                                                                     // do these have an \inBus argument?
					.set(\ctrlIn0,ctrlBusArray.choose,\ctrlIn1,ctrlBusArray.choose,\trigIn,trigBusArray.choose)
					.play(verbBus,fadeTime:fadeTime,group:inGroup,addAction:\addToTail);
					currentEvent = key;
					"% ON".format(key).postln;
					})
					},{
					var key = synthArrays['silence'][0].asSymbol;

					if(Ndef(key.asSymbol).isPlaying
					and: { memory['events'].indicesOfEqual(key).first ? 0 > (pollRateSec * minPhraseLength) },{
					Ndef(key).end(fadeTime);
					"% OFF".format(key).postln;
					})
					});
					*/

					// "bufTransforms"
					if(recIndex > 0
						and: {recentAmp <= -24}
						and: {recentSilence > 0.6}
						and: {keyList.size <= maxVoices}
						and: {currentEvent == 0},{
							var key = synthArrays['buf'][0].asSymbol;

							if(Ndef(key).isPlaying.not,{
								Ndef(key,synthLib.subLibs['buf'][key])
								.set(\bufnum,recBuffers[ (recIndex % recBuffers.size).rand ],\ctrlIn,ctrlBusArray.choose,\trigIn,trigBusArray.choose)
								.play(verbBus,fadeTime:fadeTime,group:inGroup,addAction:\addToTail);
								currentEvent = key;
								"% ON".format(key).postln
							})
						},{
							var key = synthArrays['buf'][0].asSymbol;

							if(Ndef(key.asSymbol).isPlaying
								and: { memory['events'].indicesOfEqual(key).first ? 0 > (pollRateSec * minPhraseLength) },{
									Ndef(key).end(fadeTime);
									"% OFF".format(key).postln
							})
					});

					// "oneShots"
					if(currentDensity <= 0.15
						and: {recentAmp <= -24}
						and: {currentHasFreq == 1}
						and: {recentHasFreq > 0.5}
						and: {keyList.size <= maxVoices}
						and: {currentEvent == 0},{
							if(memory['events'].indicesOfEqual("snowSines").isNil,{
								Synth(\snowSines,[\atk,4.0.rrand(6.0),\rls,8.0.rrand(10.0),\pan,1.0.rand2,\amp,0.02.rrand(0.03),\freq,currentFreq.linexp(0,1,100,900),\outBus,verbBus]);
								currentEvent = "snowSines";
								"snowSines".postln;
							},{
								if(memory['events'].indicesOfEqual("snowSines").first > (pollRateSec * 3),{
									Synth(\snowSines,[\atk,4.0.rrand(6.0),\rls,8.0.rrand(10.0),\pan,1.0.rand2,\amp,0.02.rrand(0.03),\freq,currentFreq.linexp(0,1,100,900),\outBus,verbBus]);
									currentEvent = "snowSines";
									"snowSines".postln;
								})
							});
					});

					if(memory['pastAmp'][..memLength].maxItem >= -25
						and: {currentHasFreq == 1}
						and: {recentFlatness > 0.1}
						and: {keyList.size <= maxVoices}
						and: {currentEvent == 0},{
							if(memory['events'].indicesOfEqual("freezeBells").isNil,{
								Synth(\freezeBells,[\inBus,sendBus,\outBus,verbBus], Ndef(\input).nodeID,\addAfter);
								currentEvent = "freezeBells";
								"freezeBells".postln;
							},{
								if(memory['events'].indicesOfEqual("freezeBells").first > (pollRateSec * 3),{
									Synth(\freezeBells,[\inBus,sendBus,\outBus,verbBus], Ndef(\input).nodeID,\addAfter);
									currentEvent = "freezeBells";
									"freezeBells".postln;
								})
							});
					});

					if(currentDensity >= 0.7
						and: {currentCentroid >= 0.7}
						and: {currentAmp >= -18}
						and: {keyList.size <= maxVoices}
						and: {currentEvent == 0},{
							if(memory['events'].indicesOfEqual("screech").isNil,{
								Synth(\screech,[\freq,1000,\amp,0.18.rrand(0.25),\pan,1.0.rand2,\outBus,verbBus]);
								currentEvent = "screech";
								"screech".postln;
							},{
								if(memory['events'].indicesOfEqual("screech").first > (pollRateSec * 5),{
									Synth(\screech,[\freq,1000,\amp,0.18.rrand(0.25),\pan,1.0.rand2,\outBus,verbBus]);
									currentEvent = "screech";
									"screech".postln;
								})
							});
					});

					if(recentCentroid > 0.72
						and: {recentMeanIOI < 0.3}
						and: {recentVarianceIOI < 0.1}
						and: {keyList.size <= maxVoices}
						and: {currentEvent == 0},{
							if(memory['events'].indicesOfEqual("crawlers").isNil,{
								Synth(\clicks,[\ts,1.exprand(4),\freq,0.001.exprand(0.01),\feedback,60,\amp,0.06,\outBus,verbBus]);
								currentEvent = "crawlers";
								"crawlers".postln;
							},{
								if(memory['events'].indicesOfEqual("crawlers").first > (pollRateSec * 4),{
									Synth(\clicks,[\ts,1.exprand(4),\freq,0.001.exprand(0.01),\feedback,60,\amp,0.06,\outBus,verbBus]);
									currentEvent = "crawlers";
									"crawlers".postln;
								})
							});
					});
				});
			}
			{currentTime >= performanceLength}{
				fadeTime = 10;

				synthArrays.keysValuesDo({ |key,array|
					array.do({ |synthKey|
						var key = synthKey.asSymbol;
						if(Ndef(key).isPlaying,{ Ndef(key).end(fadeTime) })
					})
				});
				state = "tacetDone"

			};

			/* =======  info posting ========= */

			if(verbose,{"\ncurrentAmp: % \nrecentAmp: % \ncurrentSilence: % \nrecentSilence: % \ncurrentFreq: % \nrecentFreq: % \ncurrentHasFreq: % \nrecentHasFreq: % \nonsets: % \ncurrentCentroid: %
recentCentroid: % \ncurrentFlatness: % \nrecentFlatness: % \ncurrentDensity: % \nrecentDensity: % \ncurrentMeanIOI: % \nrecentMeanIOI: % \ncurrentVarianceIOI: % \nrecentVarianceIOI: % \ncurrentTime: %"
				.format(currentAmp, recentAmp, currentSilence, recentSilence, currentFreq, recentFreq, currentHasFreq, recentHasFreq, onsets, currentCentroid,recentCentroid, currentFlatness,
					recentFlatness, currentDensity, recentDensity, currentMeanIOI, recentMeanIOI, currentVarianceIOI, recentVarianceIOI, currentTime).postln;

				state.postln;
			});


			/* =======  buffer recording ========= */

			if( currentTime > 0
				and: { recentAmp > -36 }
				and: { recentSilence < 0.3 },{

					case
					{recIndex == 0}{
						Synth(\recorder,[\inBus,sendBus,\bufnum,recBuffers[recIndex % recBuffers.size]], Ndef(\input).nodeID,\addAfter);
						bufferEvent = "bufRec";
						"Buffer % recording".format(recIndex).postln;
						recIndex = recIndex + 1;
					}
					{recIndex > 0}{
						if((memory['bufferEvents'].indicesOfEqual("bufRec") ? 0).asArray.first > (pollRateSec * 90),{                 // at least 45 secs between recordings...
							Synth(\recorder,[\inBus,sendBus,\bufnum,recBuffers[recIndex % recBuffers.size]], Ndef(\input).nodeID,\addAfter);
							bufferEvent = "bufRec";
							"Buffer % recording".format(recIndex).postln;
							recIndex = recIndex + 1;
						})
					}
			});

			/* =======  cycle synths ========= */

			synthArrays.keysValuesDo({ |subLibKey,synthKeyArray|
				synthKeyArray.do({ |synthKey|
					var phraseDur = pollRateSec * performanceLength * 0.25;
					if((memory['events'][..phraseDur.asInteger].indicesOfEqual(synthKey) ? 0).asArray.last == phraseDur,{  // does this work /make sense???
						var nowSynth = synthKey;
						var newSynth = synthKeyArray[1];

						if(Ndef(synthKey).isPlaying,{
							Ndef(synthKey).end(fadeTime);
							"% OFF".format(synthKey).postln;
						});

						"rotating %, introducing %".format(nowSynth, newSynth).postln;
						synthKeyArray = synthKeyArray.rotate(-1);
					})
				})
			});

			/* =======  update memory ========= */

			memory['pastAmp']         = memory['pastAmp'].addFirst(currentAmp);
			memory['pastSilence']     = memory['pastSilence'].addFirst(currentSilence);
			memory['pastFreq']        = memory['pastFreq'].addFirst(currentFreq);
			memory['pastHasFreq']     = memory['pastHasFreq'].addFirst(currentHasFreq);
			memory['pastCentroid']    = memory['pastCentroid'].addFirst(currentCentroid);
			memory['pastFlatness']    = memory['pastFlatness'].addFirst(currentFlatness);
			memory['pastDensity']     = memory['pastDensity'].addFirst(currentDensity);
			memory['pastMeanIOI']     = memory['pastMeanIOI'].addFirst(currentMeanIOI);
			memory['pastVarianceIOI'] = memory['pastVarianceIOI'].addFirst(currentVarianceIOI);

			memory['bufferEvents']    = memory['bufferEvents'].addFirst(bufferEvent);
			memory['events']          = memory['events'].addFirst(currentEvent);
			memory['state']           = memory['state'].addFirst(state);

		},'/analysis');
	}

	makeListenerKeep { |verbose = true|
		var pollRateSec = 4;                        // this gets passed in? It should be the same arg as trigRate in the \analysis Ndef
		var memLength = pollRateSec * 4;              // in seconds
		var minPhraseLength = 45;                     // in seconds
		var minStateLength = pollRateSec * performanceLength * 0.05;  // min state length

		var maxVoices = 3;                            // polyphony; this can be passed in as an argument also!
		var ctrlBusArray = [0,3,4,5,7,8,9].collect({|i| analBus.subBus(i) });
		var trigBusArray = [1,2,6].collect({|i| analBus.subBus(i) });

		listener = OSCFunc({ |msg, time, addr, recvPort|
			var currentAmp         = msg[3].ampdb;
			var recentAmp          = memory['pastAmp'][..memLength].median;
			var currentSilence     = msg[4];
			var recentSilence      = memory['pastSilence'][..memLength].mean;
			var onsets             = msg[5];
			var currentCentroid    = msg[6];
			var recentCentroid     = memory['pastCentroid'][..memLength].median;
			var currentFlatness    = msg[7];
			var recentFlatness     = memory['pastFlatness'][..memLength].median;
			var currentFreq        = msg[8];
			var recentFreq         = memory['pastFreq'][..memLength].median;
			var currentHasFreq     = msg[9];
			var recentHasFreq      = memory['pastHasFreq'][..memLength].mean;
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
					var currentState = memory['state'].first;

					if( (memory['state'][..minStateLength.asInteger].indicesOfEqual(currentState) ? 0 ).asArray.last == minStateLength,{  // this statement could be the cause of trouble???
						case
						{memory['state'].first == "ignore"}{state = ["support","ignore"].wchoose([0.85,0.15])}
						{memory['state'].first == "support"}{state = ["support","ignore"].wchoose([0.85,0.15])}
						// {memory["state"].first == "contrast"}{state = ["contrast","ignore"].wchoose([0.65,0.35])}
						{memory['state'].first == "tacet"}{state = ["support","ignore"].wchoose([0.75,0.25])}
					},{
						state = currentState;
					});
				});
			}
			{currentTime >= performanceLength}{state = "tacetDone"};  // this could also call some other function that neatly wraps up the performance?

			if(verbose,{"\ncurrentAmp: % \nrecentAmp: % \ncurrentSilence: % \nrecentSilence: % \ncurrentFreq: % \nrecentFreq: % \ncurrentHasFreq: % \nrecentHasFreq: % \nonsets: % \ncurrentCentroid: %
recentCentroid: % \ncurrentFlatness: % \nrecentFlatness: % \ncurrentDensity: % \nrecentDensity: % \ncurrentMeanIOI: % \nrecentMeanIOI: % \ncurrentVarianceIOI: % \nrecentVarianceIOI: % \ncurrentTime: %"
				.format(currentAmp, recentAmp, currentSilence, recentSilence, currentFreq, recentFreq, currentHasFreq, recentHasFreq, onsets, currentCentroid,recentCentroid, currentFlatness,
					recentFlatness, currentDensity, recentDensity, currentMeanIOI, recentMeanIOI, currentVarianceIOI, recentVarianceIOI, currentTime).postln;

				state.postln;
			});

			/* =======  state behaviour ========= */

			synthArrays.keysValuesDo({ |key,array|
				array.do({ |synthKey|
					var key = synthKey.asSymbol;
					if(Ndef(key).isPlaying,{ keyList.add(key) })
				})
			});

			switch(state,
				"support",{

					// parse the analysis to determine if material is predominantely pitch, transients, silence, etc. Maybe these classifiers need to be better??
					// is there a way to account for <= maxVoices and currentEvent == 0 for all these conditions


					// these statements should be created via iteration depending on which synthSubLibs are included in the EIDOLONSynthLib...


					//"densePerc"
					if(recentAmp >= -18
						and: { recentDensity >= 0.3 }
						and: { recentSilence <= 0.35 }
						and: { keyList.size <= maxVoices }
						and: { currentEvent == 0 },{
							var key = synthArrays['perc'][0].asSymbol;

							if(Ndef(key).isPlaying.not,{
								Ndef(key,synthLib.subLibs['perc'][key])
								.set(\inBus,sendBus,\ctrlIn,ctrlBusArray.choose,\trigIn,trigBusArray.choose)
								.play(verbBus,fadeTime:fadeTime,group:inGroup,addAction:\addToTail);
								currentEvent = key;
								"% ON".format(key).postln
							})
						},{
							var key = synthArrays['perc'][0];

							if(Ndef(key).isPlaying
								and: { memory['events'].indicesOfEqual(key).first ? 0 > (pollRateSec * minPhraseLength) },{     // prevents synths from turning off too quickly...
									Ndef(key).end(fadeTime);
									"% OFF".format(key).postln;
							})
					});

					//"pitchTrack"
					if(recentHasFreq > 0.6
						and: { recentDensity <= 0.35 }
						and: { recentSilence < 0.4 }
						and: { keyList.size <= maxVoices }
						and: { currentEvent == 0 },{
							var key = synthArrays['pitch'][0].asSymbol;

							if(Ndef(key).isPlaying.not,{
								Ndef(key,synthLib.subLibs['pitch'][key])
								.set(\inBus,sendBus,\ctrlIn,ctrlBusArray.choose,\trigIn,trigBusArray.choose)
								.play(verbBus,fadeTime:fadeTime,group:inGroup,addAction:\addToTail);
								currentEvent = key;
								"% ON".format(key).postln;
							})
						},{
							var key = synthArrays['pitch'][0].asSymbol;

							if(Ndef(key.asSymbol).isPlaying
								and: { memory['events'].indicesOfEqual(key).first ? 0 > (pollRateSec * minPhraseLength) },{
									Ndef(key).end(fadeTime);
									"% OFF".format(key).postln;
							})
					});

					//"fillSilence"       // change this definition -> something about leading vs. following, coming with new ideas, etc. and shape the conditions accordingly
					if(recentSilence > 0.88
						and: {recentAmp <= -24}
						and: {recentDensity < 0.2}
						and: {keyList.size <= maxVoices}
						and: {currentEvent == 0},{
							var key = synthArrays['silence'][0].asSymbol;

							if(Ndef(key).isPlaying.not,{
								Ndef(key,synthLib.subLibs['silence'][key])
								// .set(\inBus,sendBus)                                                                                     // do these have an \inBus argument?
								.set(\ctrlIn0,ctrlBusArray.choose,\ctrlIn1,ctrlBusArray.choose,\trigIn,trigBusArray.choose)
								.play(verbBus,fadeTime:fadeTime,group:inGroup,addAction:\addToTail);
								currentEvent = key;
								"% ON".format(key).postln;
							})
						},{
							var key = synthArrays['silence'][0].asSymbol;

							if(Ndef(key.asSymbol).isPlaying
								and: { memory['events'].indicesOfEqual(key).first ? 0 > (pollRateSec * minPhraseLength) },{
									Ndef(key).end(fadeTime);
									"% OFF".format(key).postln;
							})
					});

					//"bufTransforms"
					if(recIndex > 0
						and: {recentAmp <= -18}
						and: {recentSilence > 0.4}
						and: {keyList.size <= maxVoices}
						and: {currentEvent == 0},{
							var key = synthArrays['buf'][0].asSymbol;

							if(Ndef(key).isPlaying.not,{
								Ndef(key,synthLib.subLibs['buf'][key])
								.set(\bufnum,recBuffers[ (recIndex % recBuffers.size).rand ],\ctrlIn,ctrlBusArray.choose,\trigIn,trigBusArray.choose)
								.play(verbBus,fadeTime:fadeTime,group:inGroup,addAction:\addToTail);
								currentEvent = key;
								"% ON".format(key).postln
							})
						},{
							var key = synthArrays['buf'][0].asSymbol;

							if(Ndef(key.asSymbol).isPlaying
								and: { memory['events'].indicesOfEqual(key).first ? 0 > (pollRateSec * minPhraseLength) },{
									Ndef(key).end(fadeTime);
									"% OFF".format(key).postln
							})
					});


					/*

					add the oneShots!!


					*/

				},
				"contrast",{},
				"ignore",{

					if( (memory['state'][..minStateLength.asInteger].indicesOfEqual("ignore") ? 0).asArray.last % (pollRateSec * 60 * 1.5) == 2,{             // change every 1.5 minutes??
						var subLibKey = synthLib.keys.choose;
						var synthKey = synthLib.subLibs[subLibKey].keys.choose;

						synthArrays.keysValuesDo({ |subLibKeys,keyArrays|
							keyArrays.do({ |key|
								if(Ndef(key.asSymbol).isPlaying,{
									Ndef(key.asSymbol).end(fadeTime);
									"% OFF".format(key).postln;
								});
							})
						});

						if(Ndef(synthKey).isPlaying.not,{
							Ndef(synthKey,synthLib.subLibs[subLibKey][synthKey])
							.set(\inBus,sendBus)
							.play(verbBus,fadeTime:fadeTime,group:inGroup,addAction:\addToTail);
							currentEvent = synthKey.asString;
							"% ON".format(synthKey).postln;
						},{
							if(Ndef(synthKey).isPlaying,{
								Ndef(synthKey).end(fadeTime);
								"% OFF".format(synthKey).postln;
							});
						});
					})

					// need to also add a way to use all the other synths here, regardless of input....

				},{                                                                         // using a default instead of having cases for "tacet" nad "tacetDone"...

					if((memory['state'][..minStateLength.asInteger].indicesOfEqual("tacet").asArray.at(pollRateSec) ? 0) == pollRateSec ||
						(memory['state'][..minStateLength.asInteger].indicesOfEqual("tacetDone").asArray.at(pollRateSec) ? 0) == pollRateSec,{

							synthArrays.keysValuesDo({ |key,array|
								array.do({ |synthKey|
									var key = synthKey.asSymbol;
									if(Ndef(key).isPlaying,{ Ndef(key).end(fadeTime) })
								})
							});
					});
				};
			);

			/* =======  buffer recording ========= */

			if( currentTime > 0
				and: { recentAmp > -25 }
				and: { recentSilence < 0.3 },{

					case
					{recIndex == 0}{
						Synth(\recorder,[\inBus,sendBus,\bufnum,recBuffers[recIndex % recBuffers.size]], Ndef(\input).nodeID,\addAfter);
						bufferEvent = "bufRec";
						"Buffer % recording".format(recIndex).postln;
						recIndex = recIndex + 1;
					}
					{recIndex > 0}{
						if((memory['bufferEvents'].indicesOfEqual("bufRec") ? 0).asArray.first > (pollRateSec * 45),{                 // at least 45 secs between recordings...
							Synth(\recorder,[\inBus,sendBus,\bufnum,recBuffers[recIndex % recBuffers.size]], Ndef(\input).nodeID,\addAfter);
							bufferEvent = "bufRec";
							"Buffer % recording".format(recIndex).postln;
							recIndex = recIndex + 1;
						})
					}
			});

			/* =======  cycle synths ========= */

			synthArrays.keysValuesDo({ |subLibKey,synthKeyArray|
				synthKeyArray.do({ |synthKey|
					var phraseDur = pollRateSec * performanceLength * 0.25;
					if((memory['events'][..phraseDur.asInteger].indicesOfEqual(synthKey) ? 0).asArray.last == phraseDur,{  // does this work /make sense???
						var nowSynth = synthKey;
						var newSynth = synthKeyArray[1];

						if(Ndef(synthKey).isPlaying,{
							Ndef(synthKey).end(fadeTime);
							"% OFF".format(synthKey).postln;
						});

						"rotating %, introducing %".format(nowSynth, newSynth).postln;
						synthKeyArray = synthKeyArray.rotate(-1);
					})
				})
			});

			/* =======  update memory ========= */

			memory['pastAmp']         = memory['pastAmp'].addFirst(currentAmp);
			memory['pastSilence']     = memory['pastSilence'].addFirst(currentSilence);
			memory['pastFreq']        = memory['pastFreq'].addFirst(currentFreq);
			memory['pastHasFreq']     = memory['pastHasFreq'].addFirst(currentHasFreq);
			memory['pastCentroid']    = memory['pastCentroid'].addFirst(currentCentroid);
			memory['pastFlatness']    = memory['pastFlatness'].addFirst(currentFlatness);
			memory['pastDensity']     = memory['pastDensity'].addFirst(currentDensity);
			memory['pastMeanIOI']     = memory['pastMeanIOI'].addFirst(currentMeanIOI);
			memory['pastVarianceIOI'] = memory['pastVarianceIOI'].addFirst(currentVarianceIOI);

			memory['bufferEvents']    = memory['bufferEvents'].addFirst(bufferEvent);
			memory['events']          = memory['events'].addFirst(currentEvent);
			memory['state']           = memory['state'].addFirst(state);

		},'/analysis');
	}

	gui { |server|
		var bounds = Rect(0,0,450,725).center_( Window.availableBounds.center );
		var window = Window("EIDOLON",bounds);
		var flow = window.addFlowLayout(15@15,4@4);

		var dbSlider = { |label,actionFunc|
			var slide = EZSlider(
				parent: window,
				bounds: 60@300,
				label: label,
				labelHeight: 27,
				controlSpec: \db,
				action: actionFunc,
				initVal: -inf,
				layout: \vert,
			).round_(1);
			slide.numberView.align_(\center);
			slide.labelView.align_(\center);
		};

		var linSlider = { |label,actionFunc|
			var slide = EZSlider(
				parent: window,
				bounds: 60@300,
				label: label,
				labelHeight: 27,
				controlSpec: \unipolar,
				action: actionFunc,
				initVal: 0,
				layout: \vert,
			).round_(0.01);
			slide.numberView.align_(\center);
			slide.labelView.align_(\center);
		};

		var eqRanger = { |label,actionFunc|
			var ranger = EZRanger(
				parent: window,
				bounds: 60@300,
				label: label,
				labelHeight: 27,
				controlSpec: \freq,
				action: actionFunc,
				initVal: [200,15000],
				layout: \vert
			).round_(1);
			ranger.loBox.align_(\center);
			ranger.hiBox.align_(\center);
		};

		/* ======= layout ========= */

		dbSlider.("MIC dB",{ |slider|
			var amp = slider.value.dbamp;
			Ndef(\input).set(\amp,amp);
		});
		dbSlider.("VERB dB",{ |slider|
			var amp = slider.value.dbamp;
			Ndef(\playerVerb).set(\amp,amp);
		});
		eqRanger.("VERB EQ",{ |slider|
			var hpCutoff = slider.value[0].clip(20,20000);
			var lpCutoff = slider.value[1].clip(20,20000);
			Ndef(\playerVerb).set(\lpfFreq,lpCutoff,\hpfFreq,hpCutoff);
		});

		flow.left_(flow.bounds.width/2 + flow.margin.x + flow.gap.x);

		dbSlider.("MAIN dB", { |slider|
			var amp = slider.value.dbamp;
			Ndef(\mainVerb).set(\amp,amp);
		});
		dbSlider.("VERB dB", { |slider|
			var amp = slider.value.dbamp;
			Ndef(\mainVerb).set(\verbMix,amp);
		});
		eqRanger.("VERB EQ", { |slider|
			var hpCutoff = slider.value[0].clip(20,20000);
			var lpCutoff = slider.value[1].clip(20,20000);
			Ndef(\mainVerb).set(\lpfFreq,lpCutoff,\hpfFreq,hpCutoff);
		});

		flow.gap_(0@16);
		flow.nextLine;
		flow.gap_(4@4);

		/* ======= buttons ========= */

		Button(window.view,(flow.bounds.width/2) - flow.margin.x@30)
		.states_([["NOISE BURST",Color.black, Color.green]])
		.action_({ |state|
			var val = state.value;
			if(val == 0,{ Synth(\noiseBurst,[\amp,0.5,\out,verbBus]) })
		});

		Button(window.view,(flow.bounds.width/2) - flow.gap.x - flow.margin.x@30)
		.states_([["START RECORD",Color.black, Color.green],["STOP RECORD",Color.black, Color.red]])
		.action_({ |state|
			var val = state.value;

			case
			{val == 0}{
				server.stopRecording;
				"Recording stopped".postln;
			}
			{val == 1}{
				server.record(bus:outBus, numChannels: 2);
				"Recording starting".postln;
			}
		});

		flow.nextLine;

		Button(window.view,(flow.bounds.width/2) - flow.margin.x@30)
		.states_([["START CALIBRATE",Color.black, Color.green],["STOP CALIBRATE",Color.black, Color.red]])
		.action_({ |state|
			var val = state.value;

			case
			{val == 0}{ this.stopCalibrate }
			{val == 1}{ this.calibrate }
		});

		Button(window.view,(flow.bounds.width/2) - flow.gap.x - flow.margin.x@30)
		.states_([["START EIDOLON",Color.black, Color.green],["STOP EIDOLON",Color.black, Color.red]])
		.action_({ |state|
			var val = state.value;

			case
			{val == 0}{ this.stop }
			{val == 1}{ this.play }
		});

		flow.gap_(0@16);
		flow.nextLine;
		flow.gap_(4@4);

		/* ======= threshSliders ========= */

		dbSlider.("SILENCE THRESH",{ |slider|
			var amp = slider.value.dbamp;
			Ndef(\listener).set(\silenceThresh,amp);
		});
		linSlider.("ONSET THRESH",{ |slider|
			var thresh = slider.value;
			Ndef(\listener).set(\onsetThresh,thresh);
		});

		flow.left_(flow.bounds.width/2 + flow.gap.x);

		CheckBox(window,flow.bounds.width/2 - flow.gap.x - flow.margin.x@30,"verbose")
		.action_({ "doesn't do anything yet...".postln });

		window.view.background = Color.rand(0.5,1.0);
		window.onClose_({ this.stop });

		window.front;
	}
}

/*
spatMode Arg:
0 = equal power panning (channel check for stereo or PanAz)
1 = VBAP...how would this work? does it get addressed in interface?
2 = ambisonics...how would this work? does it get addressed in interface?
*/