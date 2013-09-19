package  
{
	import flash.events.TimerEvent;
	import flash.events.Event;
	import flash.display.MovieClip;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	
	import PlatformerCollision;
	import WorldObjects;
	import flash.geom.Point;
	import flash.sampler.NewObjectSample;
	
	public class PlayerClass extends MovieClip
	{
		public var LeftKey : uint = Keyboard.A;
		public var RightKey : uint = Keyboard.D;
		public var JumpKey : uint = Keyboard.SPACE;
		public var ResetKey : uint = Keyboard.R;
		
		//private const LEFT : Number = -1;
		//private const RIGHT : Number = 1;
		//private const UP : Number = -2;
		//private const DOWN : Number = 2;
		
		private const MAXVELOCITY : Number = 15;
		private const MAXJUMPVELOCITY : Number = 35;
		private const MINJUMPVELOCITY : Number = 5;
		private const MAXFALLSPEED : Number = -50;
		
		private const DETECTIONOFFSET : Number = 10;
		
		private static const ONGROUND : Number = 0;
		private static const MIDAIR : Number = 1;
		
		private var collisionDetection : PlatformerCollision = null;
		
		private var beneathBlock : MovieClip = null;
		private var playerBounds : MovieClip = null;
		private var playerObject : MovieClip = null;
		
		private var velocityX : Number = 0;
		private var accelerationX : Number = 0;
		private var decelerationX  : Number = 0;
		private var currentDirectionX : Number = 0;
		
		private var velocityY : Number = 0;
		private var accelerationY : Number = 0;
		private var gravity  : Number = 0;
		private var currentDirectionY : Number = 0;
		
		private var resetPos : Point = new Point(0, 0);
		
		private var currentMovementState : Number;
		
		private var pressedLeftKey : Boolean = false;
		private var pressedRightKey : Boolean = false;
		private var pressedJumpKey : Boolean = false;
		private var pressedResetKey : Boolean = false;
		
		private var isJumping : Boolean = false;
		private var hasReachedMaxJump : Boolean = false;
		
		public function PlayerClass()
		{
			playerObject = getChildByName("PlayerSprite") as MovieClip;
			
			playerBounds = getChildByName("PlayerBounds") as MovieClip;
			playerBounds.visible = false;
			
			collisionDetection = new PlatformerCollision(this, playerObject, playerBounds);
			collisionDetection.AddException(playerObject.name);
			collisionDetection.AddException(playerBounds.name);
			
			accelerationX = MAXVELOCITY / 5;
			decelerationX = -1 * (accelerationX * 1.5);
			
			accelerationY = 5;
			gravity = -1 * accelerationY;
			
			resetPos = new Point(x, y);
			
			stage.addEventListener(Event.ENTER_FRAME, Update);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, HandleKeysDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, HandleKeysUp);
		}
		
		private function Update(event : Event) : void
		{
			CheckLevelCollision();
			HandleInput();
		}
		
		private function HandleInput() : void
		{
			if(currentMovementState == ONGROUND)
				velocityY = 0;
			
			if(pressedLeftKey)
				currentDirectionX = collisionDetection.LEFT;
			if(pressedRightKey)
				currentDirectionX = collisionDetection.RIGHT;
			if(pressedJumpKey && !isJumping && velocityY == 0)
				isJumping = true;
			if(pressedResetKey)
			{
				x = resetPos.x;
				y = resetPos.y;
				velocityY = 0;
			}
			
			PlayerMove(currentDirectionX);
			
			if(isJumping)
				PlayerJump();
		}
		
		//============================== KEYBOARD INPUT ==============================
		private function HandleKeysDown(event: KeyboardEvent) : void
		{
			switch(event.keyCode)
			{
				case LeftKey:
					pressedLeftKey = true;
					break;
				case RightKey:
					pressedRightKey = true;
					break;
				case JumpKey:
					pressedJumpKey = true;
					break;
				case ResetKey:
					pressedResetKey = true;
					break;
			}
		}
		
		private function HandleKeysUp(event: KeyboardEvent) : void
		{
			switch(event.keyCode)
			{
				case LeftKey:
					pressedLeftKey = false;
					break;
				case RightKey:
					pressedRightKey = false;
					break;
				case JumpKey:
					pressedJumpKey = false;
					break;
				case ResetKey:
					pressedResetKey = false;
					break;
			}
		}
		//==========================================================================
		
		private function PlayerMove(moveDirection : Number) : void
		{
			var nearestObj = null;
			//VelocityFinal = VelocityInitial + acceleration * time
			
			if(pressedLeftKey || pressedRightKey)
			{
				if(velocityX < MAXVELOCITY)
					velocityX = velocityX + accelerationX;
			}
			else
			{
				if(velocityX > 0)
					velocityX = velocityX + decelerationX;
				else
					velocityX = 0;
			}
			
			//Check if the  player is touching a wall. If so, prevent any movement in that direction.
			if((moveDirection == collisionDetection.LEFT && collisionDetection.CheckCollisionDirection(collisionDetection.LEFT)) || 
			   (moveDirection == collisionDetection.RIGHT && collisionDetection.CheckCollisionDirection(collisionDetection.RIGHT)) )
			{
				velocityX = 0;
			}
			
			switch(moveDirection)
			{
				case collisionDetection.LEFT:
					nearestObj = collisionDetection.PredictCollisionInDirection(collisionDetection.LEFT);
					if(nearestObj != null)
					{
						if( x + -velocityX < nearestObj.x + nearestObj.width)
						{
							x = nearestObj.x + playerObject.width;
							velocityX = 0;
							
						}
					}
					break;
				case collisionDetection.RIGHT:
					nearestObj = collisionDetection.PredictCollisionInDirection(collisionDetection.RIGHT);
					if(nearestObj != null)
					{
						if( x + playerObject.width + -velocityX > nearestObj.x)
						{
							x = nearestObj.x - playerObject.width;
							velocityX = 0;
						}
					}
					break;
			}
			
			x += moveDirection * velocityX;
			collisionDetection.UpdatePosition();
		}
		
		private function PlayerJump() : void
		{
			var nearestObj = null;
			
			if(velocityY <= 0 && !hasReachedMaxJump)
			{
				velocityY = MAXJUMPVELOCITY - accelerationY;
			}
			else
			{
				hasReachedMaxJump = true;
				isJumping = false;
			}
			
			//Check for a close object above the player. If there is one, and the player's jump will exceed the bounds of the object, alter the player's position.
			/*nearestObj = collisionDetection.PredictCollisionInDirection(collisionDetection.UP);
		
			if(nearestObj != null)
			{
				if( y + -velocityY < nearestObj.y + nearestObj.height)
				{
					trace("Speculative contact - up");
					//CURRENT PROBLEM: Nearest object isn't above, player is being placed below it.
					//y = nearestObj.y + nearestObj.height;
					//velocityY = 0;
				}
			}*/
			y += -velocityY;
		}
		
		private function ApplyGravity() : void
		{
			var nearestObj = null;
			
			if(currentMovementState == MIDAIR)
			{
				if(!isJumping)
					hasReachedMaxJump = true;
					
				//if(velocityY > MAXFALLSPEED) //No longer need to cap fall speed thanks to Speculative Contacts
					velocityY = velocityY + gravity;
					
				//Get the nearest object beneath the player. If the player is going to fall through it, reduce their velocity(?)
				nearestObj = collisionDetection.PredictCollisionInDirection(collisionDetection.DOWN);
				
				if(nearestObj != null)
				{
					if( y + playerObject.height + -velocityY > nearestObj.y)
					{
						//y = nearestObj.y - playerObject.height; //THIS WAS CHEATING.
						
						//PROBLEM CAUSED BY THIS. POSSIBLY FROM PredictCollisionInDirection
						velocityY = (nearestObj.y - (y + playerObject.height)) * -1;
						trace("Speculative contact - down :" + nearestObj.name);
					}
				}
				y += -velocityY;
			}
			else
			{
				velocityY = 0;
				hasReachedMaxJump = false;
				
				//Get the nearest object beneath the player. If the player would be hovering over it, lower them.
				nearestObj = collisionDetection.PredictCollisionInDirection(collisionDetection.DOWN);
				
				if(nearestObj != null)
				{
					if(y + playerObject.height < nearestObj.y)
						y = nearestObj.y - playerObject.height;
				}
			}
			collisionDetection.UpdatePosition();
		}
		
		private function CheckLevelCollision() : void
		{
				if(collisionDetection.CheckCollisionDirection(collisionDetection.DOWN) )
				{
						currentMovementState = ONGROUND;
						beneathBlock = collisionDetection.PredictCollisionInDirection(collisionDetection.DOWN);
				}
				if(!collisionDetection.CheckCollisionDirection(collisionDetection.DOWN) )
				{
						currentMovementState = MIDAIR;
				}
				if(collisionDetection.CheckCollisionDirection(collisionDetection.UP) && isJumping)
				{
					hasReachedMaxJump = true;
					isJumping = false;
				}
				
			ApplyGravity();
		}
	}
}