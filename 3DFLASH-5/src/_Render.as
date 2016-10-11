package
{
	import base._Object3D;
	
	import flash.display.Stage;
	import flash.events.Event;
	/**
	 * 渲染者
     * -- 先渲染非透明的，再渲染透明的
     * -- 同一Z 优先渲染子容器再渲染父容器
	 * @author PC309
	 * 
	 */
	public class _Render
	{
		/**
		 * 需要被渲染的对象数组
		 */		
		public static var randerArr:Vector.<_Object3D> = new Vector.<_Object3D>;
		/**
		 * 启动渲染
		 * @param stage
		 * 
		 */		
		public static function startRender(stage:Stage):void
		{
			stage.addEventListener(Event.ENTER_FRAME,_Render.render)
		}
		/**
		 * 对需要渲染的人逐一渲染 
		 * @param e
		 * 
		 */		
		public static function render(e:Event):void{
			// 清空画面
			_Context3D.M.clear();
			// 遍历渲染者渲染
			for each (var i:_Object3D in randerArr){
				i.render();
			}
			// 发送至GPU
			_Context3D.M.present();
		}
		
		
		
		
		
	}
}