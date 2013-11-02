package  {
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.sampler.NewObjectSample;
	import mx.core.IFlexAsset;
	
	public class PlatformerCollision 
	{
		//Directional Constants
		public const LEFT : Number = -1;
		public const RIGHT : Number = 1;
		public const UP : Number = -2;
		public const DOWN : Number = 2;
		
		//Ray Cast Directional Constants
		public const RAYHORIZONTAL : Number = 0;
		public const RAYVERTICAL : Number = 1;
		public const RAYWIDTHOFFSET : Number = 2; //Offset the size of the raycast by 2 pixels.
		
		public var RayCollisionObj : MovieClip = null;

		private var exceptionList : Vector.<String>;
		
		private var objectSprite : MovieClip = null;
		private var objectExtraBounds : MovieClip = null;
		private var owner : MovieClip = null; //The MovieClip that is using this physics script.
		
		private var objSpritePos :  Point;
		
		private var maxDist : Number = 0;
		
		public function PlatformerCollision(obj : MovieClip, objSprite : MovieClip, objExtraBounds : MovieClip) 
		{
			// constructor code
			owner = obj;
			objectSprite = objSprite;
			objectExtraBounds = objExtraBounds;
			
			objSpritePos = objectSprite.localToGlobal(new Point(objectSprite.x, objectSprite.y));
			
			exceptionList = new Vector.<String>();
			AddException(owner.name);
		}
		
		public function UpdatePosition()
		{
			objSpritePos = objectSprite.localToGlobal(new Point(objectSprite.x, objectSprite.y));
		}
		
		public function AddException(exceptionName : String)
		{
			exceptionList.push(exceptionName);
		}
		
		public function GetDistance(point1 : Point, point2: Point) : Number
		{
			//Dist = sq(deltaX + deltaY)
			return Math.sqrt( (point1.x - point2.x) * (point1.x - point2.x) + (point1.y - point2.y) * (point1.y - point2.y) );
		}
		
		//public function CheckRayTrace(startPoint : Point, endPoint : Point) : Boolean
		public function CheckRayTrace(endPoint : Point, rayOrientation : Number = RAYVERTICAL) : Boolean
		{
			var collisionResult : Boolean = false;
			
			//Generate a movieclip to be used purely for collision detection (thanks to Flash being hella ghetto.)
			var ray : MovieClip = new MovieClip();
			
			//Set up the array of commands for drawPath
			var commands : Vector.<int> = new Vector.<int>(6, true);
			commands[0] = 1; //moveTo
			commands[1] = 2; //lineTo
			commands[2] = 2; //lineTo
			commands[3] = 2; //lineTo
			
			//Set up the line coords
			var coords : Vector.<Number> = new Vector.<Number>(8, true);
			//coords[0] = startPoint.x; //X - Start
			//coords[1] = startPoint.y; //Y - Start
			coords[0] = objectSprite.width/2; //X - Start
			coords[1] = objectSprite.height/2; //Y - Start
			switch(rayOrientation)
			{
				case RAYHORIZONTAL:
					coords[2] = endPoint.x; //X - End
					coords[3] = objectSprite.height - RAYWIDTHOFFSET; //Y - End
					coords[4] = endPoint.x; //X - End
					coords[5] = RAYWIDTHOFFSET; //Y - End
					break;
				case RAYVERTICAL:
					coords[2] = objectSprite.width - RAYWIDTHOFFSET; //X - End
					coords[3] = endPoint.y; //Y - End
					coords[4] = RAYWIDTHOFFSET; //X - End
					coords[5] = endPoint.y; //Y - End
					break;
			}
			coords[6] = objectSprite.width/2; //X - Start
			coords[7] = objectSprite.height/2; //Y - Start
			
			
			ray.graphics.beginFill(0x000000);
			ray.graphics.lineStyle(1, 0x000000);
			ray.graphics.drawPath(commands, coords);
			
			owner.addChild(ray);
			
			//Check if the ray is colliding with an object
			for(var i : int = 0; i < owner.parent.numChildren; i++)
			{
				if(exceptionList.indexOf(owner.parent.getChildAt(i).name) == -1)
				{
					if(ray.hitTestObject(owner.parent.getChildAt(i)) )
					{
						collisionResult = true;
						RayCollisionObj = owner.parent.getChildAt(i) as MovieClip;
					}
				}
			}
			
			owner.removeChild(ray);
			return collisionResult;
		}
		
		//Checks if there is a collision in a + direction, can also check if colliding with a specific object
		public function CheckCollisionDirection(dir : Number) : Boolean
		{
			var isColliding : Boolean;
			var hasObtainedCollision : Boolean = false;
			
			for(var i : int = 0; i < owner.parent.numChildren; i++)
			{
				//If the main object isn't colliding with an object, and that object isn't part of the exception list and there hasn't already been a collision obtained
				if(objectExtraBounds.hitTestObject(owner.parent.getChildAt(i)) && exceptionList.indexOf(owner.parent.getChildAt(i).name) == -1 && !hasObtainedCollision)
				{
					switch(dir)
					{
						case UP:
							if(owner.parent.getChildAt(i).y <= objSpritePos.y && 
							   (owner.parent.getChildAt(i).x <= objSpritePos.x + objectSprite.width || owner.parent.getChildAt(i).x + owner.parent.getChildAt(i).width >= objSpritePos.x))
								{
									if(objectExtraBounds.hitTestObject(owner.parent.getChildAt(i)))
									{
										isColliding = true;
										hasObtainedCollision = true;
									}
								}
							break;
						case DOWN:
							if(owner.parent.getChildAt(i).y >= objSpritePos.y + objectSprite.height && 
							   (owner.parent.getChildAt(i).x <= objSpritePos.x + objectSprite.width || owner.parent.getChildAt(i).x + owner.parent.getChildAt(i).width >= objSpritePos.x))
								{
									if(objectExtraBounds.hitTestObject(owner.parent.getChildAt(i)))
									{
										isColliding = true;
										hasObtainedCollision = true;
									}
								}
							break;
						case LEFT:
							if(owner.parent.getChildAt(i).x <= objSpritePos.x && owner.parent.getChildAt(i).y < objSpritePos.y)
								{
									if(objectExtraBounds.hitTestObject(owner.parent.getChildAt(i)))
									{
										isColliding = true;
										hasObtainedCollision = true;
									}
								}
							break;
						case RIGHT:
							if(owner.parent.getChildAt(i).x >= objSpritePos.x && owner.parent.getChildAt(i).y < objSpritePos.y )
								{
									if(objectExtraBounds.hitTestObject(owner.parent.getChildAt(i)))
									{
										isColliding = true;
										hasObtainedCollision = true;
									}
								}
							break;
						default:
							break;
					}
				}
			}
			
			return isColliding;
		}
		
		private function CheckBounds(object1 : MovieClip, object2 : MovieClip, axis : String) : Boolean
		{
			var isInBounds : Boolean = false;
			switch(axis)
			{
				case "x":
				case "X":
				//PROBLEM EXISTS HERE. NEAREST OBJS EXCEED BOUNDS.
				
				//Check if object1 is within object2's bounds
						//If object1's left side is between the object2's right and left sides               //If object1's right side is between the object2's right and left sides
					if( (object1.x < object2.x + object2.width && object1.x > object2.x) || (object1.x + object1.width > object2.x && object1.x + object1.width < object2.x + object2.width) )
					{
						isInBounds = true;
					}
					break;
				case "y":
				case "Y":
					break;
			}
			return isInBounds;
		}

	}
	
}
