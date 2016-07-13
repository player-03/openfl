package openfl.display;


class TileData {
	
	
	public var bitmapData (default, set):BitmapData;
	public var x (default, set):Int;
	public var y (default, set):Int;
	public var width (default, set):Int;
	public var height (default, set):Int;
	
	private var __uvLeft:Float;
	private var __uvTop:Float;
	private var __uvRight:Float;
	private var __uvBottom:Float;
	
	
	public function new (?bitmapData:BitmapData, x:Int = 0, y:Int = 0, width:Int = 0, height:Int = 0) {
		
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
		this.bitmapData = bitmapData;
		
	}
	
	
	@:noCompletion private function __updateUVs ():Void {
		
		if (bitmapData != null) {
			
			__uvLeft = x / bitmapData.width;
			__uvTop = y / bitmapData.height;
			__uvRight = (x + width) / bitmapData.width;
			__uvBottom = (y + height) / bitmapData.height;
			
		}
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	@:noCompletion private function set_bitmapData (value:BitmapData):BitmapData {
		
		this.bitmapData = value;
		__updateUVs ();
		return value;
		
	}
	
	
	@:noCompletion private function set_height (value:Int):Int {
		
		this.height = value;
		__updateUVs ();
		return value;
		
	}
	
	
	@:noCompletion private function set_width (value:Int):Int {
		
		this.width = value;
		__updateUVs ();
		return value;
		
	}
	
	
	@:noCompletion private function set_x (value:Int):Int {
		
		this.x = value;
		__updateUVs ();
		return value;
		
	}
	
	
	@:noCompletion private function set_y (value:Int):Int {
		
		this.y = value;
		__updateUVs ();
		return value;
		
	}
	
	
}