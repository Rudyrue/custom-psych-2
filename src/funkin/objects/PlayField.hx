package funkin.objects;

import flixel.group.FlxSpriteGroup;
import funkin.objects.Strumline;
import funkin.objects.Note;
import funkin.objects.Note.NoteData;
import lime.app.Application;
import lime.ui.KeyCode;

class PlayField extends FlxSpriteGroup {
	public var strumlines:FlxTypedSpriteGroup<Strumline>;
	public var notes:FlxTypedSpriteGroup<Note>;
	public var sustains:FlxTypedSpriteGroup<Sustain>;

	public var playerID(default, set):Int;
	function set_playerID(v:Int):Int {
		currentPlayer = getStrumline(v);

		if (v >= strumlines.length) {
			return playerID;
		}

		for (i => line in strumlines.members) {
			line.ai = (v == i) ? botplay : true;
		}

		return playerID = v;
	}

	public var currentPlayer:Strumline = null;
	public var scrollSpeed:Float = 3.35;
	public var botplay(default, set):Bool = false;
	function set_botplay(v:Bool):Bool {
		currentPlayer.ai = v;
		return botplay = v;
	}

	// because `playfield.strumlines.members[id]` is a little long
	public function getStrumline(id:Int):Strumline {
		return strumlines.members[id];
	}

	public dynamic function noteHit(line:Strumline, note:Note) {}
	public dynamic function sustainHit(line:Strumline, note:Note, ?mostRecent:Bool) {}
	public dynamic function noteMiss(line:Strumline, note:Note) {}

	public function new(lines:Array<Strumline>, playerID:Int = 0) {
		super();

		add(sustains = new FlxTypedSpriteGroup<Sustain>());

		add(strumlines = new FlxTypedSpriteGroup<Strumline>());
		for (line in lines) strumlines.add(line);

		add(notes = new FlxTypedSpriteGroup<Note>());

		this.playerID = playerID;

		Application.current.window.onKeyDown.add(input);
		Application.current.window.onKeyUp.add(release);
	}

	public var unspawnedNotes:Array<NoteData> = [];
	public function load(chart:Chart) {
		unspawnedNotes.resize(0);

		for (section in chart.notes) {
			for (noteData in section.sectionNotes) {
				var note:NoteData = {
					time: Math.max(0, noteData[0]),
					lane: Std.int(noteData[1] % Strumline.keyCount),
					length: noteData[2],
					player: noteData[1] > (Strumline.keyCount - 1) != section.mustHitSection ? 1 : 0,
					type: (noteData[3] is String ? noteData[3] : Note.defaultTypes[noteData[3]]) ?? '',
				};

				unspawnedNotes.push(note);
			}
		}

		unspawnedNotes.sort((a, b) -> return Std.int(a.time - b.time));
	}

	function addNote<T:Note>(data:NoteData, group:FlxTypedSpriteGroup<T>, cls:Class<T>):T {
		var strumline:Strumline = getStrumline(data.player);

		var note:T = group.recycle(cls);
		group.remove(note, true); // keep ordering
		group.add(cast note.setup(data));

		return note;
	}

	public var noteSpawnIndex:Int = 0;
	public var noteSpawnDelay:Float = 1500;
	override function update(delta:Float) {
		while (noteSpawnIndex < unspawnedNotes.length) {
			var noteData = unspawnedNotes[noteSpawnIndex];

			final hitTime:Float = (noteData.time - Settings.data.noteOffset) - Conductor.rawTime;
			if (hitTime > noteSpawnDelay) break;

			var note = addNote(noteData, notes, Note);
			if (noteData.length > 0) {
				note.sustain = addNote(noteData, sustains, Sustain);
				//note.sustain.type = note.type;
				final strum:StrumNote = getStrumline(noteData.player).members[noteData.lane];
				note.sustain.calcHeight(scrollSpeed);
			}

			noteSpawnIndex++;
		}

		strumlines.update(delta);
		
		for (note in notes.members) {
			if (note == null || !note.exists) continue;
			note.update(delta);

			var strum = getStrumline(note.player).members[note.lane];
			note.followStrum(strum, scrollSpeed);

			if (strum.parent.ai) botplayInputs(strum, note);

			if (note.exists && note.tooLate && !note.missed) {
				note.missed = true;
				noteMiss(strum.parent, note);
			}

			if (note.time < Conductor.rawTime - 300) note.kill();
		}

		for (obj in sustains.members) {
			if (obj == null || !obj.exists) continue;
			obj.update(delta);

			var strum = getStrumline(obj.player).members[obj.lane];
			obj.followStrum(strum, scrollSpeed);

			sustainInputs(strum, obj, scrollSpeed);
			obj.calcHeight(scrollSpeed);

			if (obj.time + obj.length + 300 < Conductor.rawTime)
				obj.kill();
		}
	}

