EIDOLONSynthLib {

	var <subLibs;

	*new { |includeSubLib|
		^super.new.init(includeSubLib)
	}

	init { |subLibKeys|
		var pathToSubLibs = Platform.userExtensionDir +/+ "EIDOLON" +/+ "synthLibs";
		subLibs = IdentityDictionary();

		if(subLibKeys.isNil,{
			PathName(pathToSubLibs).entries.do({ |entry|
				var key = entry.fileNameWithoutExtension.asSymbol;
				subLibs.put(key, entry.fullPath.load);
			})
		},{
			subLibKeys.asArray.do({ |key|
				var path = 	pathToSubLibs +/+ "%.scd".format(key.asString);
				subLibs.put(key.asSymbol, path.load);
			});
		});
	}

	keys { ^subLibs.keys }

}