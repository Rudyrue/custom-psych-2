import flixel.FlxG;
import funkin.objects.Alphabet;
import funkin.backend.Settings;
import funkin.backend.Conductor;

class InitState extends flixel.FlxState {
	override function create():Void {
		FlxG.autoPause = false;
		FlxG.fixedTimestep = false;
		//FlxG.mouse.visible = false;
		FlxG.cameras.useBufferLocking = true;
		flixel.graphics.FlxGraphic.defaultPersist = true;

		Settings.load();
		Alphabet.loadData();
		FlxG.drawFramerate = FlxG.updateFramerate = 120;

		FlxG.plugins.add(new Conductor());
		FlxG.switchState(Type.createInstance(Main.initialState, []));

		FlxG.signals.preStateSwitch.add(function() {
			Conductor.stepHit.removeAll();
			Conductor.beatHit.removeAll();
			Conductor.measureHit.removeAll();
		});
	}
}