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
		private const MINJUMPVELOCITY : Number = 10;
		private const MAXJUMPVELOCITY : Number = 30;
		private const MINJUMPHEIGHT : Number = MINJUMPVELOCITY;
		private const MAXJUMPHEIGHT : Number = 65;
		private const MAXFALLSPEED : Number = -50;
		
		private const DETECTIONOFFSET : Number = 10;
		
		//Player terrain states.
		private const ONGROUND : Number = 0;
		private const MIDAIR : Number = 1;
		
		//Player jump states.
		private const JUMPSTARTED : Number = 0;
		private const JUMPMID : Number = 1;
		private const JUMPFINISHED : Number = 2;
		private const DONEJUMP : Number = 3;
		
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
			
			currentJumpState = DONEJUMP;
			
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
			if(pressedJumpKey && currentJumpState == DONEJUMP)
			{
				isJumping = true;
				prevY = y;
				currentJumpState = JUMPSTARTED;
				velocityY = MAXJUMPVELOCITY;
			}
			if(!pressedJumpKey && isJumping)
			{
				isJumping = false;
				hasReachedMaxJump = true;
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
						velocityX = x - (collisionDetection.RayCollisionObj.x + collisionDetection.RayCollisionObj.width);
					}
					break;
				case collisionDetection.RIGHT:
					if(collisionDetection.CheckRayTrace(new Point(playerObject.width + velocityX, playerObject.height/2), collisionDetection.RAYHORIZONTAL) == true)
					{
						velocityX = collisionDetection.RayCollisionObj.x - (x + playerObject.width);
					}
					break;
			}
			
			x += moveDirection * velocityX;
			collisionDetection.UpdatePosition();
		}
		
		private function PlayerJump() : void
		{
			switch(currentJumpState)
			{
				case JUMPSTARTED:
					velocityY = MINJUMPVELOCITY;
					if(!pressedJumpKey || distTravelledY >= MINJUMPHEIGHT)
					{
						velocityY = MAXJUMPVELOCITY;
						currentJumpState = JUMPMID;
					}
					break;
				case JUMPMID:
					velocityY -= accelerationY * 0.25;
					if(!pressedJumpKey || distTravelledY >= MAXJUMPHEIGHT)
						currentJumpState = JUMPFINISHED;
					break;
				case JUMPFINISHED:
					velocityY = 0;
					isJumping = false;
					break;
			}
			//Speculative contact check upwards
			if(collisionDetection.CheckRayTrace(new Point(playerObject.width/2, -velocityY), collisionDetection.RAYVERTICAL) == true &&
			   collisionDetection.RayCollisionObj.y < y)
			{
				velocityY = (collisionDetection.RayCollisionObj.y + collisionDetection.RayCollisionObj.height - y) * -1;
			}
			y += -velocityY;
			
			distTravelledY += (prevY - y);
			
			prevY = y;
		}
		
		private function ApplyGravity() : void
		{
			if(currentMovementState == MIDAIR)
			{
				if(!isJumping)
					hasReachedMaxJump = true;
					
				if(velocityY > MAXFALLSPEED)
					velocityY = velocityY + gravity;
					
				//Speculative Contacts for both above and below the player.
				//Perform Speculative Contacts by checking the ray cast. Prevents player from ghosting through terrian.
				if(collisionDetection.CheckRayTrace(new Point(playerObject.width/2, playerObject.height + -velocityY), collisionDetection.RAYVERTICAL) == true &&
			   		collisionDetection.RayCollisionObj.y > y + playerObject.height)
				{
					velocityY = (collisionDetection.RayCollisionObj.y - (y + playerObject.height)) * -1;
				}
				
				//Perform Speculative Contacts by checking the ray cast. Prevents player from ghosting through terrian.
				if(collisionDetection.CheckRayTrace(new Point(playerObject.width/2, -velocityY), collisionDetection.RAYVERTICAL) == true &&
			   collisionDetection.RayCollisionObj.y < y)
				{
					velocityY = (collisionDetection.RayCollisionObj.y + collisionDetection.RayCollisionObj.height - y) * -1;
				}
				
				y += -velocityY;
			}
			else
			{
				velocityY = 0;
				hasReachedMaxJump = false;
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
						if(currentJumpState != DONEJUMP)
							currentJumpState = DONEJUMP;
						//beneathBlock = collisionDetection.PredictCollisionInDirection(collisionDetection.DOWN);
				}
				if(!collisionDetection.CheckCollisionDirection(collisionDetection.DOWN) )
				{
						currentMovementState = MIDAIR;
				}
				/*if(collisionDetection.CheckCollisionDirection(collisionDetection.UP) && isJumping)
				{
					hasReachedMaxJump = true;
					isJumping = false;
				}*/
				
			ApplyGravity();
		}
	}
}