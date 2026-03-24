package funkin.states;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxObject;
import flixel.effects.FlxFlicker;

class MainMenuState extends FunkinState {
	var mouseControls:Bool = true;
	static var curSelected:Int = 0;
	final options:Array<String> = [
		'story mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		#if AWARDS_ALLOWED 'awards', #end
		'credits',
		'options'
	];

	var optionGrp:FlxSpriteGroup;
	var camFollow:FlxObject;

	var atlas:FlxAtlasFrames = null;
	override function create():Void {
		atlas = Paths.multiAtlas([for (i in options) 'menus/main/$i']);

		add(camFollow = new FlxObject(FlxG.width * 0.5, 0, 1, 1));
		FlxG.camera.follow(camFollow, null, 0.15);

		var bg = new FlxSprite().loadGraphic(Paths.image('yellowBG'));
		bg.scrollFactor.y = 0.1;
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		add(optionGrp = new FlxSpriteGroup());

		// meth :broken_heart:
		var itemScrollY:Float = options.length < 6 ? 0 : (options.length - 4) * 0.135;
		var offset:Float = 108 - (Math.max(options.length, 4) - 4) * 80;
		for (i => option in options) {
			var item = createItem(option, 0, (i * 140) + offset);
			optionGrp.add(item);

			item.scrollFactor.set(0, itemScrollY);
			item.updateHitbox();
			item.screenCenter(X);
		}

		changeSelection();
	}

	function createItem(option:String, ?x:Float, ?y:Float):FlxSprite {
		final item = new FlxSprite(x, y);
		item.frames = atlas;
		item.animation.addByPrefix('idle', '$option idle');
		item.animation.addByPrefix('selected', '$option selected');
		item.animation.play('idle');

		return item;
	}

	var accepted:Bool = false;
	override function update(delta:Float) {
		optionGrp.update(delta);

		if (accepted) return;

		final downJustPressed:Bool = Controls.justPressed('ui_down');
		if (downJustPressed || Controls.justPressed('ui_up')) changeSelection(downJustPressed ? 1 : -1);

		if (mouseControls && (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0)) {
			for (index => option in optionGrp.members) {
				if (!FlxG.mouse.overlaps(option) || curSelected == index) continue;

				changeSelection(index, true);
				break;
			}
		}

		if (Controls.justPressed('back')) {
			FlxG.switchState(new TitleState());
		}

		if (Controls.justPressed('accept') || (mouseControls && FlxG.mouse.overlaps(optionGrp.members[curSelected]) && FlxG.mouse.justPressed)) {
			FlxG.sound.play(Paths.sfx('confirmMenu'));

			accepted = true;
			var name = options[curSelected];

			for (i => option in optionGrp.members) {
				if (i == curSelected) continue;

				FlxTween.tween(option, {alpha: 0}, 0.4, {
					ease: FlxEase.quadOut,
					onComplete: function(_) option.kill()
				});
			}

			FlxFlicker.flicker(
				optionGrp.members[curSelected], 
				1, 0.06, false, false, 
				function(_) {
					if (!canSwitch(name)) {
						reviveOptions();
						return;
					}
					goToState(name);
				}
			);
		}
	}

	// this is used for donate but since that's removed in psych it's kinda pointless
	function canSwitch(name:String):Bool {
		switch name {
/*			case 'donate':
				return false;*/
		}

		return true;
	}

	function goToState(name:String) {
		switch name {
			case 'freeplay':
				FlxG.switchState(new FreeplayState());
							
			default: reviveOptions();
		}
	}

	function reviveOptions() {
		optionGrp.members[curSelected].alpha = 0.0;
		optionGrp.members[curSelected].visible = true;
		for (i => option in optionGrp.members) {
			if (!option.exists) option.revive();
			FlxTween.tween(option, {alpha: 1.0}, 0.2 * (i + 1), {ease: FlxEase.quadIn, startDelay: 0.5});
		}
		accepted = false;
	}

	function changeSelection(?dir:Int = 0, ?usingMouse:Bool = false) {
		curSelected = usingMouse ? dir : FlxMath.wrap(curSelected + dir, 0, optionGrp.length - 1);
		var curItem = optionGrp.members[curSelected];

		// i guess i have to do this the dumb way
		var item = null;
		for (i in 0...optionGrp.length) {
			item = optionGrp.members[i];

			if (i == curSelected) {
				item.animation.play('selected');
				item.centerOffsets();
				item.screenCenter(X);
				continue;
			}

			item.animation.play('idle');
			item.updateHitbox();
			item.screenCenter(X);
		}
		item = null;

		FlxG.sound.play(Paths.sfx('scrollMenu'));
		camFollow.y = curItem.getGraphicMidpoint().y - (optionGrp.length > 4 ? optionGrp.length * 8 : 0);
	}
}