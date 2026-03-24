package funkin;

class FunkinState extends flixel.FlxState {
	override function create() {
		FlxG.camera.bgColor = 0x00;
		Conductor.reset();

		Conductor.stepHit.add(stepHit);
		Conductor.beatHit.add(beatHit);
		Conductor.measureHit.add(measureHit);
	}

	function playMenuMusic() {
		Conductor.inst = FlxG.sound.load(Paths.audio('freakyMenu', 'music'), 0.7, true);
		Conductor.play();
	}

	function stepHit(step:Int) {}
	function beatHit(beat:Int) {}
	function measureHit(measure:Int) {}
}