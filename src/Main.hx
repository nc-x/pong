package;

import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

enum State {
	Paused;
	Playing;
}

enum Player {
	Human;
	AI;
}

class WindowSize extends Sprite {
	public var windowH:Int;
	public var windowW:Int;
	public var baseH:Int;
	public var baseW:Int;
	public var scaleH:Float;
	public var scaleW:Float;
	public var minScale:Float;

	public function new() {
		super();

		windowH = Lib.current.stage.stageHeight;
		windowW = Lib.current.stage.stageWidth;

		baseH = 500;
		baseW = 600;

		scaleH = (windowH / baseH);
		scaleW = (windowW / baseW);

		minScale = (Math.min(scaleH, scaleW));
	}
}

class Paddle extends Sprite {
	public var paddleWidth:Float;
	public var paddleHeight:Float;

	public function new() {
		super();

		var size = new WindowSize();

		paddleWidth = 20 * size.scaleW;
		paddleHeight = 125 * size.minScale;

		this.graphics.beginFill(0xFDFCFE);
		this.graphics.drawRoundRect(0, 0, paddleWidth, paddleHeight, paddleWidth / 4, paddleHeight / 4);
		this.graphics.endFill();
	}
}

class Ball extends Sprite {
	public var ballRadius:Float;

	public function new() {
		super();

		var size = new WindowSize();

		ballRadius = 10 * size.minScale;

		this.graphics.beginFill(0x26EDFF);
		this.graphics.drawCircle(0, 0, ballRadius);
		this.graphics.endFill();
	}
}

class Main extends Sprite {
	private var paddle1:Paddle;
	private var paddle2:Paddle;
	private var paddleOffset:Point;
	private var ball:Ball;
	private var invisibleBall:Ball;
	private var playerScore:Int;
	private var aiScore:Int;
	private var score:TextField;
	private var message:TextField;
	private var currentGameState:State;
	private var aiSpeed:Int;
	private var ballMovement:Point;
	private var ballSpeed:Int;
	private var omittedSpace:Float;
	private var size:WindowSize;

	public function new() {
		super();

		size = new WindowSize();

		omittedSpace = 10 * size.minScale;

		paddle1 = new Paddle();
		paddle1.x = omittedSpace * size.minScale;
		paddle1.y = ((size.windowH - paddle1.paddleHeight) / 2);
		addChild(paddle1);

		paddle2 = new Paddle();
		paddle2.x = (size.windowW - omittedSpace - paddle2.paddleWidth);
		paddle2.y = ((size.windowH - paddle2.paddleHeight) / 2);
		addChild(paddle2);

		paddleOffset = new Point();

		ball = new Ball();
		ball.x = size.windowW / 2;
		ball.y = size.windowH / 2;

		invisibleBall = new Ball();

		var textFormat:TextFormat = new TextFormat("Verdana", Math.floor(24 * size.minScale), 0xFDFCFE, true);
		textFormat.align = TextFormatAlign.CENTER;

		score = new TextField();
		addChild(score);
		score.width = 500;
		score.defaultTextFormat = textFormat;
		score.selectable = false;
		score.x = (size.windowW - score.width) / 2;
		score.y = 30;

		message = new TextField();
		addChild(message);
		message.width = 500;
		message.height = 500;
		message.defaultTextFormat = textFormat;
		message.selectable = false;
		message.text = "Instructions:\nTap to start.\nDrag the Paddle to move.";
		message.x = (size.windowW - score.width) / 2;
		message.y = size.windowH / 2;

		playerScore = 0;
		aiScore = 0;

		aiSpeed = Math.ceil(7 * size.minScale);
		ballSpeed = Math.ceil(7 * size.minScale);

		ballMovement = new Point(0, 0);

		setGameState(Paused);
		stage.addEventListener(MouseEvent.CLICK, stageClick);
		paddle1.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		addEventListener(Event.ENTER_FRAME, everyFrame);
	}

	private function stageClick(event:MouseEvent):Void {
		if (currentGameState == Paused) {
			setGameState(Playing);
			addChild(ball);
		}
	}

	private function mouseDown(event:MouseEvent):Void {
		if (currentGameState == Playing) {
			paddleOffset.y = paddle1.y - event.stageY;
			stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
		}
	}

	private function mouseMove(event:MouseEvent):Void {
		paddle1.y = event.stageY + paddleOffset.y;
	}

	private function mouseUp(event:MouseEvent):Void {
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
		stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
	}

