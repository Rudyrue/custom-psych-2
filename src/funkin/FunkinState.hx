package funkin;

import funkin.substates.Transition;
import flixel.FlxState;

class FunkinState extends flixel.FlxState {
	public static var skipNextTransIn:Bool = false;
	public static var skipNextTransOut:Bool = false;

	override function create() {
		FlxG.camera.bgColor = 0x00;
		Conductor.reset();

		Conductor.stepHit.add(stepHit);
		Conductor.beatHit.add(beatHit);
		Conductor.measureHit.add(measureHit);

		if (!skipNextTransOut) openSubState(new Transition(0.5, true));
		skipNextTransOut = false;
	}

	function playMenuMusic() {
		if (Conductor.inst != null && Conductor.inst.playing) return;

		Conductor.inst = FlxG.sound.load(Paths.audio('freakyMenu', 'music'), 0.7, true);
		Conductor.play();
	}

	public static function switchState(nextState:FlxState = null) {
		nextState ??= FlxG.state;
		if (nextState == FlxG.state) {
			resetState();
			return;
		}

		if (skipNextTransIn) FlxG.switchState(nextState);
		else startTransition(nextState);
		skipNextTransIn = false;
	}

	public static function resetState() {
		if (skipNextTransIn) FlxG.resetState();
		else startTransition();
		skipNextTransIn = false;
	}

	// Custom made Trans in
	public static function startTransition(?nextState:FlxState) {
		if (nextState == null) nextState = FlxG.state;

		FlxG.state.openSubState(new Transition(0.5, false));
		Transition.onFinish = function() {
			if (nextState == FlxG.state) FlxG.resetState();
			else FlxG.switchState(nextState);
		}
	}

	public static function getState():FunkinState {
		return cast(FlxG.state, FunkinState);
	}

	function stepHit(step:Int) {}
	function beatHit(beat:Int) {}
	function measureHit(measure:Int) {}
}