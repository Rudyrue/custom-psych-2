package funkin.objects;

import funkin.objects.Note.NoteData;
import funkin.objects.Strumline;
import flixel.graphics.frames.FlxFrame;
import flixel.animation.FlxAnimation;

class Sustain extends Note {
	var holdAnims:Array<String> = [for (col in Util.colours) col.toLowerCase() + " hold piece"];
	var holdEndAnims:Array<String> = [for (col in Util.colours) col.toLowerCase() + " hold end"];
	static var finalVertices:Array<Float> = [for (i in 0...8) 0];

	public var forceHeightRecalc:Bool = false;
	var lastScaleY:Float = -1;
	var lastSustainScale:Float = -1;

	var sustainDivisions:Int = 0;
	var sustainTopY:Float = 0;
	var holdFrame:FlxFrame;
	var holdAnim:FlxAnimation;
	var holdHeight:Float = 0;
	var tailFrame:FlxFrame;
	var tailAnim:FlxAnimation;
	var tailHeight:Float = 0;

	// set to false by default
	// because it causes some weird overlapping bug if it's set to true
	// might try to workaround this in the future
	public var holdAntialiasing:Bool = false;

	public var tapHolding:Bool = false;
	public var coyoteAlpha:Float = 0.7;
	public var coyoteHitMult:Float = 1.0;
	public var coyoteTimer:Float = 0.175;
	public var timeOffset:Float = 0;
	public var untilTick:Float = 0;

	// stupid shit to make texture setting not break this
	override function updateHitbox() {}
	override function resetHelpers():Void {
		resetFrameSize();
		_flashRect2.x = 0;
		_flashRect2.y = 0;

		if (graphic != null) {
			_flashRect2.width = graphic.width;
			_flashRect2.height = graphic.height;
		}

		if (FlxG.renderBlit) {
			dirty = true;
			updateFramePixels();
		}
	}

/*	override function set_type(value:String):String {
		type = value;
		var finalSkin:String = '';
		coyoteHitMult = 1.0;
		animSuffix = '';
		tapHolding = false;
		switch (value) {
			case 'GF Sing':
				noAnimation = true;

			case 'Alt Animation':
				animSuffix = '-alt';
		}

		skin = finalSkin;
		return type;
	}*/

	override function applyFrames() {
		frames = Paths.sparrowAtlas('funkin');

		animation.addByPrefix('hold', holdAnims[lane]);
		animation.addByPrefix('holdend', holdEndAnims[lane]);

		holdAnim = animation.getByName("hold");
		tailAnim = animation.getByName("holdend");
		holdHeight = frames.frames[holdAnim.frames[0]].sourceSize.y;
		tailHeight = frames.frames[tailAnim.frames[0]].sourceSize.y;

		final divisionsFloat:Float = (height - tailHeight * scale.y) / (holdHeight * scale.y);
		sustainDivisions = Math.ceil(divisionsFloat);
		sustainTopY = holdHeight * (sustainDivisions - divisionsFloat);

		scale.set(Strumline.actualSize, Strumline.actualSize);
	}

	override function setup(data:NoteData) {
		super.setup(data);
		coyoteAlpha = 0.7;
		lastScaleY = -1; // basically these two will force it to recalc height.
		lastSustainScale = -1;
		holdAntialiasing = antialiasing;
		coyoteTimer = 0.175 * coyoteHitMult;
		timeOffset = 0;
		untilTick = 0;
		return this;
	}

	@:noDebug override function followStrum(strum:StrumNote, ?speed:Float = 1.0) {
		visible = strum.visible && strum.parent.visible;
		distance = (hitTime + timeOffset) * 0.45 * speed;

 		alpha = strum.alpha;
		x = strum.x + strum.width * 0.5;
		y = strum.y + strum.height * 0.5 + distance;
	}

	public function calcHeight(holdScale:Float) {
		if (forceHeightRecalc || scale.y != lastScaleY || holdScale != lastSustainScale) {
			forceHeightRecalc = false;
			lastScaleY = scale.y;
			lastSustainScale = holdScale;
			height = (length - timeOffset) * 0.45 * holdScale;
		}
	}

	override public function draw() {
		if (alpha == 0 || coyoteAlpha <= 0 || height <= 0)
			return;

		holdFrame = frames.frames[holdAnim.frames[Math.floor(Math.abs(Conductor.time * 0.001 * holdAnim.frameRate) % holdAnim.frames.length)]];
		tailFrame = frames.frames[tailAnim.frames[Math.floor(Math.abs(Conductor.time * 0.001 * tailAnim.frameRate) % tailAnim.frames.length)]];
		for (camera in cameras) {
			if (!camera.visible || !camera.exists)
				continue;

			drawComplex(camera);

			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug)
			drawDebug();
		#end
	}
	
	override public function drawComplex(camera:FlxCamera) {
		final camX = camera.scroll.x * scrollFactor.x;
		final yMult = flipY ? -1 : 1;
		var curY = -camera.scroll.y * scrollFactor.y;

		finalVertices[0] = finalVertices[4] = x - camX - (holdFrame.frame.width * scale.x * 0.5);
		finalVertices[2] = finalVertices[6] = x - camX + (holdFrame.frame.width * scale.x * 0.5);

		final backupHoldY = holdFrame.frame.y;
		final backupHoldHeight = holdFrame.frame.height;
		for (i in 0...sustainDivisions) {
			finalVertices[1] = finalVertices[3] = y + curY;
			
			holdFrame.frame.y = (i == 0) ? backupHoldY + sustainTopY : backupHoldY;
			holdFrame.frame.height = backupHoldHeight - (holdFrame.frame.y - backupHoldY);
			curY += holdFrame.frame.height * scale.y * yMult;

			finalVertices[5] = finalVertices[7] = y + curY;

			if (Math.min(finalVertices[1], finalVertices[5]) <= camera.viewMarginBottom && Math.max(finalVertices[1], finalVertices[5]) >= camera.viewMarginTop)
				camera.drawNoteVertices(holdFrame, finalVertices, colorTransform, blend, holdAntialiasing, false, colorTransform.alphaMultiplier * coyoteAlpha);
		}

		holdFrame.frame.y = backupHoldY;
		holdFrame.frame.height = backupHoldHeight;

		final backupTailY = tailFrame.frame.y;
		final backupTailHeight = tailFrame.frame.height;
		tailFrame.frame.height = Math.min(height, backupTailHeight);
		tailFrame.frame.y = backupTailY + (backupTailHeight - tailFrame.frame.height);

		finalVertices[1] = finalVertices[3] = y + curY;
		finalVertices[5] = finalVertices[7] = y + curY + (tailFrame.frame.height * scale.y * yMult);

		if (Math.min(finalVertices[1], finalVertices[5]) <= camera.viewMarginBottom && Math.max(finalVertices[1], finalVertices[5]) >= camera.viewMarginTop)
			camera.drawNoteVertices(tailFrame, finalVertices, colorTransform, blend, antialiasing, false, colorTransform.alphaMultiplier * coyoteAlpha);

		tailFrame.frame.y = backupTailY;
		tailFrame.frame.height = backupTailHeight;
	}

	override function set_height(value:Float) {
		if (height == value) return height;

		final divisionsFloat:Float = (value - tailHeight * scale.y) / (holdHeight * scale.y);
		sustainDivisions = Math.ceil(divisionsFloat);
		sustainTopY = holdHeight * (sustainDivisions - divisionsFloat);
		return height = value;
	}
}