	private function setGameState(state:State):Void {
		currentGameState = state;
		updateScore();

		if (state == Paused) {
			message.alpha = 1;
		} else {
			message.alpha = 0;
			paddle1.y = ((size.windowH - paddle1.paddleHeight) / 2);
			paddle2.y = ((size.windowH - paddle2.paddleHeight) / 2);
			ball.x = size.windowW / 2;
			ball.y = size.windowH / 2;
			var direction:Int = (Math.random() > .5) ? (1) : (-1);
			var randomAngle:Float = (Math.random() * Math.PI / 2) - 45;
			ballMovement.x = direction * Math.cos(randomAngle) * ballSpeed;
			ballMovement.y = Math.sin(randomAngle) * ballSpeed;
			createInvisible();
		}
	}

	private function everyFrame(event:Event):Void {
		// player platform limits
		if (paddle1.y < omittedSpace)
			paddle1.y = omittedSpace;
		if (paddle1.y > (size.windowH - paddle1.paddleHeight - omittedSpace))
			paddle1.y = size.windowH - paddle1.paddleHeight - omittedSpace;

		if (currentGameState == Playing) {
			// AI platform movement
			if ((ball.x > 0.92 * paddle2.x)) {
				if (ball.y > paddle2.y) {
					paddle2.y += aiSpeed;
				}
				if (ball.y < paddle2.y + paddle2.height) {
					paddle2.y -= aiSpeed;
				}
			} else if (ballMovement.x > 0 && invisibleBall.y > paddle2.y) {
				paddle2.y += aiSpeed;
			} else if (ballMovement.x > 0 && invisibleBall.y < paddle2.y && paddle2.y - invisibleBall.y > paddle2.height) {
				paddle2.y -= aiSpeed;
			}

			// AI platform limits
			if (paddle2.y < omittedSpace)
				paddle2.y = omittedSpace;
			if (paddle2.y > (size.windowH - paddle2.paddleHeight - omittedSpace))
				paddle2.y = size.windowH - paddle2.paddleHeight - omittedSpace;

			// ball movement
			ball.x += ballMovement.x;
			ball.y += ballMovement.y;

			// invisible ball movement
			invisibleBall.x += 3 * ballMovement.x;
			invisibleBall.y += 3 * ballMovement.y;

			// ball platform bounce
			if (ballMovement.x < 0 && ball.x < (ball.ballRadius + paddle1.paddleWidth + omittedSpace) && ball.y >= paddle1.y && ball.y <= (paddle1.y + paddle1
				.paddleHeight)) {
				bounceBall();
				ball.x = ball.ballRadius + paddle1.paddleWidth + omittedSpace;
				createInvisible();
			}

			if (ballMovement.x > 0 && ball.x > (size.windowW - (ball.ballRadius + paddle2.paddleWidth + omittedSpace)) && ball.y >= paddle2.y && ball
				.y <= (paddle2.y + paddle2.paddleHeight)) {
				bounceBall();
				ball.x = size.windowW - (ball.ballRadius + paddle2.paddleWidth + omittedSpace);
				createInvisible();
			}

			// ball edge bounce
			if (ball.y < omittedSpace || ball.y > size.windowH - omittedSpace) {
				ballMovement.y *= -1;
				createInvisible();
			}

			// ball goal
			if (ball.x < omittedSpace) {
				ball.x += ballMovement.x;
				ball.y += ballMovement.y;
				winGame(AI);
			}

			if (ball.x > size.windowW - omittedSpace) {
				ball.x += omittedSpace;
				ball.x += ballMovement.x;
				ball.y += ballMovement.y;
				winGame(Human);
			}
		}
	}

	private function bounceBall():Void {
		var direction:Int = (ballMovement.x > 0) ? (-1) : (1);
		var randomAngle:Float = (Math.random() * Math.PI / 2) - 45;
		ballMovement.x = direction * Math.cos(randomAngle) * ballSpeed;
		ballMovement.y = Math.sin(randomAngle) * ballSpeed;
	}

	private function createInvisible():Void {
		invisibleBall.x = ball.x;
		invisibleBall.y = ball.y;
	}

	private function winGame(player:Player):Void {
		if (player == Human) {
			playerScore++;
		} else {
			aiScore++;
		}
		setGameState(Paused);
	}

	private function updateScore():Void {
		score.text = playerScore + ":" + aiScore;
	}
}
