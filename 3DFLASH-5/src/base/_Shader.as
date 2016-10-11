//------------------------------------------------------------------------------------------------------
// 绘制代码
//------------------------------------------------------------------------------------------------------
package base
{
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Program3D;

	public class _Shader
	{
		public var program:Program3D;
		private var _mode:int;
		public function _Shader(mode:int=0)
		{
			_mode = mode;
			if(mode==0)setShader();
			if(mode==1)setShader1();
			
		}
		private static var PROGRAM:Program3D;
		private static var PROGRAM_terrain:Program3D;
		// 一般物件的渲染代码
		private function setShader(){
		    if(!PROGRAM){
			  PROGRAM = _Context3D.M.createProgram();
			  var vShader:AGALMiniAssembler = new AGALMiniAssembler();
			  vShader.assemble(Context3DProgramType.VERTEX,
				"m44 op va0 vc0 \n" + 
				"mov v0 va0\n"+ // x y z 
				"mov v1 va1\n"+ // u v
				"mov v2 va2\n" // r g b a
			  
			  );
			  var fShader:AGALMiniAssembler = new AGALMiniAssembler();
			  fShader.assemble(Context3DProgramType.FRAGMENT,
				"tex ft0, v1, fs0 <2d,linear,repeat,nomip>\n"+
				"add ft1, v2, ft0\n" + 
				"add ft1, ft1, ft0\n" + 
				"mov oc, ft1\n"
			  );
			  PROGRAM.upload(vShader.agalcode,fShader.agalcode);
			
			}
			program = PROGRAM;
		}
		
		// -- 主要为了地形的渲染代码
		private function setShader1(){
			if(!PROGRAM_terrain){
				PROGRAM_terrain = _Context3D.M.createProgram();
				var vShader:AGALMiniAssembler = new AGALMiniAssembler();
				vShader.assemble(Context3DProgramType.VERTEX,
					"m44 vt1 va0 vc0\n" +
					"mov op vt1\n" + 
//					"m44 op va0 vc0\n"+
					"mov v0 va0\n"+ // x y z 
					"mov v1 va1\n"+ // u v
					"mov v2 va2\n"+ // r g b a
					"mov v3 va3\n"+ // 混合1 混合2 混合3
					"m44 vt0 va4 vc0 \n" + // 法线也要作用最终矩阵
					"mov v4 va4\n"+ // nx ny nz
//					"mov v4 vt0\n"+ // nx ny nz 作用M44
					"mov v5 vt1\n" // 最终坐标点
					
				);
				var fShader:AGALMiniAssembler = new AGALMiniAssembler();
				fShader.assemble(Context3DProgramType.FRAGMENT,
					"tex ft0, v1, fs0 <2d,linear,repeat,nomip>\n"+
					"tex ft1, v1, fs1 <2d,linear,repeat,nomip>\n"+
					"tex ft2, v1, fs2 <2d,linear,repeat,nomip>\n"+
					
					
					"mul ft0,ft0,v3.x\n"+ // 原图1*参数1
					
					"mul ft1,ft1,v3.y\n"+ // 原图2*参数2
					
					"mul ft2,ft2,v3.z\n"+ // 原图2*参数2
					
					
					
					"add ft0, ft1, ft0\n" +  // 混合图2 ADD
					
					"add ft0, ft2, ft0\n" +  // 混合图3 ADD
					
//					"mul ft0, v2, ft0\n" +  // 混合高位颜色
					
					
					
					// -- 法线平行光
					
					
					"dp3 ft4 fc2 v4\n" + // ft4=点积光和法线
					"mul ft0,ft0,ft4\n" + // 像素点*ft4
					"add ft0,ft0,fc3\n" + // 环境光
					
		
					
					
					
					"mov oc, ft0\n" // 输出
					
				);
				PROGRAM_terrain.upload(vShader.agalcode,fShader.agalcode);
				
			}
			program = PROGRAM_terrain;
		}
		
		
		
		
		
	}
}