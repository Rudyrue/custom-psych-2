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

	// basically an internal placeholder
	// for whether the song has actually started playing or not
	// different from `playing`
	static var _songPlaying:Bool = false;

	static var _rawTime:Float = 0.0;
	@:isVar public static var rawTime(get, set):Float;
	static function get_rawTime():Float {
		if (inst == null || !inst.playing) {
			return _rawTime + offset;
		}

		return inst.time + offset;
	}

	static function set_rawTime(v:Float):Float {
		if (inst == null) return _rawTime = v;
		if (!inst.playing) {
			_rawTime = v;
			return _songPlaying ? inst.time = v : v;
		}

		return inst.time = v;
	}

	public static var time:Float = 0;

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

		rawTime = time = time = 0.0;
		offset = 0.0;

		if (voices != null) voices.destroy();
		voices = null;

		_songPlaying = false;
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

	static var _lastTime:Float = 0;
	public static dynamic function syncTime(delta:Float) {
		delta *= 1000;
		if (inst == null || !inst.playing) {
			_rawTime += delta;
			time = rawTime;
			return;
		}
		
		if (inst.time == _lastTime) {
			time += delta;
		} else {
			if (Math.abs(rawTime - time) >= delta)
				time = rawTime;
			else
				time += delta;

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
		_songPlaying = false;

		playing = false;
        inst.stop();
        if (voices != null) voices.stop();
    }

    public static function play() {
		_songPlaying = true;

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