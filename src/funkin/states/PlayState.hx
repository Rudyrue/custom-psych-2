package funkin.states;

import flixel.FlxState;
import funkin.objects.Strumline;
import funkin.objects.PlayField;
import funkin.objects.Countdown;
import funkin.objects.Bar;
import funkin.objects.CharIcon;
import funkin.objects.JudgementSpr;
import funkin.objects.ComboNums;
import funkin.objects.Note;
import funkin.substates.PauseMenu;
import funkin.backend.Judgement;
import flixel.util.FlxStringUtil;

class PlayState extends FunkinState {
	public static var self:PlayState;

	public static var songID:String = 'guy';
	public var songName:String;
	var difficulty:String = 'hard';
	static var chart:Chart;

	var playerID(get, never):Int;
	function get_playerID():Int {
		if (playfield == null) return 0;
		return playfield.playerID;
	}

	var combo:Int = 0;
	var score:Int = 0;
	var comboBreaks:Int = 0;
	var accuracy:Float = 0.0;
	var totalNotesHit:Int = 0;
	var totalNotesPlayed:Float = 0.0;
	var health(default, set):Float = 50;
	function set_health(v:Float):Float {
		v = FlxMath.bound(v, 0, 100);

		health = v;
		healthBar.updatePercent();

		updateIconStates();
		updateIconPositions();

		return v;
	}

	var playfield:PlayField;
	var countdown:Countdown;
	var skipCountdown:Bool = false;

	var hud:FlxSpriteGroup;
	override function create():Void {
		super.create();
		self = this;

		var opponentLine = new Strumline(320, 50);
		var playerLine = new Strumline(960, 50, false);

		add(playfield = new PlayField([opponentLine, playerLine], 1));
		playfield.noteHit = noteHit;
		playfield.noteMiss = noteMiss;
		loadSong(songID, difficulty);

		add(hud = new FlxSpriteGroup());
		loadHUD();

		add(countdown = new Countdown());
		countdown.screenCenter();
		countdown.onStart = function() {
			Conductor.playing = true;
		}
		countdown.onFinish = function() {
			Conductor.play();
			updateTime = true;
		}

		if (skipCountdown) {
			countdown.finished = true;
			countdown.onFinish();
		} else {
			Conductor.time = (Conductor.crotchet * -4);
			countdown.starting = true;
			countdown.start();
		}
	}

	var healthBar:Bar;
	var iconP1:CharIcon;
	var iconP2:CharIcon;
	var infoText:FlxText;
	var timeBar:Bar;
	var timeText:FlxText;
	var judgeSprite:JudgementSpr;
	var comboNumbers:ComboNums;
	function loadHUD() {
		if (hud == null) return;
		hud.clear();

		hud.add(timeBar = new Bar(
			0, 19, // x, y
			function() return Math.max(0, Conductor.inst.time), // percent
			0, Conductor.length, // min, max
			'ui/timeBar', 'ui/timeBar-fill' // background, fill
		));
		timeBar.setColors(FlxColor.WHITE, FlxColor.BLACK);
		timeBar.screenCenter(X);

		hud.add(timeText = new FlxText(0, 0, timeBar.width, '2:30', 32));
		timeText.font = Paths.font('vcr.ttf');
		timeText.alignment = 'center';
		timeText.borderStyle = FlxTextBorderStyle.OUTLINE;
		timeText.borderSize = 2;
		timeText.borderColor = FlxColor.BLACK;

		timeText.x = timeBar.getMidpoint().x - (timeText.width * 0.5);
		timeText.y = timeBar.getMidpoint().y - (timeText.height * 0.5);
		updateTimeText(true);

		hud.add(healthBar = new Bar(
			0, 648, // x, y
			function() return health, // percent
			0, 100, // min, max
			'ui/healthBar', 'ui/healthBar-fill' // background, fill
		));
		healthBar.leftToRight = false;
		healthBar.setColors(FlxColor.RED, FlxColor.LIME);
		healthBar.screenCenter(X);

		hud.add(iconP1 = new CharIcon('face', true));
		iconP1.y = healthBar.y - (iconP1.height * 0.5);

		hud.add(iconP2 = new CharIcon('face'));
		iconP2.y = healthBar.y - (iconP2.height * 0.5);

		updateIconPositions();

		hud.add(infoText = new FlxText(0, FlxG.height - 39, FlxG.width, '', 20));
		infoText.font = Paths.font('vcr.ttf');
		infoText.alignment = 'center';
		infoText.borderStyle = FlxTextBorderStyle.OUTLINE;
		infoText.borderSize = 1.25;
		infoText.borderColor = FlxColor.BLACK;
		updateInfo();
		infoText.screenCenter(X);

		hud.add(judgeSprite = new JudgementSpr(400, 300));
		hud.add(comboNumbers = new ComboNums(400, 425));
	}

