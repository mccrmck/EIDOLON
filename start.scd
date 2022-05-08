










// must fix no Buf synths in first ignore!
// must fix the synth rotation condition!
// brokenRec doesn't work?
//too much tacet - osciallting between support and tacet nearly...should maybe make things fade?
// should poll rate be faster?


e = EIDOLON(0,0,60 * 5,10)

e.analBus.get
e.memory

e.waitBeforeStartTime
e.synthArrays

Ndef(\listener).inspect

nil < 10

y = IdentityDictionary();

j = EIDOLONSynthLib();
j.subLibs.keysValuesDo({ |subLibKey,subLib| y.put(subLibKey,subLib.keys.asArray) });

j
f = j.keys.choose
j.subLibs[f.asSymbol]


m = 4 * 300 * 0.15
m = 10

(e.memory['events'][..167].indicesOfEqual('pitchShift') ? 0).asArray.last % 167 == 0
