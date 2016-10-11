package
{
	import flash.display.Stage;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	/**
	 * 封装 Context3D
	 * @author kds
	 * 
	 */
	public class _Context3D
	{
		// 最终矩阵M
		public static var M:Context3D;
		// 是否已创建标志
		private static var alreadyCreaded:Boolean;
		// 创建完成时方法回调
		private static var _onFin:Function
		// falsh的舞台
		private static var _stage:Stage;
		public static function init(stage:Stage,onFin:Function):void{
		  // 环境检测 
		  if(stage.stage3Ds.length==0)
			   return;
		  // 侦听和开启
		  stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE,created);
		  stage.stage3Ds[0].addEventListener(ErrorEvent.ERROR,error);
		  stage.stage3Ds[0].requestContext3D();
		  _onFin = onFin;
		  _stage = stage;
		   
		}
		//------------------------------------------------------------------------------------------------------
		// 创建时
		//------------------------------------------------------------------------------------------------------
		private static function error(e:ErrorEvent):void{
			trace("创建出错-1");
		}
		private static function created(e:Event):void{
		    M = (e.target as Stage3D).context3D;
			if(M==null){
			   trace("创建出错-2");
			   return;
			}
			// 开启AGAL报错
			M.enableErrorChecking=true;
			// 已创建不再回调
			if(alreadyCreaded){
			   trace("已经创建，暂没有制作恢复设备的事宜");
			   return;
			}
			// 配置后台缓冲区
			M.configureBackBuffer(_stage.stageWidth,_stage.stageHeight,0,true);
			// 创建完成时通知
			_onFin();
		}
	}
}