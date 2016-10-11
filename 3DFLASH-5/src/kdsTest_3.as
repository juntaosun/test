 //------------------------------------------------------------------------------------------------------
// 封装 
//   -- 渲染、相机、模型、实体、贴图、代码
//   -- 基本的层次叠加

//------------------------------------------------------------------------------------------------------
package
{
	import base._Object3D;
	import base._Texture;
	import base.terrain;
	
	import flash.display.Sprite;
	import flash.display3D.Context3D;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.ui.Keyboard;
	import flash.utils.setTimeout;

	[SWF(width="1200", height="700", frameRate="60", backgroundColor="#000000")]
	public class kdsTest_3 extends Sprite
	{
		private var player:_Object3D;
		private var moveSpeed:Number = 0.1;
		private var roSpeed:Number = 2;
		private var scaleSpeed:Number = 0.1;
		private var p2:_Object3D;
		private var p3:_Object3D;
		private var ter:terrain;
		public function kdsTest_3()
		{
			// 初始化context3D
			_Context3D.init(stage,c3dComplete);
		}
		private function c3dComplete():void{
			// 新建一个相机
		    new _Camera3D(stage);
			// 渲染者开始渲染
			_Render.startRender(stage);
			// 新建一个地形
			ter = new terrain();
			ter.setLooks(6,101);
			// 5秒后凸起
			setTimeout(function(){
				ter.setLooks(6,100);
			},5000)
			// 新建一个模型
			player = new _Object3D();
			player.setLooks(2,1);
			
			
			// 可渲染地形
			_Render.randerArr.push(ter);
			// 模型在地形上面
			ter.addChild(player);
			// 可渲染模型
			_Render.randerArr.push(player);
			
			
		    // 初始化地形的一些更改
			ter.x -= 30;
			ter.y -= 30;
			ter.scaleY = -1;
			
			// 相机再拉远一些
			_Camera3D.M.z = -50;
			
			// 键盘事件
			stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDown);
			
			
			// 鼠标事件
			stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseDown);
			stage.addEventListener(MouseEvent.MOUSE_MOVE,mouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP,mouseUp);
			stage.addEventListener(MouseEvent.MOUSE_WHEEL,mouseWheel);
			
			

		}
		
		private var isDown:Boolean;
		private var mouseP:Point = new Point();
		/**
		 * 
		 * @param e
		 * 
		 */		
		private function mouseDown(e:Event):void{
			isDown = true;
			mouseP.x = stage.mouseX;
			mouseP.y = stage.mouseY;
		}
		/**
		 * 
		 * @param e
		 * 
		 */		
		private function mouseMove(e:Event):void{
			 
			 if(isDown){
			    var dx:Number = stage.mouseX - mouseP.x;
				var dy:Number = stage.mouseY - mouseP.y;
				ter.rotationY += dx;
				ter.rotationX += dy;
				mouseP.x = stage.mouseX;
				mouseP.y = stage.mouseY;
			 }
		}
		/**
		 * 
		 * @param e
		 * 
		 */		
		private function mouseUp(e:Event):void{
			isDown=false;
		}
		
		/**
		 *  
		 * 
		 */		
		private function mouseWheel(e:MouseEvent):void{
			_Camera3D.M.z += e.delta/10;
		}
		
		private function keyDown(e:KeyboardEvent):void{
			switch(e.keyCode){
				case Keyboard.LEFT:
					ter.x+=moveSpeed;
					break;
				case Keyboard.RIGHT:
					ter.x-=moveSpeed;
					break;
				case Keyboard.UP:
					if(e.ctrlKey){
						ter.y+=moveSpeed;
						return;
					}
					ter.z-=moveSpeed;
					break;
				case Keyboard.DOWN:
					if(e.ctrlKey){
						ter.y-=moveSpeed;
						return;
					}
					ter.z+=moveSpeed;
					break;
				case Keyboard.NUMPAD_0:
					ter.rotationX+=roSpeed;
					break;
				case Keyboard.NUMPAD_1:
					ter.rotationX-=roSpeed;
					break;
				case Keyboard.NUMPAD_2:
					ter.rotationY-=roSpeed;
					break;
				case Keyboard.NUMPAD_3:
					ter.rotationY+=roSpeed;
					break;
				case Keyboard.NUMPAD_4:
					ter.rotationZ-=roSpeed;
					break;
				case Keyboard.NUMPAD_5:
					ter.rotationZ+=roSpeed;
					break;
				case Keyboard.NUMPAD_6:
					ter.scaleX+=scaleSpeed;
					break;
				case Keyboard.NUMPAD_7:
					ter.scaleX-=scaleSpeed;
					break;
				
				case Keyboard.NUMBER_1:
					terrain.setTex1(0,0.05);
					break;
				case Keyboard.NUMBER_2:
					terrain.setTex1(0,-0.05);
					break;
				case Keyboard.NUMBER_3:
					terrain.setTex1(1,0.05);
					
					break;
				case Keyboard.NUMBER_4:
					terrain.setTex1(1,-0.05);
					
					break;
				case Keyboard.NUMBER_5:
					terrain.setTex1(2,0.05);
					
					break;
				case Keyboard.NUMBER_6:
					terrain.setTex1(2,-0.05);
					
					break;
				
				case Keyboard.W:
					terrain.lightP.y+=1;
					break;
				case Keyboard.A:
					terrain.lightP.x-=1;
					break;
				case Keyboard.S:
					terrain.lightP.y-=1;
					break;
				case Keyboard.D:
					terrain.lightP.x+=1;
					break;
				
				

			}
			
			player.x = terrain.lightP.x;
			player.y = terrain.lightP.y;
			player.z = terrain.lightP.z;
			
				
				

		}
		
		
		
		
		
	}
}