package base
{
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	public class terrain extends _Object3D
	{
		public function terrain()
		{
			super();
		}
		
		private var tex1:Texture;
		private var tex2:Texture;
		private var tex3:Texture;
		
		
		private static var texBlend:Array = [0.33,0.33,0.34];
		public static var lightP:Vector3D = new Vector3D(32,-32,30,0);
		public static function setTex1(n:int,v:Number):void{
			if(n==0){
			   var now:Number = texBlend[0];
			   if(now+v>1||now+v<0)return;
			   now+=v;
			   var elseV:Number = 1-now; // 剩余总和
			   var elseNowV:Number = texBlend[1]+texBlend[2]; // 当前总和
			   texBlend[1] = texBlend[1]*(elseV/elseNowV);
			   texBlend[2] = elseV - texBlend[1];
			   texBlend[0] = now;
			}
			else if(n==1){
				var now:Number = texBlend[1];
				if(now+v>1||now+v<0)return;
				now+=v;
				var elseV:Number = 1-now; // 剩余总和
				var elseNowV:Number = texBlend[0]+texBlend[2]; // 当前总和
				texBlend[0] = texBlend[0]*(elseV/elseNowV);
				texBlend[2] = elseV - texBlend[0];
				texBlend[1] = now;
			
			}
			else if(n==2){
				var now:Number = texBlend[2];
				if(now+v>1||now+v<0)return;
				now+=v;
				var elseV:Number = 1-now; // 剩余总和
				var elseNowV:Number = texBlend[0]+texBlend[1]; // 当前总和
				texBlend[0] = texBlend[0]*(elseV/elseNowV);
				texBlend[1] = elseV - texBlend[0];
				texBlend[2] = now;
			}
			trace(texBlend)
			
		}
		
		
		
		public override function setLooks(texID:int=1,meshID:int=1):void{
			tex1 = _Texture.getTexture(6);
			tex2 = _Texture.getTexture(7);
			tex3 = _Texture.getTexture(8);
			setMesh(meshID);
			shader = new _Shader(1);
		}
		
		public override function render():void{
//			return;
			finMat.identity();
			
			
			finMat.append(matWorld);
			finMat.append(_Camera3D.M.matWorld);
			finMat.append(_Camera3D.protMat);
			
			
			
			_Context3D.M.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,0,Vector.<Number>([texBlend[0],texBlend[1],texBlend[2],1]));
			_Context3D.M.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, finMat, true );
			
			
			// -- 设置一个静态法线
			var fx:Vector3D = new Vector3D(0,0,1);
			fx.normalize();
			
			// 光点转换
			var matWorldV:Matrix3D = matWorld.clone(); // 获得模型矩阵的副本 
			matWorldV.invert(); // 反转
			var light:Vector3D=matWorldV.deltaTransformVector(lightP); // 不含平移元素的变换
			light.normalize(); // 单位化
			_Context3D.M.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,2,Vector.<Number>([light.x,light.y,light.z,0]));
			
			
			
//			light.normalize();
			
			// -- 静态法线，没有用到
			_Context3D.M.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,1,Vector.<Number>([fx.x,fx.y,fx.z,0]));
			
			
			
			
			// -- 全局光
			_Context3D.M.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,3,Vector.<Number>([0.45,0.5,0.5,0]));
			
			
			_Context3D.M.setDepthTest(true, Context3DCompareMode.LESS_EQUAL);
			
			
			
			_Context3D.M.setProgram(shader.program);
			_Context3D.M.setTextureAt(0,tex1);
			_Context3D.M.setTextureAt(1,tex2);
			_Context3D.M.setTextureAt(2,tex3);
			
			_Context3D.M.setVertexBufferAt(0,mesh.vb,0,Context3DVertexBufferFormat.FLOAT_3); // x y z
			_Context3D.M.setVertexBufferAt(1,mesh.vb,3,Context3DVertexBufferFormat.FLOAT_2); // u v
			_Context3D.M.setVertexBufferAt(2,mesh.vb,5,Context3DVertexBufferFormat.FLOAT_4); // r g b a
			_Context3D.M.setVertexBufferAt(3,mesh.vb,9,Context3DVertexBufferFormat.FLOAT_4); // 混合1 混合2 混合3 1
			_Context3D.M.setVertexBufferAt(4,mesh.vb,13,Context3DVertexBufferFormat.FLOAT_3); // nx ny nz
			
			
			_Context3D.M.drawTriangles(mesh.ib,0);
			_Context3D.M.setTextureAt(1,null);
			_Context3D.M.setTextureAt(2,null);
			_Context3D.M.setVertexBufferAt(0,null); // x y z
			_Context3D.M.setVertexBufferAt(1,null); // u v
			_Context3D.M.setVertexBufferAt(2,null); // r g b a
			_Context3D.M.setVertexBufferAt(3,null); // 混合1 混合2 混合3 1
			_Context3D.M.setVertexBufferAt(4,null); // nx ny nz
			
			
		}
		
		
	}
}