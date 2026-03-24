package funkin.backend;

@:structInit
@:publicFields
class SaveVariables {
	var noteOffset:Float = -60;
}

class Settings {
	public static var data:SaveVariables = {};
	public static final default_data:SaveVariables = {};

	public static function save() {

	}

	public static function load() {
	
	}

	public static function reset(?saveToDisk:Bool = false) {
		
	}
}