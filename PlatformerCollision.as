package  {
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.sampler.NewObjectSample;
	
	public class PlatformerCollision 
	{
		public const LEFT : Number = -1;
		public const RIGHT : Number = 1;
		public const UP : Number = -2;
		public const DOWN : Number = 2;

		private var exceptionList : Vector.<String>;
		
		private var objectSprite : MovieClip = null;
		private var objectExtraBounds : MovieClip = null;
		private var owner : MovieClip = null; //The MovieClip that is using this physics script.
		
		private var objSpritePos :  Point;
		
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
								isColliding = true;
								hasObtainedCollision = true;
							}
							break;
						case DOWN:
							if(owner.parent.getChildAt(i).y >= objSpritePos.y + objectSprite.height && 
							   (owner.parent.getChildAt(i).x <= objSpritePos.x + objectSprite.width || owner.parent.getChildAt(i).x + owner.parent.getChildAt(i).width >= objSpritePos.x))
							{
								isColliding = true;
								hasObtainedCollision = true;
							}
							break;
						case LEFT:
							if(owner.parent.getChildAt(i).x <= objSpritePos.x && owner.parent.getChildAt(i).y < objSpritePos.y)
							{
								isColliding = true;
								hasObtainedCollision = true;
							}
							break;
						case RIGHT:
							if(owner.parent.getChildAt(i).x >= objSpritePos.x && owner.parent.getChildAt(i).y < objSpritePos.y )
							{
								isColliding = true;
								hasObtainedCollision = true;
							}
							break;
						default:
							break;
					}
				}
			}
			
			return isColliding;
		}
		
		public function PredictCollisionInDirection(direction : Number) : MovieClip
		{
			var currentObj : MovieClip = null;
			var closestObj : MovieClip = null;
			var closestDist : Number = 500;
			var tempDistLeft : Number = 0;
			var tempDistRight : Number = 0;
			var tempDistClosest : Number = 0;
			var isInRange : Boolean = false;
			var isTouchingObj : Boolean = false;
			
			for(var i : int = 0; i < owner.parent.numChildren; i++)
			{
				if(exceptionList.indexOf(owner.parent.getChildAt(i).name) == -1)
				{
					currentObj = owner.parent.getChildAt(i) as MovieClip;
					switch(direction)
					{
						case UP:
						//If the object is above the search point and within the max search range
							if(currentObj.y + currentObj.height <= owner.y)
							{
								if(CheckBounds(owner, currentObj, "x") == true)
								{
									isInRange = true;
									isTouchingObj = CheckCollisionDirection(UP);
								 }
							}
							break;
						case DOWN:
						//If the object is below the search point and within the max search range
							//if(currentObj.y >= searchPoint.y && currentObj.y <= searchPoint.y + maxDist.y)
							if(currentObj.y >= owner.y + objectSprite.height)
							{
								if(CheckBounds(owner, currentObj, "x")  == true)
								{
									isInRange = true;
									isTouchingObj = CheckCollisionDirection(DOWN);
								}
							}
							break;
						case LEFT:
						//If the object is to the left of the search point and within the max search range
							//if(currentObj.x <= searchPoint.x && currentObj.x >= searchPoint.x + maxDist.x)
							if(currentObj.x <= owner.x)
							{
								//if(searchPoint.y <= currentObj.y && searchPoint.y >= currentObj.y + currentObj.height)
								if(owner.y <= currentObj.y && owner.y >= currentObj.y + currentObj.height)
								   {
										isInRange = true;
										isTouchingObj = CheckCollisionDirection(LEFT);
										trace("LEFT");
								   }
							}
							break;
						case RIGHT:
						//If the object is to the right of the search point and within the max search range
							//if(currentObj.x >= searchPoint.x && currentObj.x <= searchPoint.x + maxDist.x)
							if(currentObj.x >= owner.x)
							{
								//if(searchPoint.y <= currentObj.y && searchPoint.y >= currentObj.y + currentObj.height)
								if(owner.y <= currentObj.y && owner.y >= currentObj.y + currentObj.height)
								   {
										isInRange = true;
										isTouchingObj = CheckCollisionDirection(RIGHT);
										trace("RIGHT");
								   }
							}
							break;
						default:
							trace("[ERROR] INVALID AXIS SELECTED");
					}
					
					if(isInRange == true)
					{
						//Calculate the middle point of both the subject object and the searched object.
						var fullObjectMidX : Number = owner.x + (owner.width / 2);
						var currObjectMidX : Number = currentObj.x + (currentObj.width / 2);
						
						if (GetDistance(new Point(fullObjectMidX, owner.y), new Point(currObjectMidX, owner.y)) < closestDist || isTouchingObj == true )
						{
							tempDistClosest = GetDistance(new Point(fullObjectMidX, owner.y), new Point(currObjectMidX, currentObj.y) );
							
							//if(tempDistClosest < 0)
								//tempDistClosest *= -1;
							
							if(tempDistClosest < closestDist)
							{
								closestDist = tempDistClosest;
								closestObj = owner.parent.getChildAt(i) as MovieClip;
							}
						}
					}
				}
			}
			if(closestObj != null)
				closestObj.alpha = 0.5; //DISPLAYING THE CLOSEST OBJECT TO THE PLAYER
				
			return closestObj;
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
