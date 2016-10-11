package f3d.core.components {

	import flash.events.EventDispatcher;
	
	import f3d.core.base.Object3D;
	import f3d.core.event.ComponentEvent;
	import f3d.core.interfaces.IComponent;
	import f3d.core.scene.Scene3D;
	
	[Event(name="ENABLE",  type="f3d.core.event.ComponentEvent")]
	[Event(name="DISABLE", type="f3d.core.event.ComponentEvent")]
	
	public class Component3D extends EventDispatcher implements IComponent {
		
		private static const ENABLE_EVENT  : ComponentEvent = new ComponentEvent(ComponentEvent.ENABLE);
		private static const DISABLE_EVENT : ComponentEvent = new ComponentEvent(ComponentEvent.DISABLE);
		
		public var object3D : Object3D;
		
		// 是否启用组件
		private var _enable : Boolean;
		
		public function Component3D() {
			super();
			this._enable = true;
		}
		
		public function onAdd(master : Object3D) : void {
			this.object3D = master;
		}

		public function onOtherComponentAdd(component : IComponent) : void {

		}

		public function onOtherComponentRemove(component : IComponent) : void {

		}

		public function onRemove(master : Object3D) : void {
			this.object3D = null;
		}
		
		public function onUpdate() : void {
			
		}
		
		public function onDraw(scene : Scene3D) : void {
			
		}
		
		/**
		 * 开/关组件 
		 * @param value
		 * 
		 */		
		public function set enable(value : Boolean) : void {
			if (enable == value) {
				return;
			}
			this._enable = value;
			if (value) {
				this.dispatchEvent(ENABLE_EVENT);
			} else {
				this.dispatchEvent(DISABLE_EVENT);
			}
			
		}
		
		/**
		 * 是否启用 
		 * @return 
		 */		
		public function get enable() : Boolean {
			return _enable;
		}

	}
}
