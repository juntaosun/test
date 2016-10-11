package
{
	import base._Object3D;
	
	import com.adobe.utils.PerspectiveMatrix3D;
	
	import flash.display.Stage;
	import flash.geom.Matrix3D;
	/**
	 * 相机类 
	 *   继承于 _Object3D
	 * @author kds
	 * 
	 */
	public class _Camera3D extends _Object3D
	{
		/**
		 * 单例 
		 */		
		public static var M:_Camera3D;
		/**
		 * P矩阵 
		 */		
		public static var protMat:PerspectiveMatrix3D = new PerspectiveMatrix3D();
		/**
		 * 相机构造函数 
		 * @param stage
		 * 
		 */		
		public function _Camera3D(stage:Stage){
			// 记录单例
			M=this;
			// 设置P矩阵
			protMat.perspectiveFieldOfViewRH(45.0,1,0.01,5000.0);//stage.stageWidth/stage.stageHeight
			// 设置初始平移
		    this.mat_local.appendTranslation(0,0,30);
			// 反转相机矩阵
			this.mat_local.invert();
		}
	}
}