	var updateTime:Bool = false;
	var whatTheFuckDoICallThis:Float = 0.0;
	dynamic function updateTimeText(?forced:Bool = false) {
		if (forced || (updateTime && whatTheFuckDoICallThis >= 1)) {
			timeText.text = FlxStringUtil.formatTime(Conductor.inst.time * 0.001);
			whatTheFuckDoICallThis = 0;
		}
	}

	var iconSpacing:Float = 20;
	dynamic function updateIconPositions():Void {
		iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconSpacing;
		iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconSpacing * 2;
	}

	dynamic function updateIconScales(delta:Float):Void {
		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, Math.exp(-delta * 9));
		iconP1.scale.set(mult, mult);
		iconP1.centerOrigin();

		mult = FlxMath.lerp(1, iconP2.scale.x, Math.exp(-delta * 9));
		iconP2.scale.set(mult, mult);
		iconP2.centerOrigin();
	}

	dynamic function updateIconStates() {
		iconP1.animation.curAnim.curFrame = healthBar.percent < 20 ? 1 : 0; //If health is under 20%, change player icon to frame 1 (losing icon), otherwise, frame 0 (normal)
		iconP2.animation.curAnim.curFrame = healthBar.percent > 80 ? 1 : 0; //If health is over 80%, change opponent icon to frame 1 (losing icon), otherwise, frame 0 (normal)
	}

	dynamic function updateInfo() {
		var scoreStr:String = Std.string(score);
		var comboBreaksStr:String = Std.string(comboBreaks);
		var accuracyStr:String = '${Util.truncateFloat(accuracy)}%';
		var clearType:String = Judgement.getClearType(null, comboBreaks);
		var rank:String = Judgement.getRank(accuracy);

		//infoText.text = 'Score: $scoreStr | Misses: $comboBreaksStr | Rating: $rank ($accuracyStr) - $clearType';
		infoText.text = 'Score: $scoreStr | Combo Breaks: $comboBreaksStr | $accuracyStr [$clearType | $rank]';
	}

	function noteHit(line:Strumline, note:Note) {
		//singCharacter(strumline.character(), 'sing', note.lane);

		if (note.player != playerID) return;

		var judge = Judgement.getFromTiming(note.hitTime);

		judge.hits++;
		health += 2;
		score += judge.score;
		totalNotesPlayed += judge.accuracy;
		totalNotesHit++;
		accuracy = updateAccuracy();

		updateInfo();

		judgeSprite.display(note.hitTime);
		comboNumbers.display(++combo);
	}

	function noteMiss(line:Strumline, note:Note) {
		score -= 10;
		comboBreaks++;
		combo = 0;
		health -= 5;
		accuracy = updateAccuracy();

		updateInfo();
	}

	function updateAccuracy() {
		return totalNotesPlayed / (totalNotesHit + comboBreaks);
	}

	function loadSong(id:String, difficulty:String) {
		chart = Song.loadFromPath(Paths.get('songs/$id/$difficulty.json'));
		songName = chart.song;

		Conductor.inst = FlxG.sound.load(Paths.audio('songs/$id/Inst'));
		Conductor.inst.onComplete = endSong;

		Conductor.voices = FlxG.sound.load(Paths.audio('songs/$id/Voices'));
		Conductor.bpm = chart.bpm;

		playfield.load(chart);
	}

	public function endSong() {
		FlxG.switchState(new FreeplayState());
		playMenuMusic();
	}

	override function update(delta:Float) {
		super.update(delta);

		whatTheFuckDoICallThis += delta;
		updateTimeText();
		updateIconScales(delta);
		updateIconPositions();

		if (FlxG.keys.justPressed.F8) playfield.botplay = !playfield.botplay;
		if (Controls.justPressed('pause')) openPauseMenu();
	}

	function openPauseMenu() {
		FlxTween.globalManager.forEach(function(twn:FlxTween) if (twn != null)
			twn.active = false);
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (tmr != null)
			tmr.active = false);

		Conductor.pause();
		persistentUpdate = false;
		var menu = new PauseMenu(songName, difficulty, 0);
		openSubState(menu);
	}

	override function destroy() {
		super.destroy();
		self = null;
	}

	override function beatHit(beat:Int) {
		iconP1.scale.set(1.2, 1.2);
		iconP1.updateHitbox();

		iconP2.scale.set(1.2, 1.2);
		iconP2.updateHitbox();
	}
}