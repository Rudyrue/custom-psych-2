package funkin.backend;

@:structInit
class Judgement {
	public static var list:Array<Judgement> = [
		{
			name: 'sick', 
			timing: 45,
			score: 350,
			accuracy: 100
		},
		{
			name: 'good', 
			timing: 90, 
			score: 200,
			accuracy: 67 // just fucking kill me please
		},
		{
			name: 'bad', 
			timing: 135,
			score: 100,
			accuracy: 34
		},
		{
			name: 'shit',
			timing: 180, 
			score: 50,
			accuracy: 0
		}
	];

	public var timing:Float = 0;
	public var accuracy:Float = 0;
	public var score:Int = 0;
	public var name:String = '';
	public var hits:Int = 0;
	public var breakCombo:Bool = false;

	public static var max(get, never):Judgement;
	static function get_max():Judgement return list[list.length - 1];

	public static var min(get, never):Judgement;
	static function get_min():Judgement return list[0];

	inline public static function resetHits():Void {
		for (judge in list) judge.hits = 0;
	}

	public static function getIDFromTiming(noteDev:Float):Int {
		var value:Int = list.length - 1;

		for (i in 0...list.length) {
			if (Math.abs(noteDev) > list[i].timing) continue;
			value = i;
			break;
		}

		return value;
	}

	public static function getFromTiming(noteDev:Float):Judgement {
		var judge:Judgement = max;

		for (possibleJudge in list) {
			if (Math.abs(noteDev) > possibleJudge.timing) continue;
			judge = possibleJudge;
			break;
		}

		return judge;
	}

	public static var clearTypes:Array<String> = [
		'SFC', // All sicks
		'BF', // One good
		'SDG', // (2 or more / 9 or less) goods
		'GFC', // 10 or more goods
		'FC', // At least one bad/shit
		'MF', // One miss/combo break
		'SDCB', // (2 or more / 9 or less) misses/combo breaks
		'Clear' // 10 or more misses/combo breaks
	];
	public static function getClearType(?judges:Array<Judgement>, comboBreaks:Int) {
		judges ??= list;

		var result:String = 'N/A';

		var sicks:Int = judges[0].hits;
		var goods:Int = judges[1].hits;
		var bads:Int = judges[2].hits;
		var shits:Int = judges[3].hits;

		// you didn't hit a note !!!!!!! gRRR HIT A NOTE
		if (sicks == 0 && goods == 0 && bads == 0 && shits == 0) {
			return result;
		}

		if (comboBreaks == 0) {
			if (bads == 0 && shits == 0 && goods == 0)
				result = clearTypes[0]; // Sick Full Combo (SFC)
			else if (bads == 0 && shits == 0) {
				if (goods == 1) result = clearTypes[1]; // Black Flag (BF)
				else if (goods >= 2) result = clearTypes[2]; // Single Digit Good (SDG)
				else result = clearTypes[3]; // Good Full Combo (GFC)
			}else result = clearTypes[4]; // Full Combo (FC)
		} else if (comboBreaks < 10) {
			if (comboBreaks == 1) result = clearTypes[5]; // Miss Flag (MF)
			else result = clearTypes[6]; // Single Digit Combo Break (SDCB)
		} else result = clearTypes[7]; // Clear

		return result;
	}

	static var conditions:Array<Array<Dynamic>> = [
		[100, 'Perfect!!'],
		[90, 'Sick!'],
		[80, 'Great'],
		[70, 'Good'],
		[69, 'Nice'],
		[60, 'Meh'],
		[50, 'Bruh'],
		[40, 'Bad'],
		[20, 'Shit'],
		[0, 'You Suck!']
	];
	public static function getRank(accuracy:Float):String {
		var result:String = 'N/A';
		if (accuracy <= 0) return result;

		for (i in 0...conditions.length) {
			var rank:Array<Dynamic> = conditions[i];
			var condition:Float = rank[0];

			if (condition > accuracy) continue;
			result = rank[1];
			break;
		}

		return result;
	}
}