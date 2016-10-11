//------------------------------------------------------------------------------------------------------
// 网格：存放XYZ UV RGBA
//------------------------------------------------------------------------------------------------------
package base
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;

	public class _Mesh
	{
		// 高度图
		[Embed (source = "gg.raw",mimeType="application/octet-stream")]
		private static var heightMapClass:Class;
		private static var heightMapBy:ByteArray = new heightMapClass() as ByteArray;
		private static var heightMap:Array = []; // 65*65 储存的是顶点的高度
		
		
		// 透明图
		[Embed (source = "alphaMap4.png")]
		private static var alphaMapClass:Class;
		private static var alphaMapBitmap:Bitmap = new alphaMapClass();
		private static var alphaMap:Array = []; // [r,g,b]、[r,g,b] 储存的是块的混合方式
		
		// 我的VB
		public var vb:VertexBuffer3D;
		// 我的IB
		public var ib:IndexBuffer3D;
		public function _Mesh(id:int){
			// -- 设置好vb和ib并上传好
			setVbIb(id);
			// -- 地形样式
			if(id==100){
			  setVbIb_Terrain();
			}
			else if(id==101){
			  setVbIb_Terrain(true);
			}
		}
		
		//------------------------------------------------------------------------------------------------------
		// 设置地形的顶点和索引 
		// 1.将所有点绘制出来，同时根据高度图计算
		// 2.将透明图写入到VB里面，方便后面着色的时候使用该图的数据（每个像素点的RGB作为三张图的混合方式）
		//------------------------------------------------------------------------------------------------------
		private function setVbIb_Terrain(isFlat:Boolean=false):void{
			// -- png 透明图
			var alphaMapBD:BitmapData = alphaMapBitmap.bitmapData;
			// -- raw 高度图 从横往右数
			while(heightMapBy.bytesAvailable){
				heightMap.push(heightMapBy.readUnsignedByte());
			}
			var heightMapWidth:int = Math.pow(heightMap.length,0.5);
			// -- 绘制顶点、UV、法线、
			var w:int = 64;
			var h:int = 64;
			var vbLineSize:int = 16; 
			// -- 遍历点
			var vbvb:Vector.<Number> = Vector.<Number>([]);
			for(var x:int=0;x<=w;x++){
				for(var y:int=0;y<=h;y++){
					// 高度 因为高度
					var vecH:Number = heightMap[(h-y)*(w+1)+x%w]/5;
					if(isFlat)vecH = 0;
				    // 顶点 0,0  0,1  
					var vec:Vector3D = new Vector3D(x,y,vecH);
					// UV 和坐标对齐
					var uv:Point = new Point(x%2,y%2);
					// 颜色混合，暂时没有用到
					var mix:Vector3D = new Vector3D(1,1,1,1);
					// *透明图效果（R、G、B）
					var alphaMapColor:uint = alphaMapBD.getPixel(x,y);
					var rgbStr:String = alphaMapColor.toString(16);
					while(rgbStr.length!=6)rgbStr="0"+rgbStr;
					var texR:uint = uint("0x"+rgbStr.substr(0,2));
					var texG:uint = uint("0x"+rgbStr.substr(2,2));
					var texB:uint = uint("0x"+rgbStr.substr(4,2));
					// 按比例分配
					var allRGB:uint = texR+texG+texB;
					var texMix1:Number = texR/allRGB;
					var texMix2:Number = texG/allRGB;
					var texMix3:Number = texB/allRGB;
					
					// 法线待后面计算
					
					// x y z u v r g b a 混合1 混合2 混合3 1 法线X 法线Y 法线Z(法线在后面计算)
					vbvb.push(vec.x , vec.y, vec.z, uv.x, uv.y, mix.x, mix.y, mix.z, mix.w,texMix1,texMix2,texMix3,1,0,0,1);
				}
			}
			// -- 添加索引，用于绘制
			var ibib:Vector.<uint> = Vector.<uint>([]);
			var py:int = 0;
			for(var x:int=0;x<w;x++){
				for(var y:int=0;y<h;y++){
					var p0:int = 0+int(py/h)*(h+1)+py%h;
					var p1:int = p0+1;
					var p2:int = p1+(h+1);
					var p3:int = p2-1;
					ibib.push(
						p0,p1,p2,
						p2,p3,p0
					);
					py++;
				}
			}
//			trace("check",vbvb.length/16,ibib.length/6);
			
			
			// 法线追加
			for (var x:int=0;x<w;x++){
				for (var y:int=0;y<h;y++){
					
					var mi:int = y+x*w;
					
//					trace("法线中心点IDX=",mi);
					
					var size:int = vbLineSize;
					
					var point5:Array = [];
					var addToPoint5:Function = function(vbIdx:int,ptIdx:int):void{
						var px:int = vbvb[vbIdx];
						var py:int = vbvb[vbIdx+1];
						var pz:int = vbvb[vbIdx+2];
						point5[ptIdx] = [px,py,pz];
					}
						
					// 获取中心点
					var p1Idx:int = mi*size;;
					
					
					
					addToPoint5(p1Idx,0);
					
					// -- 中心点左边
					var p2Idx:int = p1Idx - h*size;
					if(p2Idx>0){
						addToPoint5(p2Idx,1);
					}
					
					// -- 中心点上面
					var p3Idx:int = p1Idx - 1*size;
					if(p3Idx>0){
						addToPoint5(p3Idx,2);
					}
					
					// -- 中心点右边
					var p4Idx:int = p1Idx + h*size;
					if(p4Idx<vbvb.length){
						addToPoint5(p4Idx,3);
					} 
					
					// -- 中心点下边
					var p5Idx:int = p1Idx + 1*size;
					if(p5Idx<vbvb.length){
						addToPoint5(p5Idx,4);
					} 				
					
					
					
					// -- 获取所有的法线，即中心点（point5[0]）与别的两个边的形成的最多4个面
					var normalArray:Array = [];
					// -- 0 1 2
					if(point5[0]&&point5[1]&&point5[2]){
						normalArray.push(getNormal(point5[0],point5[1],point5[2]));
					}
					// -- 0 2 3
					if(point5[0]&&point5[2]&&point5[3]){
						normalArray.push(getNormal(point5[0],point5[2],point5[3]));
					}
					// -- 0 3 4
					if(point5[0]&&point5[3]&&point5[4]){
						normalArray.push(getNormal(point5[0],point5[3],point5[4]));
					}
					// -- 0 4 1
					if(point5[0]&&point5[4]&&point5[1]){
						normalArray.push(getNormal(point5[0],point5[4],point5[1]));
					}
					
					// -- 
					var vAll:Vector3D = new Vector3D();
					for each(var v:Vector3D in normalArray){
						vAll.x += v.x;
						vAll.y += v.y;
						vAll.z += v.z;
					}
					vAll.x = vAll.x/normalArray.length;
					vAll.y = vAll.y/normalArray.length;
					vAll.z = vAll.z/normalArray.length;
					vAll.normalize();
					
					vAll = normalArray[0];
					vAll.normalize();
					
					
					
					// -- 找到VB插入进去
					vbvb[p1Idx+13] = vAll.x;
					vbvb[p1Idx+14] = vAll.y;
					vbvb[p1Idx+15] = vAll.z;
					
				}
			}
			
			
			// -- 上传
			var _vb:VertexBuffer3D = _Context3D.M.createVertexBuffer(vbvb.length/vbLineSize,vbLineSize);
			_vb.uploadFromVector(vbvb,0,vbvb.length/vbLineSize);
			
			var _ib:IndexBuffer3D = _Context3D.M.createIndexBuffer(ibib.length);
			_ib.uploadFromVector(ibib,0,ibib.length);
			
			vb = _vb;
			ib = _ib;
		
		}

		
		
		/**
		 * 给定三角形的三个点返回一个法线给我 叉乘
		 * @param Point1
		 * @param Point2
		 * @param Point3
		 * @return 
		 * 
		 */		
		private function getNormal(Point1:Array, Point2:Array, Point3:Array):Vector3D
		{
			var source2:Vector3D = new Vector3D(Point2[0]-Point1[0],Point2[1]-Point1[1],Point2[2]-Point1[2]);
			var source1:Vector3D = new Vector3D(Point3[0]-Point1[0],Point3[1]-Point1[1],Point3[2]-Point1[2]);
			var norV:Vector3D = new Vector3D();
			norV.x = source1.y * source2.z - source1.z * source2.y;
			norV.y = source1.z * source2.x - source1.x * source2.z;
			norV.z = source1.x * source2.y - source1.y * source2.x;
			norV.normalize();
			return norV;
		}

		//------------------------------------------------------------------------------------------------------
		// 库
		//------------------------------------------------------------------------------------------------------
		// -- 正方形
		private static var vbV1:Vector.<Number> = Vector.<Number>([
			// X、Y、Z、U、V、R、G、B、A
			-1,1,0,0,0,  1.0,0.0,0.0,0.1,
			1,1,0,1,0,   1.0,0.0,0.0,0.1,
			1,-1,0,1,1,  1.0,0.0,0.0,0.1,
			-1,-1,0,0,1, 1.0,0.0,0.0,0.1
		]);
		private static var ibV1:Vector.<uint> = Vector.<uint>([
			0,1,2,
			2,3,0
		]);
		// -- 三角形
		private static var vbV2:Vector.<Number> = Vector.<Number>([
			// X、Y、Z、U、V、R、G、B、A
			-1,1,0,0,0,1,0,0,1,
			1,1,0,1,0,0,1,0,1,
			1,-1,0,1,1,0,0,1,1,

		]);
		private static var ibV2:Vector.<uint> = Vector.<uint>([
			0,1,2
		]);
		private static var vbMode1:VertexBuffer3D;
		private static var ibMode1:IndexBuffer3D;

		private static var vbMode2:VertexBuffer3D;
		private static var ibMode2:IndexBuffer3D;

		private function setVbIb(id:int):void{
			if(id<1 || id>2){return;}
			var _vb:VertexBuffer3D = _Mesh["vbMode"+String(id)];
			var _ib:IndexBuffer3D = _Mesh["ibMode"+String(id)];
			var _vv:Vector.<Number> = _Mesh["vbV"+String(id)];
			var _iv:Vector.<uint> = _Mesh["ibV"+String(id)];
			if(_vb==null){
			  _vb = _Context3D.M.createVertexBuffer(_vv.length/9,9);
			  _vb.uploadFromVector(_vv,0,_vv.length/9);
			  _ib = _Context3D.M.createIndexBuffer(_iv.length);
			  _ib.uploadFromVector(_iv,0,_iv.length);
			  _Mesh["vbMode"+String(id)] = _vb;
			  _Mesh["ibMode"+String(id)] = _ib;
			}
			vb = _vb;
			ib = _ib;
		}
		
		
		
	}
}


