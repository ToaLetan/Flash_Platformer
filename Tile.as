package  
{
	import PlatformerEnums;
	
	import flash.display.MovieClip;
	
	public class Tile extends MovieClip
	{
		private var tileName : String;
		private var tileProperty : String;

		public function Tile() 
		{
			// constructor code
			tileName = name;
			
			switch(tileName)
			{
				default:
					tileProperty = PlatformerEnums.STANDARD;
					break;
			}
		}

	}
	
}
