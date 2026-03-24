package funkin.objects;

import funkin.objects.Strumline;
import funkin.objects.Strumline.StrumNote;
import funkin.objects.Sustain;
import funkin.shaders.NoteShader;

@:structInit
@:publicFields
class NoteData {
	var time:Float = 0.0;
	var lane:Int = 0;
	var player:Int = 0;
	var length:Float = 0.0;
	var type:String = '';
}

class Note extends FlxSprite {
	public static var defaultTypes:Array<String> = [
		'', // Always leave this one empty pls
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'GF Sing',
		'No Animation'
	];

	public static var colourShader = new NoteShader();

	public var time(get, never):Float;
	function get_time():Float {
		return rawTime - Settings.data.noteOffset;
	}

	public var hitTime(get, never):Float;
	function get_hitTime():Float {
		return time - Conductor.time;
	}

	public var wasHit:Bool = false;
	public var canHit:Bool = true;
	public var missed:Bool = false;
	public var inHitRange(get, never):Bool;
	function get_inHitRange():Bool {
		final early:Bool = time < Conductor.rawTime + (180);
		final late:Bool = time > Conductor.rawTime - (180);

		return early && late;
	}

	public var hittable(get, never):Bool;
	function get_hittable():Bool return exists && inHitRange && canHit && !missed;

	public var tooLate(get, never):Bool;
	function get_tooLate():Bool {
		return hitTime < -(180 + 25);
	}

	public var rawTime:Float = 0.0;
	public var lane:Int = 0;
	public var length:Float = 0.0;
	public var player:Int = 0;
	public var type:String = '';

	public var distance:Float;

	public var sustain:Sustain;

	public var data:NoteData = null;
	public function new() {
		super();

		data = {};
		active = false;
	}

	public function setup(data:NoteData):Note {
		this.data = data;

		wasHit = false;
		missed = false;
		sustain = null;

		rawTime = data.time;
		lane = data.lane;
		length = data.length;
		player = data.player;
		type = data.type;

		applyFrames();

		return this;
	}

	function applyFrames() {
		frames = Paths.sparrowAtlas('funkin');

		animation.addByPrefix('_', '${Util.colours[lane].toLowerCase()}0');
		animation.play('_');

		scale.set(Strumline.actualSize, Strumline.actualSize);
		updateHitbox();
	}

	public function followStrum(strum:StrumNote, ?speed:Float = 1.0) {
		distance = (hitTime * 0.45 * speed);

		x = strum.x;
		y = strum.y + distance;
	}
}