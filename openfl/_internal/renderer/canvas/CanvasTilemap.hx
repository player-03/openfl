package openfl._internal.renderer.canvas;


import lime.graphics.utils.ImageCanvasUtil;
import openfl._internal.renderer.RenderSession;
import openfl.display.Tilemap;

@:access(lime.graphics.ImageBuffer)
@:access(openfl.display.BitmapData)
@:access(openfl.display.Tilemap)


class CanvasTilemap {
	
	
	public static inline function render (tilemap:Tilemap, renderSession:RenderSession):Void {
		
		#if (js && html5)
		
		if (!tilemap.__renderable || tilemap.__tiles.length == 0 || tilemap.__worldAlpha <= 0) return;
		
		var context = renderSession.context;
		
		renderSession.maskManager.pushObject (tilemap);
		
		context.globalAlpha = tilemap.__worldAlpha;
		var transform = tilemap.__worldTransform;
		
		if (renderSession.roundPixels) {
			
			context.setTransform (transform.a, transform.b, transform.c, transform.d, Std.int (transform.tx), Std.int (transform.ty));
			
		} else {
			
			context.setTransform (transform.a, transform.b, transform.c, transform.d, transform.tx, transform.ty);
			
		}
		
		if (!tilemap.smoothing) {
			
			untyped (context).mozImageSmoothingEnabled = false;
			//untyped (context).webkitImageSmoothingEnabled = false;
			untyped (context).msImageSmoothingEnabled = false;
			untyped (context).imageSmoothingEnabled = false;
			
		}
		
		var cacheBitmapData = null;
		var source = null;
		
		var tile, tileData, bitmapData;
		
		var tiles = tilemap.__tiles;
		var tileDataArray = tilemap.__tileData;
		var count = tiles.length;
		
		for (i in 0...count) {
			
			tile = tiles[i];
			tileData = tileDataArray[tile.id];
			bitmapData = tileData.bitmapData;
			
			if (bitmapData == null) continue;
			
			if (bitmapData != cacheBitmapData) {
				
				if (tileData.bitmapData.image.buffer.__srcImage == null) {
					
					ImageCanvasUtil.convertToCanvas (tileData.bitmapData.image);
					
				}
				
				source = bitmapData.image.src;
				cacheBitmapData = tileData.bitmapData;
				
			}
			
			context.drawImage (source, tileData.x, tileData.y, tileData.width, tileData.height, tile.x, tile.y, tileData.width, tileData.height);
			
		}
		
		if (!tilemap.smoothing) {
			
			untyped (context).mozImageSmoothingEnabled = true;
			//untyped (context).webkitImageSmoothingEnabled = true;
			untyped (context).msImageSmoothingEnabled = true;
			untyped (context).imageSmoothingEnabled = true;
			
		}
		
		renderSession.maskManager.popObject (tilemap);
		
		#end
		
	}
	
	
}