{ | eidolonInstance |

	var transforms = eidolonInstance.synthLib;
	var memory = eidolonInstance.memory;
	var recBufs = eidolonInstance.recBuffers;
	var bufIndex = eidolonInstance.recIndex;


	var verbose = true;

	OSCdef(\listener,{ |msg, time, addr, recvPort|
		var currentAmp     = msg[3].ampdb;
		var recentAmp      = memory['pastAmp'][..memLength].median;
		var currentSilence = msg[4];
		var recentSilence  = memory['pastSilence'][..memLength].mean;


		var state;

		/* =======  determine state  ========= */


		/* =======  state behaviour ========= */

		switch(state,
			"support",{

				// parse the analysis to determine if material is predominantely pitch, transients, silence, etc. Maybe these classifiers need to be better??
				// case/switch to determine if the

			},
			"contrast",{},
			"ignore",	{

				case                                                                                                             // should this have a default case
				{ (memory['state'].indicesOfEqual("ignore") ? 0).asArray.last % (pollRateScale * 60 * 3) == 1 }{                 // after 3 minutes(?) it should be silent for a bit?

					transforms.values.collect({ |subDicts|
						subDicts.keysDo({ |subDictKey|
							if(Ndef((subDictKey ++ playerIndex).asSymbol).isPlaying,{ Ndef((subDictKey ++ playerIndex).asSymbol).end(fadeTime) })
						})
					});
				}
				{ (memory['state'].indicesOfEqual("ignore") ? 0).asArray.last % (pollRateScale * 60 * 1.5) == 2 }{
					var dict = transforms.keys.choose;
					var key = transforms[dict].keys.choose;
					var playerKey = (key ++ playerIndex);

					transforms.values.collect({ |subDicts|
						subDicts.keysDo({ |subDictKey|
							if(Ndef((subDictKey ++ playerIndex).asSymbol).isPlaying,{
								Ndef((subDictKey ++ playerIndex).asSymbol).end(fadeTime);
								"% OFF".format(subDictKey ++ playerIndex).postln;
							});
						})
					});

					if(Ndef(playerKey.asSymbol).isPlaying.not,{
						Ndef(playerKey.asSymbol,transforms[dict][key]).play(switcherBus,numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
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

			},
			"tacet",{},
			"tacetDone",{}
		);

		/* =======  cycle synths ========= */

		(
			~synthKeys[playerIndex].keysDo({ |key|

				var synthKey = (~synthKeys[playerIndex][key].first ++ playerIndex);

				if(Ndef(synthKey.asSymbol).isPlaying.not and: { (memory['events'].indicesOfEqual(synthKey) ? 0).asArray.last > (pollRateScale * (performanceLength/5)) },{
					~synthKeys[playerIndex][key] = ~synthKeys[playerIndex][key].rotate(-1);
					"rotating %, introducing %".format(synthKey,~synthKeys[playerIndex][key].first).postln;
				});
			})
		);

		/* =======  update memory ========= */

	},'/analysis')
}