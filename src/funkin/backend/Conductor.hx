package funkin.backend;

import flixel.FlxG;
import flixel.sound.FlxSound;
import flixel.util.FlxSignal;

class Conductor extends flixel.FlxBasic {
	public static var inst(default, set):FlxSound;
    static function set_inst(value:FlxSound):FlxSound {
        if (inst != null) {
            inst.stop();
            inst.destroy();
            FlxG.sound.list.remove(inst);
            if (value == null) return inst = null;
        }

        value.persist = true;
        length = value.length;
        return inst = value;
    }

	public static var voices:FlxSound;
	public static final vocalResyncDiff:Float = 10.0;

	public static var rawTime:Float = 0;
	public static var visualTime:Float = 0;
	public static var length:Float = 0;
	public static var offset:Float = 0;
	public static var metronome:Bool = false;
	public static var playing:Bool = false;

	public static var stepHit:FlxTypedSignal<Int -> Void>;
	public static var beatHit:FlxTypedSignal<Int -> Void>;
	public static var measureHit:FlxTypedSignal<Int -> Void>;

	// beat METH
	public static var bpm(default, set):Float = 120;
	static function set_bpm(v:Float):Float {
		crotchet = (60 / v) * 1000;
		stepCrotchet = crotchet * 0.25;

		return bpm = v;
	}

	public static var crotchet:Float = (60 / bpm) * 1000;
	public static var stepCrotchet:Float = crotchet * 0.25;

	public static var measure:Int = -1;
	public static var floatMeasure:Float = measure;

	public static var beat:Int = -1;
	public static var floatBeat:Float = beat;

	public static var step:Int = -1;
	public static var floatStep:Float = step;

	public function new() {
		super();
		visible = false;
		stepHit = new FlxTypedSignal<Int -> Void>();
		beatHit = new FlxTypedSignal<Int -> Void>();
		measureHit = new FlxTypedSignal<Int -> Void>();
		reset();
	}

	public static function reset() {
		bpm = 120;
		floatMeasure = measure = -1;
		floatBeat = beat = -1;
		floatStep = step = -1;

		rawTime = visualTime = time = 0.0;
		offset = 0.0;

		if (voices != null) voices.destroy();
		voices = null;

		playing = false;

		stepHit.removeAll();
		beatHit.removeAll();
		measureHit.removeAll();
	}

	override function update(delta:Float) {
		if (!playing) return;

		syncTime(delta);
		syncVoices();
		syncBeats();
	}

	public static var time:Float = 0; // used if the inst isn't playing but playing is still set to true
	static var _lastTime:Float = 0;
	public static dynamic function syncTime(delta:Float) {
		delta *= 1000;
		if (inst == null || !inst.playing) {
			time += delta;
			rawTime = time + offset;
			visualTime = rawTime;
			return;
		}

		time = inst.time;
		rawTime = time + offset;
		
		if (inst.time == _lastTime) {
			visualTime += delta;
		} else {
			if (Math.abs(rawTime - visualTime) >= delta)
				visualTime = rawTime;
			else
				visualTime += delta;

			_lastTime = inst.time;
		}
	}

	public static dynamic function syncVoices() {
		if (inst == null || !inst.playing) return;
		if (voices == null || !voices.playing) return;

		final instTime:Float = inst.time;
		if (voices.length < instTime) return;

		if (Math.abs(voices.time - instTime) > vocalResyncDiff)
			voices.time = instTime;
	}

	public static dynamic function syncBeats() {
		var lastMeasure:Int = measure;
		var lastBeat:Int = beat;
		var lastStep:Int = step;

		floatBeat = rawTime / crotchet; //getBeatFromTime(rawTime) + ((rawTime - point.time) / crotchet);
		floatStep = floatBeat * 4;
		floatMeasure = floatBeat * 0.25;

		var newMeasure:Int = Math.floor(floatMeasure);
		var newBeat:Int = Math.floor(floatBeat);
		var newStep:Int = Math.floor(floatStep);

		if (newBeat != lastBeat) {
			if (metronome) FlxG.sound.play(openfl.media.Sound.fromFile('assets/metronome.ogg'));
			beatHit.dispatch(beat = newBeat);
		}

		if (newStep != lastStep) {
			stepHit.dispatch(step = newStep);
		}

		if (newMeasure != lastMeasure) {
			measureHit.dispatch(measure = newMeasure);
		}
	}

    public static function stop() {
		playing = false;
        inst.stop();
        if (voices != null) voices.stop();
    }

    public static function play() {
		playing = true;
        inst.play();
        if (voices != null) voices.play();
    }

    public static function pause() {
		playing = false;
        inst.pause();
        if (voices != null) voices.pause();
    }

    public static function resume() {
		playing = true;
        inst.resume();
        if (voices != null) voices.resume();
    }
}