//------------------------------------------------------------------------------------------------------
// 实体
// -- 封装 x,y,z,roX,roY,roZ,scaleX,scaleY
// -- 封装addChild removeChild 
// -- 一些混合模式之类的 context3D API
// -- 
//------------------------------------------------------------------------------------------------------
package base
{
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	public class _Object3D
	{
		/**
		 * 本地矩阵 
		 */		
		public var mat_local:Matrix3D = new Matrix3D();
		/**
		 * 世界矩阵 
		 */		
		protected var mat_world:Matrix3D = new Matrix3D();
		/**
		 * 本地矩阵脏标记 
		 */		
		protected var mat_localDirty:Boolean;
		/**
		 * 本地矩阵脏标记 
		 */		
		protected var mat_worldDirty:Boolean;
		/**
		 * 位置向量
		 */		
		protected var postionV:Vector3D = new Vector3D();
		/**
		 * 旋转向量 
		 */		
		protected var rotationV:Vector3D = new Vector3D();
		/**
		 * 缩放向量 
		 */		
		protected var scaleV:Vector3D = new Vector3D(1,1,1);
		/**
		 * 贴图
		 */		
		protected var texture:Texture;
		/**
		 * 网格信息 
		 */		
		protected var mesh:_Mesh;
		/**
		 * 着色代码 
		 */		
		protected var shader:_Shader;
		/**
		 * 父节点 
		 */		
		protected var parent:_Object3D;
		/**
		 * 子节点 
		 */		
		protected var childs:Array = [];
		/**
		 * 最终矩阵 
		 */		
		protected static var finMat:Matrix3D = new Matrix3D();
		
		public function _Object3D(){
			
		}
		/**
		 * 设置模样
		 * @param texID
		 * @param meshID
		 * 
		 */		
		public function setLooks(texID:int=1,meshID:int=1):void{
			setTexture(texID);
			setMesh(meshID);
			setShader();
		}
		/**
		 * 设置纹理 
		 * @param id
		 * 
		 */		
		protected function setTexture(id:int):void{
			texture = _Texture.getTexture(id);
		}
		/**
		 * 设置模型
		 * @param id
		 * 
		 */		
		protected function setMesh(id:int):void{
			mesh = new _Mesh(id);
		}
		/**
		 * 设置代码 
		 * 
		 */		
		protected function setShader():void{
			shader = new _Shader();
		}
		/**
		 * 设置属性 
		 * @return 
		 * 
		 */		
		public function get x():Number{
		   return postionV.x;
		}
		public function set x(n:Number):void{
		   mat_local.appendTranslation(n-postionV.x,0,0);
		   postionV.x = n;
		}
		public function get y():Number{
			return postionV.y;
		}
		public function set y(n:Number):void{
			mat_local.appendTranslation(0,n-postionV.y,0);
			postionV.y = n;
		}
		public function get z():Number{
			return postionV.z;
		}
		public function set z(n:Number):void{
			mat_local.appendTranslation(0,0,n-postionV.z);
			postionV.z = n;
		}
		public function get rotationX():Number{
		    return rotationV.x;
		}
		public function set rotationX(n:Number):void{
			mat_local.appendRotation(n-rotationV.x,Vector3D.X_AXIS);
			rotationV.x = n;
		}
		public function get rotationY():Number{
			return rotationV.y;
		}
		public function set rotationY(n:Number):void{
			mat_local.appendRotation(n-rotationV.y,Vector3D.Y_AXIS);
			rotationV.y = n;
		}
		public function get rotationZ():Number{
			return rotationV.z;
		}
		public function set rotationZ(n:Number):void{
			mat_local.appendRotation(n-rotationV.z,Vector3D.Z_AXIS);
			rotationV.z = n;
		}
		public function get scaleX():Number{
			return scaleV.x;
		}
		public function set scaleX(n:Number):void{
			mat_local.appendScale(1+n-scaleV.x,1,1);
			scaleV.x = n;
		}
		public function get scaleY():Number{
			return scaleV.y;
		}
		public function set scaleY(n:Number):void{
			mat_local.appendScale(1,1+n-scaleV.y,1);
			scaleV.y = n;
		}
		/**
		 * 添加子显示对象
		 * @param obj
		 * 
		 */		
		public function addChild(obj:_Object3D):void{
			childs.push(obj);
			obj.parent = this;
		}
		/**
		 * 移除子显示对象 
		 * @param obj
		 * 
		 */		
		public function removeChild(obj:_Object3D):void{
			var idx:int = childs.indexOf(obj);
			if(idx==-1){return;}
			childs.splice(idx,1);
			obj.parent = null;
		}
		/**
		 * 获取我的世界矩阵信息
		 * 原理：不断与父容器的mat_local相乘
		 * @return 
		 * 
		 */		
		public function get matWorld():Matrix3D{
			if(parent){
			   var m:Matrix3D = mat_local.clone();
			   m.append(parent.matWorld);
			   return m;
			}
			return mat_local;
		}
		
		/**
		 * 物理的渲染 
		 *   -- 默认走这种渲染方式
		 * 
		 */		
		public function render():void{
			// 最终矩阵初始化
			finMat.identity();
			// MVP
			finMat.append(matWorld);
			finMat.append(_Camera3D.M.matWorld);
			finMat.append(_Camera3D.protMat);
			// 设置常量 VERTEX vc0=finMat
			_Context3D.M.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, finMat, true );
			// 设置我当前的代码
			_Context3D.M.setProgram(shader.program);
			// 设置我当前的贴图
			_Context3D.M.setTextureAt(0,texture);
			// 设置va0=坐标 va1=贴图坐标 va2=颜色
			_Context3D.M.setVertexBufferAt(0,mesh.vb,0,Context3DVertexBufferFormat.FLOAT_3);
			_Context3D.M.setVertexBufferAt(1,mesh.vb,3,Context3DVertexBufferFormat.FLOAT_2);
			_Context3D.M.setVertexBufferAt(2,mesh.vb,5,Context3DVertexBufferFormat.FLOAT_4);
			// 绘制三角形
			_Context3D.M.drawTriangles(mesh.ib,0);
			
		}
	}
}