	function botplayInputs(strum:StrumNote, note:Note) {
		if (note.time > Conductor.time) return;

		noteHit(strum.parent, note);
		note.wasHit = true;
		if (note.sustain != null)
			note.sustain.wasHit = true;
		note.kill();
		strum.glow('confirm');
	}

	public var sustainInterval:Float = 120;
	dynamic function sustainInputs(strum:StrumNote, note:Sustain, noteSpeed:Float) {
		if (!note.wasHit || note.missed) return;

		var held:Bool = pressedKeys[note.lane];
		var playerHeld:Bool = (held || note.coyoteTimer > 0);
		var heldKey:Bool = (!strum.parent.ai && playerHeld) || (strum.parent.ai && note.time <= Conductor.time);

		final coyoteLim = 0.175 * note.coyoteHitMult;
		if (note.coyoteTimer < coyoteLim && held) {
			//if (!glowStrum(strum, note))
			strum.glow('static');
		}

		note.coyoteTimer = held ? coyoteLim : note.coyoteTimer - FlxG.elapsed;
		note.coyoteAlpha = strum.parent.ai ? 1 : 1 * (note.coyoteTimer / coyoteLim);
		if (strum.parent.ai && note.coyoteTimer <= 0) {
			note.coyoteTimer = coyoteLim;
			sustainHit(strum.parent, note, true);
			strum.glow('confirm');
		}

		final curHolds = strum.parent.curHolds;
		if (!heldKey) {
			if (!strum.parent.ai) {
				noteMiss(strum.parent, note);
				curHolds.remove(note);
				note.coyoteAlpha = 0.2;
				note.missed = true;
			}

			return;
		}

		note.timeOffset = -Math.min(note.hitTime, 0);
		note.forceHeightRecalc = true;
		strum.isHolding = true;

		if (!curHolds.contains(note)) {
			// we want the most recent, but we also dont wanna prioritize super short sustains
			final idx = note.length >= 250 ? curHolds.length : 0;
			curHolds.insert(idx, note);
		} else if (note.time + note.length <= Conductor.time) {
			curHolds.remove(note);
			note.kill();
			strum.isHolding = !strum.parent.ai && held;
			if (strum.parent.ai && strum.animation.finished)
				strum.glow('static');
			note.untilTick = 0; // Hit it one last time, to make sure 
		}

		note.untilTick -= FlxG.elapsed * 1000;
		if (note.untilTick > 0) return;

		note.untilTick = sustainInterval;
		if (strum.parent.ai || held)
			strum.glow('confirm');
		sustainHit(strum.parent, note, curHolds[curHolds.length - 1] == note);
	}

	final keys:Array<String> = [
		'note_left',
		'note_down',
		'note_up',
		'note_right'
	];

	var pressedKeys:Array<Bool> = [for (i in 0...Strumline.keyCount) false];
	function input(key:KeyCode, _) {
					   // i hate this check but whatever it works
		if (botplay || (FlxG.state.subState != null && !FlxG.state.persistentUpdate)) return;

		final dir:Int = Controls.convertStrumKey(keys, Controls.convertLimeKeyCode(key));
		if (dir == -1) return;

		if (pressedKeys[dir]) return;
		pressedKeys[dir] = true;

		var strum = currentPlayer.members[dir];

		for (sustain in sustains.members) {
			if (!sustain.exists) continue;
			if (sustain.player != playerID || !sustain.wasHit || sustain.lane != dir) continue;

			sustain.coyoteTimer = 0.175 * sustain.coyoteHitMult;
			//sustainHit(currentPlayer, sustain, true);
			strum.glow('confirm');
		}

		var closestDistance:Float = Math.POSITIVE_INFINITY;
		var noteToHit:Note = null;
		for (note in notes.members) {
			if (!note.exists) continue;
			if (note.player != playerID || !note.hittable || note.lane != dir) continue;

			var distance:Float = Math.abs(note.hitTime);
			if (distance < closestDistance) {
				closestDistance = distance;
				noteToHit = note;
			}
		}

		if (noteToHit == null) {
			strum.glow('pressed');
			return;
		}

		strum.glow('confirm');
		strum.isHolding = true;

		noteHit(currentPlayer, noteToHit);
		noteToHit.wasHit = true;
		if (noteToHit.sustain != null)
			noteToHit.sustain.wasHit = true;
		noteToHit.kill();
		noteToHit = null;
	}

	function release(key:KeyCode, _) {
		if (botplay) return;

		final dir:Int = Controls.convertStrumKey(keys, Controls.convertLimeKeyCode(key));
		if (dir == -1) return;

		pressedKeys[dir] = false;

		var strum = currentPlayer.members[dir];
		strum.glow('static');
		strum.isHolding = false;
	}

	override function destroy() {
		super.destroy();

		Application.current.window.onKeyDown.remove(input);
		Application.current.window.onKeyUp.remove(release);
	}
}