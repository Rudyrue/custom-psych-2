package funkin.states;

@:structInit
@:publicFields
class TitleData {
	var logo:Array<Float> = [-150, -100];
	var start:Array<Float> = [100, 576];
	var gf:Array<Float> = [512, 40];
	var backgroundSprite:String = '';
	var bpm:Float = 102;

	var animation:String = 'gfDance';
	var dance_left:Array<Int> = [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14];
	var dance_right:Array<Int> = [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29];
	var idle:Bool = false;
}

class TitleState extends FunkinState {
	// objects
	var gf:FlxSprite;
	var logo:FlxSprite;
	var text:FlxSprite;
	var alphabet:Alphabet;
	var titleGroup:FlxSpriteGroup;
	var ngSpr:FlxSprite;

	// title data stuff
	var gfPos:FlxPoint = FlxPoint.get();
	var gfAnimation:String = '';
	var gfLeftIndices:Array<Int> = [];
	var gfRightIndices:Array<Int> = [];
	var gfIdle:Bool = false;

	var startPos:FlxPoint = FlxPoint.get();
	var logoPos:FlxPoint = FlxPoint.get();
	var bpm:Float = 0;
	var backgroundSprite:String = '';

	// other variables
	var curWacky:Array<String> = [];
	var textColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var textAlphas:Array<Float> = [1, .64];
	var seenIntro:Bool = false;
	var accepted:Bool = false;
	override function create():Void {
		FunkinState.skipNextTransOut = true;

		super.create();
		persistentUpdate = true;
		
		loadJsonData();
		curWacky = FlxG.random.getObject(getIntroTexts());

		Conductor.bpm = bpm;

		add(titleGroup = new FlxSpriteGroup());

		titleGroup.add(gf = new FlxSprite(gfPos.x, gfPos.y));
		gf.frames = Paths.sparrowAtlas('menus/title/gfDanceTitle');
		if (gfIdle) {
			gf.animation.addByPrefix('idle', gfAnimation, 24, false);
			gf.animation.play('idle');
		} else {
			gf.animation.addByIndices('danceLeft', gfAnimation, gfLeftIndices, '', 24, false);
			gf.animation.addByIndices('danceRight', gfAnimation, gfRightIndices, '', 24, false);
			gf.animation.play('danceLeft');
		}

		titleGroup.add(logo = new FlxSprite(logoPos.x, logoPos.y));
		logo.frames = Paths.sparrowAtlas('menus/title/logoBumpin');
		logo.animation.addByPrefix('fuck', 'logo bumpin', 24, false);
		logo.animation.play('fuck');

		titleGroup.add(text = new FlxSprite(startPos.x, startPos.y));
		text.frames = Paths.sparrowAtlas('menus/title/pressEnter');
		text.animation.addByPrefix('idle', 'ENTER IDLE', 0, false);
		text.animation.addByPrefix('pressed', 'ENTER PRESSED', 24, true);
		text.animation.play('idle');

		if (seenIntro) return;

		ngSpr = new FlxSprite(0, FlxG.height - 346).loadGraphic(Paths.image('newgrounds_logo'));
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Math.floor(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);

		add(alphabet = new Alphabet(0, 200, '', BOLD, CENTER));
		alphabet.fieldWidth = FlxG.width;

		playMenuMusic();
		
		Conductor.inst.fadeIn(4, 0, 0.7);
		titleGroup.visible = false;
	}

	function loadJsonData() {
		function getFile() {
			var result:TitleData = {};

			if (!Paths.exists('data/gfDanceTitle.json')) return result;

			var file = Json.parse(Paths.getFileContent('data/gfDanceTitle.json'));
			for (field in Reflect.fields(file)) {
				if (!Reflect.hasField(result, field)) continue;

				Reflect.setField(result, field, Reflect.field(file, field));
			}

			return result;
		}

		var data = getFile();

		gfPos.set(data.gf[0], data.gf[1]);
		gfAnimation = data.animation;
		gfLeftIndices = data.dance_left;
		gfRightIndices = data.dance_right;
		gfIdle = data.idle;

		startPos.set(data.start[0], data.start[1]);
		logoPos.set(data.logo[0], data.logo[1]);
		backgroundSprite = data.backgroundSprite;
		bpm = data.bpm;
	}

	var titleTimer:Float = 0;
	function updateText(elapsed:Float) {
		if (!seenIntro || accepted) return;

		titleTimer += FlxMath.bound(elapsed, 0, 1);
		if (titleTimer > 2) titleTimer -= 2;

		var timer:Float = titleTimer;
		if (timer >= 1) timer = -timer + 2;
				
		timer = FlxEase.quadInOut(timer);
				
		text.color = FlxColor.interpolate(textColors[0], textColors[1], timer);
		text.alpha = FlxMath.lerp(textAlphas[0], textAlphas[1], timer);
	}

	var time:Float = 0.0;
	override function update(elapsed:Float) {
		titleGroup.update(elapsed);
		if (alphabet != null) alphabet.update(elapsed);

		updateText(elapsed);

		if (Controls.justPressed('accept') || FlxG.mouse.justPressed) {
			if (accepted) {
				FunkinState.switchState(new MainMenuState());
				return;
			}

			if (!seenIntro) skipIntro();
			else {
				accepted = true;
				FlxG.camera.flash(FlxColor.WHITE, 1);
				FlxG.sound.play(Paths.audio('confirmMenu', 'sfx'), 0.7);
				text.color = FlxColor.WHITE;
				text.alpha = 1;
				text.animation.play('pressed');
				new FlxTimer().start(2, function(_) {
					FunkinState.switchState(new MainMenuState());
				});
			}
		}
	}

	function getIntroTexts():Array<Array<String>> 
		return [for (i in Paths.text('data/introText.txt').split('\n')) i.split('--')];

	var curBeat:Int = 0;
	override function beatHit(_) {
		curBeat++;

		logo.animation.play('fuck', true);
		if (gfIdle) {
			gf.animation.play('idle');
		} else gf.animation.play('dance${curBeat % 2 == 0 ? 'Left' : 'Right'}', true);

		if (seenIntro) return;

		switch curBeat {
			case 1:
				alphabet.y += 40;
				alphabet.text += 'Psych Engine by';
			case 3:
				alphabet.text += '\nShadow Mario\nRiveren';
			case 4:
				alphabet.text = '';
			case 5:
				alphabet.y -= 40;
				alphabet.text += 'Not associated\nwith';
			case 7:
				alphabet.text += '\nNewgrounds';
				ngSpr.visible = true;
			case 8:
				alphabet.text = '';
				ngSpr.visible = false;
			case 9:
				alphabet.text += curWacky[0];
			case 11:
				alphabet.text += '\n${curWacky[1]}';
			case 12:
				alphabet.text = '';
			case 13:
				alphabet.text += 'Friday';
			case 14:
				alphabet.text += '\nNight';
			case 15:
				alphabet.text += '\nFunkin';
			case 16:
				skipIntro();
		}
	}

	function skipIntro() {
		if (seenIntro) return;
		seenIntro = true;
		FlxG.camera.flash(FlxColor.WHITE, 2);
		if (Conductor.inst.fadeTween != null) Conductor.inst.fadeTween.cancel();
		Conductor.inst.volume = 0.7;

		titleGroup.visible = true;
		remove(ngSpr);
		remove(alphabet);
		alphabet.destroy();
		alphabet = null;
	}
}