package openfl._internal.renderer.flash;


import openfl.display.BitmapData;
import openfl.display.Tilemap;
import openfl.geom.Point;

@:access(openfl.display.Tilemap)


class FlashTilemap {
	
	
	public static inline function render (tilemap:Tilemap):Void {
		
		#if flash
		if (tilemap.__tiles.length == 0 || tilemap.tileset == null) return;
		
		var bitmapData = tilemap.bitmapData;
		
		bitmapData.lock ();
		bitmapData.fillRect (bitmapData.rect, 0);
		
		var tile;
		var cacheTileID = -1;
		var sourceRect = null;
		var destPoint = new Point ();
		
		var sourceBitmapData = tilemap.tileset;
		
		var tiles = tilemap.__tiles;
		var count = tiles.length;
		
		for (i in 0...count) {
			
			tile = tiles[i];
			
			if (tile.id != cacheTileID) {
				
				sourceRect = tilemap.__rects[tile.id];
				cacheTileID = tile.id;
				
			}
			
			destPoint.x = tile.x;
			destPoint.y = tile.y;
			
			bitmapData.copyPixels (sourceBitmapData, sourceRect, destPoint, null, null, true);
			
		}
		
		bitmapData.unlock ();
		
		#end
		
	}
	
	
}