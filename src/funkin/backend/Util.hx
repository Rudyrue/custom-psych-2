package funkin.backend;

class Util {
	public static final directions:Array<String> = [
		'Left',
		'Down',
		'Up',
		'Right'
	];

	public static final colours:Array<String> = [
		'Purple',
		'Blue',
		'Green',
		'Red'
	];

	static final units:Array<String> = [
		'Bytes',
		'KB',
		'MB',
		'GB',
		'TB',
		'PB'
	];

	public static function isLetter(c:String) { // thanks kade
		var ascii:Int = StringTools.fastCodeAt(c, 0);
		return (ascii >= 65 && ascii <= 90) || (ascii >= 97 && ascii <= 122) || (ascii >= 192 && ascii <= 214) || (ascii >= 216 && ascii <= 246)
			|| (ascii >= 248 && ascii <= 255);
	}

	// FlxStringUtil.formatBytes() but it just adds a space between the size and the unit lol
	public static function formatBytes(bytes:Float, ?precision:Int = 2):String {
		var curUnit:Int = 0;
		while (bytes >= 1024 && curUnit < units.length - 1) {
			bytes /= 1024;
			curUnit++;
		}

		return '${FlxMath.roundDecimal(bytes, precision)} ${units[curUnit]}';
	}

	public static inline function format(string:String):String
		return string.toLowerCase().replace(' ', '-');

	/**
		Helper Function to Fix Save Files for Flixel 5

		-- EDIT: [November 29, 2023] --

		this function is used to get the save path, period.
		since newer flixel versions are being enforced anyways.
		@crowplexus
	**/
	@:access(flixel.util.FlxSave.validate)
	inline public static function getSavePath():String {
		final company:String = FlxG.stage.application.meta.get('company');
		final file:String = FlxG.stage.application.meta.get('file');

		return '${company}/${flixel.util.FlxSave.validate(file)}';
	}

	public static function truncateFloat(number:Float, precision:Float = 2):Float {
		number *= (precision = Math.pow(10, precision));
		return Math.floor(number) / precision;
	}
}