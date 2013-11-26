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
		
		private const MAXVELOCITY : Number = 15;
		private const JUMPVELOCITY : Number = 15;
		private const MAXJUMPHEIGHT : Number = JUMPVELOCITY * 10;
		private const MAXFALLSPEED : Number = -50;
		
		private const DETECTIONOFFSET : Number = 10;
		
		//Player terrain states.
		private const ONGROUND : Number = 0;
		private const MIDAIR : Number = 1;
		
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
		private var distTravelledY : Number = 0;
		private var prevY : Number = 0;
		private var currentDirectionY : Number = 0;
		
		private var resetPos : Point = new Point(0, 0);
		
		private var currentMovementState : Number;
		private var currentJumpState : Number;
		
		private var pressedLeftKey : Boolean = false;
		private var pressedRightKey : Boolean = false;
		private var pressedJumpKey : Boolean = false;
		private var releasedJumpKey : Boolean = true; //Used to prevent jump spamming
		private var pressedResetKey : Boolean = false;
		
		private var isJumping : Boolean = false;
		private var applyGravity : Boolean = true;
		
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
				
			if(pressedJumpKey && releasedJumpKey && !isJumping && currentMovementState == ONGROUND)
			{
				isJumping = true;
				applyGravity = false;
				releasedJumpKey = false;
				prevY = y;
				velocityY = JUMPVELOCITY;
			}
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
					releasedJumpKey = true;
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
			
			//Speculative contacts for both left and right. Adjust X-Velocity accordingly.
			switch(moveDirection)
			{
				case collisionDetection.LEFT:
					if(collisionDetection.CheckRayTrace(new Point(-velocityX, playerObject.height/2), collisionDetection.RAYHORIZONTAL) == true)
					{
						velocityX = x - (collisionDetection.ObjectCollidingWith.x + collisionDetection.ObjectCollidingWith.width);
					}
					break;
				case collisionDetection.RIGHT:
					if(collisionDetection.CheckRayTrace(new Point(playerObject.width + velocityX, playerObject.height/2), collisionDetection.RAYHORIZONTAL) == true)
					{
						velocityX = collisionDetection.ObjectCollidingWith.x - (x + playerObject.width);
					}
					break;
			}
			
			x += moveDirection * velocityX;
			collisionDetection.UpdatePosition();
		}
		
		private function PlayerJump() : void
		{
			if(distTravelledY >= MAXJUMPHEIGHT || !pressedJumpKey)
			{
				isJumping = false;
				applyGravity = true;
			}
			else
			{
				velocityY = JUMPVELOCITY;
				
				//Speculative contact check upwards
				if(collisionDetection.CheckRayTrace(new Point(playerObject.width/2, -velocityY), collisionDetection.RAYVERTICAL) == true &&
				   collisionDetection.ObjectCollidingWith.y < y)
				{
					velocityY = (collisionDetection.ObjectCollidingWith.y + collisionDetection.ObjectCollidingWith.height - y) * -1;
				}
				y += -velocityY;
				
				distTravelledY += (prevY - y);
				
				prevY = y;
			}
		}
		
		private function ApplyGravity() : void
		{
			if(currentMovementState == MIDAIR && applyGravity)
			{
				if(velocityY > MAXFALLSPEED)
				{
					velocityY = velocityY + gravity;
				}
					
				//Speculative Contacts for both above and below the player.
				//Perform Speculative Contacts by checking the ray cast. Prevents player from ghosting through terrian.
				if(collisionDetection.CheckRayTrace(new Point(playerObject.width/2, playerObject.height + -velocityY), collisionDetection.RAYVERTICAL) == true &&
			   		collisionDetection.ObjectCollidingWith.y > y + playerObject.height)
				{
					velocityY = (collisionDetection.ObjectCollidingWith.y - (y + playerObject.height)) * -1;
				}
				
				//Perform Speculative Contacts by checking the ray cast. Prevents player from ghosting through terrian.
				if(collisionDetection.CheckRayTrace(new Point(playerObject.width/2, -velocityY), collisionDetection.RAYVERTICAL) == true &&
			   collisionDetection.ObjectCollidingWith.y < y)
				{
					velocityY = (collisionDetection.ObjectCollidingWith.y + collisionDetection.ObjectCollidingWith.height - y) * -1;
				}
				
				y += -velocityY;
			}
			else
			{
				velocityY = 0;
				applyGravity = true;
			}
			collisionDetection.UpdatePosition();
		}
		
		private function CheckLevelCollision() : void
		{
				if(collisionDetection.CheckCollisionDirection(collisionDetection.DOWN) )
				{
						currentMovementState = ONGROUND;
						if(distTravelledY != 0)
							distTravelledY = 0;
						//beneathBlock = collisionDetection.ObjectCollidingWith;
				}
				//if(!collisionDetection.CheckCollisionDirection(collisionDetection.DOWN) )
				else
				{
						currentMovementState = MIDAIR;
				}
				
			ApplyGravity();
		}
	}
}