package openfl._internal.renderer.canvas;


import lime.graphics.utils.ImageCanvasUtil;
import openfl._internal.renderer.RenderSession;
import openfl.display.Tilemap;

@:access(openfl.display.BitmapData)
@:access(openfl.display.Tilemap)


class CanvasTilemap {
	
	
	public static inline function render (tilemap:Tilemap, renderSession:RenderSession):Void {
		
		#if (js && html5)
		
		if (!tilemap.__renderable || tilemap.__worldAlpha <= 0) return;
		
		if (tilemap.__tiles.length == 0 || tilemap.tileset == null) return;
		
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
		
		var tileRect = null;
		var cacheTileID = -1;
		
		ImageCanvasUtil.convertToCanvas (tilemap.tileset.image);
		var source = tilemap.tileset.image.src;
		
		var tile;
		var tiles = tilemap.__tiles;
		var count = tiles.length;
		var rects = tilemap.__rects;
		
		for (i in 0...count) {
			
			tile = tiles[i];
			
			if (tile.id != cacheTileID) {
				
				tileRect = rects[tile.id];
				cacheTileID = tile.id;
				
			}
			
			context.drawImage (source, tileRect.x, tileRect.y, tileRect.width, tileRect.height, tile.x, tile.y, tileRect.width, tileRect.height);
			
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