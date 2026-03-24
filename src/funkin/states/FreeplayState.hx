package funkin.states;

import funkin.objects.CharIcon;

typedef SongData = {
	var id:String;
}

class FreeplayState extends FunkinState {
	var list:Array<SongData> = [];
	var grpSongs:FlxTypedSpriteGroup<Alphabet>;
	var grpIcons:FlxTypedSpriteGroup<CharIcon>;
	static var curSelected:Int = 0;
	static var curDifficulty:Int = 0;
	var totalSongIndex:Int = -1;

	var curSong(get, never):SongData;
	function get_curSong():SongData return list[curSelected];

	override function create():Void {
		super.create();

		var bg = new FlxSprite(0, 0, Paths.image('blueBG'));
		bg.screenCenter();
		add(bg);

		add(grpSongs = new FlxTypedSpriteGroup<Alphabet>());
		add(grpIcons = new FlxTypedSpriteGroup<CharIcon>());

		for (line in FileSystem.readDirectory('assets/songs')) {
			list.push({
				id: line
			});

			addSong(line, 'face');
		}

		changeSelection();

		curDifficulty = Difficulty.list.indexOf(Difficulty.current);
		changeDifficulty();

		persistentUpdate = true;
		FlxG.mouse.visible = true;
	}

	function addSong(name:String, ?icon:String) {
		totalSongIndex++;

		var alphabet = new Alphabet(90, 320, name);
		alphabet.isMenuItem = true;
		alphabet.scaleX = Math.min(1, 980 / alphabet.width);
		alphabet.snapToPosition();
		alphabet.targetY = totalSongIndex;
		grpSongs.add(alphabet);

		grpIcons.add(new CharIcon(icon));
	}

	var holdTime:Float;
	var intendedScore:Int;
	var lerpScore:Int;
	override function update(elapsed:Float) {
		grpSongs.update(elapsed);

		var icon = null;
		for (i in 0...grpIcons.length) {
			icon = grpIcons.members[i];
			var item = grpSongs.members[i];

			icon.setPosition(item.x + (item.width + (icon.width * 0.05)), item.y - (item.height * 0.5));
		}

		if (Controls.justPressed('back') || FlxG.mouse.justPressedRight) {
			FunkinState.switchState(new MainMenuState());
			FlxG.sound.play(Paths.sfx('cancelMenu'));
		}

		songControls(elapsed);
		difficultyControls();
	}

	function songControls(elapsed:Float) {
		var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;

		final downJustPressed:Bool = Controls.justPressed('ui_down');
		if (downJustPressed || Controls.justPressed('ui_up')) {
			changeSelection(downJustPressed ? shiftMult : -shiftMult);
			holdTime = 0;
		}

		final downPressed:Bool = Controls.pressed('ui_down');
		if (downPressed || Controls.pressed('ui_up')) {
			var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
			holdTime += elapsed;
			var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

			if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
				changeSelection((checkNewHold - checkLastHold) * (downPressed ? shiftMult : -shiftMult));
		}

		if (FlxG.mouse.wheel != 0) changeSelection(-shiftMult * FlxG.mouse.wheel, 0.2);

		if (Controls.justPressed('accept') || FlxG.mouse.justPressed) {
			PlayState.songID = curSong.id;
			Difficulty.current = Difficulty.list[curDifficulty];
			FunkinState.switchState(new PlayState());
		}
	}

	function difficultyControls() {
		final leftPressed:Bool = Controls.justPressed('ui_left');
		if (leftPressed || Controls.justPressed('ui_right')) changeDifficulty(leftPressed ? -1 : 1);
	}

	function changeSelection(?change:Int = 0, ?volume:Float = 0.4) {
		curSelected = FlxMath.wrap(curSelected + change, 0, list.length - 1);
		if (volume > 0.0) FlxG.sound.play(Paths.sfx('scrollMenu'), volume);

		for (i => item in grpSongs.members) {
			item.alpha = i == curSelected ? 1 : 0.5;
			item.targetY = i - curSelected;
			grpIcons.members[i].alpha = i == curSelected ? 1 : 0.5;
		}

		changeDifficulty();
	}

	function changeDifficulty(?change:Int = 0) {

	}
}