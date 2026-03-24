package funkin.objects;

import flixel.group.FlxSpriteGroup;
import funkin.objects.Sustain;

class Strumline extends FlxTypedSpriteGroup<StrumNote> {
	public static final keyCount:Int = 4;

	public static final actualSize:Float = 0.65;
	public static var size(default, set):Float = 1.0;
	static function set_size(value:Float) {
		swagWidth = 160.0 * actualSize * value;
		return size = value;
	}
	public static var swagWidth:Float = 160.0 * actualSize * size;

	public var ai:Bool;

	public var curHolds:Array<Sustain> = [];

	public function new(?x:Float, ?y:Float, ?ai:Bool = true) {
		super(x, y);

		this.ai = ai;

		regenerate();

		// center the strumline on the x position we gave it
		// instead of basing the x position on the left side of the x axis
		this.x = x - (width * 0.5);
	}

	public function regenerate() {
		// just in case there's anything stored
		while (members.length != 0) members.pop().destroy();

		var strum:StrumNote = null;
		for (i in 0...keyCount) {
			add(strum = new StrumNote(this, i));
			strum.x += swagWidth * i;
			strum.y += (swagWidth - strum.height) * 0.5;
		}
	}
}

class StrumNote extends FlxSprite {
	public var parent:Strumline;
	public var lane:Int;
	public var isHolding:Bool = false;

	public function new(parent:Strumline, lane:Int) {
		super();

		this.parent = parent;
		this.lane = lane;

		applyFrames();

		scale.set(Strumline.actualSize, Strumline.actualSize);
		updateHitbox();

		animation.finishCallback = function(anim) {
			var waitForAnim = !parent.ai || isHolding;

			if (waitForAnim || anim != 'confirm') return;
			glow('static');
		}
	}

	function applyFrames() {
		frames = Paths.sparrowAtlas('funkin');
		animation.addByPrefix('static', 'arrow${Util.directions[lane].toUpperCase()}', 24, true);
		animation.addByPrefix('confirm', '${Util.directions[lane].toLowerCase()} confirm', 48, false);
		animation.addByPrefix('pressed', '${Util.directions[lane].toLowerCase()} press', 48, false);

		animation.play('static');
	}

	public function glow(name:String) {
		animation.play(name, true);
		centerOffsets();
		centerOrigin();
	}
}