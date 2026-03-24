package funkin.backend;

import haxe.Json;

typedef Chart = {
	var notes:Array<Section>;
	var bpm:Float;
	var speed:Float;
	var stage:String;
	var offset:Float;
	var player1:String;
	var player2:String;
	var gfVersion:String;
	var needsVoices:Bool;
	var song:String;
}

typedef Section = {
	var sectionNotes:Array<Dynamic>;
	var gfSection:Bool;
	var mustHitSection:Bool;
	var changeBPM:Bool;
	var bpm:Float;
	var sectionBeats:Int;
	var ?lengthInSteps:Int;
}

class Song {
	public static function getDummy():Chart {
		return {
			notes: [],
			bpm: 120,
			speed: 1.0,
			stage: 'stage',
			offset: 20,
			player1: 'bf',
			player2: 'bf',
			gfVersion: 'gf',
			needsVoices: false,
			song: 'Unknown'
		}
	}

	public static function loadFromPath(path:String):Chart {
		var chart = getDummy();
		if (!FileSystem.exists(path)) return chart;

		var file = Json.parse(File.getContent(path)).song;

		//chart = cast file; FUCK
		for (field in Reflect.fields(file)) {
			if (!Reflect.hasField(chart, field)) continue;

			Reflect.setField(chart, field, Reflect.field(file, field));
		}

		// FUCK 2
		//chart.notes = cast file.notes;

		return chart;
	}

	function getSectionBeats(section:Section) {
		return section.sectionBeats ?? Math.floor(section.lengthInSteps * 0.25);
	}
}