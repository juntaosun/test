//------------------------------------------------------------------------------------------------------
// 纹理
//------------------------------------------------------------------------------------------------------
package base
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;

	public class _Texture
	{
		[Embed (source = "1.jpg")]
		private static var myTextureBitmap1:Class;
		private static var myTextureData1:Bitmap = new myTextureBitmap1();
		
		[Embed (source = "2.jpg")]
		private static var myTextureBitmap2:Class;
		private static var myTextureData2:Bitmap = new myTextureBitmap2();
		
		[Embed (source = "3.jpg")]
		private static var myTextureBitmap3:Class;
		private static var myTextureData3:Bitmap = new myTextureBitmap3();
		
		[Embed (source = "4.jpg")]
		private static var myTextureBitmap4:Class;
		private static var myTextureData4:Bitmap = new myTextureBitmap4();
		
		[Embed (source = "5.jpg")]
		private static var myTextureBitmap5:Class;
		private static var myTextureData5:Bitmap = new myTextureBitmap5();
		
		[Embed (source = "tile1.jpg")]
		private static var myTextureBitmap6:Class;
		private static var myTextureData6:Bitmap = new myTextureBitmap6();
		
		[Embed (source = "tile2.jpg")]
		private static var myTextureBitmap7:Class;
		private static var myTextureData7:Bitmap = new myTextureBitmap7();
		
		[Embed (source = "tile3.jpg")]
		private static var myTextureBitmap8:Class;
		private static var myTextureData8:Bitmap = new myTextureBitmap8();
		
		private static var texVec:Array = [];
		//------------------------------------------------------------------------------------------------------
		// 获取texture
		//------------------------------------------------------------------------------------------------------
		public static function getTexture(n:int):Texture{
			
		   if(n>=6){
			   var bd:BitmapData = getPicData(n);
			   if(texVec[n]==null){
				   texVec[n]=_Context3D.M.createTexture(bd.width,bd.height,Context3DTextureFormat.BGRA,true);
			   }
			   texVec[n].uploadFromBitmapData(getPicData(n));
			   
			   var t:Texture =_Context3D.M.createTexture(bd.width,bd.height,Context3DTextureFormat.BGRA,true);
		   
			   return texVec[n];
		   }	
			
			
		   if(n<1 || n>5){return null;}
		   if(texVec[n]==null){
			   texVec[n]=_Context3D.M.createTexture(512,512,Context3DTextureFormat.BGRA,true);
		   }
		   texVec[n].uploadFromBitmapData(getPicData(n));
		   
		   var t:Texture =_Context3D.M.createTexture(512,512,Context3DTextureFormat.BGRA,true);
		
		   
		   
		   return texVec[n];
		}
		// -- 获取bitmapdata
		private static function getPicData(n:int):BitmapData{
			return (_Texture["myTextureData"+String(n)] as Bitmap).bitmapData;
		}	
		
		
		
	
		
	}
}