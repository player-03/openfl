package openfl._internal.renderer.opengl;


import lime.utils.Float32Array;
import openfl._internal.renderer.RenderSession;
import openfl.display.Tilemap;
import openfl.display.Tile;
import openfl.display.TileData;
import openfl.filters.ShaderFilter;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;

@:access(openfl.display.Tilemap)
@:access(openfl.display.Tile)
@:access(openfl.display.TileData)


class GLTilemap {
	
	
	public static function render (tilemap:Tilemap, renderSession:RenderSession):Void {
		
		if (tilemap.__tiles.length == 0) return;
		
		var gl = renderSession.gl;
		var shader;
		
		if (tilemap.filters != null && Std.is (tilemap.filters[0], ShaderFilter)) {
			
			shader = cast (tilemap.filters[0], ShaderFilter).shader;
			
		} else {
			
			shader = renderSession.shaderManager.defaultShader;
			
		}
		
		renderSession.blendModeManager.setBlendMode (tilemap.blendMode);
		renderSession.shaderManager.setShader (shader);
		renderSession.maskManager.pushObject (tilemap);
		
		var renderer:GLRenderer = cast renderSession.renderer;
		
		gl.uniform1f (shader.data.uAlpha.index, tilemap.__worldAlpha);
		gl.uniformMatrix4fv (shader.data.uMatrix.index, false, renderer.getMatrix (tilemap.__worldTransform));
		
		var tile;
		var tiles = tilemap.__tiles;
		var tileDataArray = tilemap.__tileData;
		var count = tiles.length;
		
		var bufferData = tilemap.__bufferData;
		
		if (bufferData == null || tilemap.__dirty || bufferData.length != count * 24) {
			
			var startIndex = 0;
			
			if (bufferData == null) {
				
				bufferData = new Float32Array (count * 24);
				
			} else if (bufferData.length != count * 24) {
				
				if (!tilemap.__dirty) {
					
					startIndex = Std.int (bufferData.length / 24);
					
				}
				
				var data = new Float32Array (count * 24);
				data.set (bufferData);
				bufferData = data;
				
			}
			
			for (i in startIndex...count) {
				
				tile = tiles[i];
				updateTileUV (tile, tileDataArray[tile.id], i * 24, bufferData);
				
			}
			
			tilemap.__bufferData = bufferData;
			
		}
		
		if (tilemap.__buffer == null) {
			
			tilemap.__buffer = gl.createBuffer ();
			
		}
		
		gl.bindBuffer (gl.ARRAY_BUFFER, tilemap.__buffer);
		
		var tileWidth = 0, tileHeight = 0;
		var offset, tileData, tileMatrix, x, y, x2, y2, x3, y3, x4, y4;
		
		for (i in 0...count) {
			
			tile = tiles[i];
			tileData = tileDataArray[tile.id];
			tileWidth = tileData.width;
			tileHeight = tileData.height;
			
			offset = i * 24;
			
			if (tile.__uvsDirty) {
				
				updateTileUV (tile, tileData, offset, bufferData);
				
			}
			
			if (tile.__transformDirty) {
				
				tileMatrix = tile.matrix;
				
				x = tile.__transform[0] = tileMatrix.__transformX (0, 0);
				y = tile.__transform[1] = tileMatrix.__transformY (0, 0);
				x2 = tile.__transform[2] = tileMatrix.__transformX (tileWidth, 0);
				y2 = tile.__transform[3] = tileMatrix.__transformY (tileWidth, 0);
				x3 = tile.__transform[4] = tileMatrix.__transformX (0, tileHeight);
				y3 = tile.__transform[5] = tileMatrix.__transformY (0, tileHeight);
				x4 = tile.__transform[6] = tileMatrix.__transformX (tileWidth, tileHeight);
				y4 = tile.__transform[7] = tileMatrix.__transformY (tileWidth, tileHeight);
				
				tile.__transformDirty = false;
				
			} else {
				
				x = tile.__transform[0];
				y = tile.__transform[1];
				x2 = tile.__transform[2];
				y2 = tile.__transform[3];
				x3 = tile.__transform[4];
				y3 = tile.__transform[5];
				x4 = tile.__transform[6];
				y4 = tile.__transform[7];
				
			}
			
			bufferData[offset + 0] = x;
			bufferData[offset + 1] = y;
			bufferData[offset + 4] = x2;
			bufferData[offset + 5] = y2;
			bufferData[offset + 8] = x3;
			bufferData[offset + 9] = y3;
			
			bufferData[offset + 12] = x3;
			bufferData[offset + 13] = y3;
			bufferData[offset + 16] = x2;
			bufferData[offset + 17] = y2;
			bufferData[offset + 20] = x4;
			bufferData[offset + 21] = y4;
			
		}
		
		gl.bufferData (gl.ARRAY_BUFFER, bufferData, gl.DYNAMIC_DRAW);
		
		gl.vertexAttribPointer (shader.data.aPosition.index, 2, gl.FLOAT, false, 4 * Float32Array.BYTES_PER_ELEMENT, 0);
		gl.vertexAttribPointer (shader.data.aTexCoord.index, 2, gl.FLOAT, false, 4 * Float32Array.BYTES_PER_ELEMENT, 2 * Float32Array.BYTES_PER_ELEMENT);
		
		var cacheBitmapData = tileDataArray[tiles[0].id].bitmapData;
		var lastIndex = 0;
		
		for (i in 0...count) {
			
			tileData = tileDataArray[tiles[i].id];
			
			if (tileData.bitmapData != cacheBitmapData) {
				
				gl.bindTexture (gl.TEXTURE_2D, cacheBitmapData.getTexture (gl));
				gl.drawArrays (gl.TRIANGLES, lastIndex * 6, i * 6);
				
				cacheBitmapData = tileData.bitmapData;
				lastIndex = i;
				
			}
			
		}
		
		gl.bindTexture (gl.TEXTURE_2D, cacheBitmapData.getTexture (gl));
		gl.drawArrays (gl.TRIANGLES, lastIndex * 6, count * 6);
		
		tilemap.__dirty = false;
		renderSession.maskManager.popObject (tilemap);
		
	}
	
	
	private static inline function updateTileUV (tile:Tile, tileData:TileData, tileOffset:Int, bufferData:Float32Array):Void {
		
		var u = tileData.__uvLeft;
		var v = tileData.__uvTop;
		var u2 = tileData.__uvRight;
		var v2 = tileData.__uvBottom;
		
		bufferData[tileOffset + 2] = u;
		bufferData[tileOffset + 3] = v;
		bufferData[tileOffset + 6] = u2;
		bufferData[tileOffset + 7] = v;
		bufferData[tileOffset + 10] = u;
		bufferData[tileOffset + 11] = v2;
		
		bufferData[tileOffset + 14] = u;
		bufferData[tileOffset + 15] = v2;
		bufferData[tileOffset + 18] = u2;
		bufferData[tileOffset + 19] = v;
		bufferData[tileOffset + 22] = u2;
		bufferData[tileOffset + 23] = v2;
		
		tile.__uvsDirty = false;
		
	}
	
	
}
