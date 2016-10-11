package
{
	import com.adobe.utils.AGALMiniAssembler;
	import com.adobe.utils.PerspectiveMatrix3D;
	
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DRenderMode;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.ui.Keyboard;

	[SWF(width="800", height="600", frameRate="60", backgroundColor="#000000")]
	public class Main extends Sprite
	{
		/**
		 * 是否首次创建3D环境
		 */		
		private var isFirstCreate:Boolean = true;
		/**
		 * 唯一状态机/画家 
		 */		
		private var context3d:Context3D;
		/**
		 * 模型M矩阵
		 */		
		private var modelMatrix:Matrix3D;
		/**
		 * 镜头V矩阵
		 */		
		private var viewMatrix:Matrix3D;
		/**
		 * 投影P矩阵，Adobe封装的，继承于Matrix3D
		 */		
		private var projectionMatrix:PerspectiveMatrix3D;
		/**
		 * 最终矩阵，这个应该是M+V+P 
		 */		
		private var finalMatrix:Matrix3D;
		/**
		 * flash要用到的顶点信息：顶点缓冲数据 
		 */		
		private var modelVb:VertexBuffer3D;
		/**
		 * flash要用到的顶点索引信息：索引缓冲数据 告诉系统点的绘制顺序，系统才知道有多少个面，是怎样的面 
		 */		
		private var modelIb:IndexBuffer3D;
		/**
		 * 画家绘制的代码，就是你告诉他应该如何绘制，调色等，他会按照这个方式来绘制，当然也是程序，汇编的风格... 也就是说你可以预先定制好N个代码来选择哪一个来绘制
		 */		
		private var program:Program3D;
		/**
		 * 当鼠标移动的时候记录的鼠标点 
		 */		
		private var onMouseDownPt:Point = new Point();
		
		
	   
		public function Main()
		{
			// 初始化
			init();
		}
		
		/**
		 * 初始化 
		 * 
		 */		
		private function init():void{
		   // -- 如果没有3D环境的话
		   if(stage.stage3Ds.length==0){
			  throw("你没有可用的3D环境！");
		      return;
		   }
		   // -- 取得一个stage3D舞台，这里取下标0，因为这个3D舞台100%存在。
		   var stage3d:Stage3D = stage.stage3Ds[0];
		   // -- 设置侦听：创建失败的情况
		   stage3d.addEventListener(ErrorEvent.ERROR,onCreate3dError);
		   // -- 设置侦听：创建成功的情况或设备恢复的情况
		   stage3d.addEventListener(Event.CONTEXT3D_CREATE,onCreate3dSuccess);
		   // -- 请求创建，如果你不请求创建，那么又有什么用呢？渲染模式为硬件模式，表示使用显卡GPU来计算
		   stage3d.requestContext3D(Context3DRenderMode.AUTO);
		}
		/**
		 * 创建3D环境失败 
		 * @param e
		 * 
		 */		
		private function onCreate3dError(e:ErrorEvent):void{
			throw("创建3D环境失败！");
		}
		/**
		 * 创建3D环境成功的情况或设备恢复的情况 
		 * @param e
		 * 
		 */		
		private function onCreate3dSuccess(e:Event):void{
			// 如果找不到状态机context3d的话提示错误
			context3d = (e.target as Stage3D).context3D;
			if(context3d==null){
			   throw("创建3D环境失败!");
			   return;
			}
			// 当发生错误的时候会显示错误信息，着色语言阶段出错时开启此选项就会报具体的错误信息，你好因此排查错误（无论首次创建还是设备恢复都要重新设定此项）
			context3d.enableErrorChecking=true;
			// 设定后台缓冲区，一般就是要画画的区域大小了，还有抗锯齿为2的N次方（0表示不抗锯齿画的效率更高但画面更丑）（无论首次创建还是设备恢复都要重新设定此项）
			context3d.configureBackBuffer(stage.stageWidth, stage.stageHeight, 0, true);
			// 如果第一次创建的话而非设备恢复的情况
			if(isFirstCreate){
				// -- 标识下，说明不再是第一次创建3D环境了
				isFirstCreate = false;
				// -- 侦听：每帧渲染
				this.addEventListener(Event.ENTER_FRAME,onRender);
				// -- 侦听：键盘操控 
				stage.addEventListener(KeyboardEvent.KEY_DOWN,onKeyDown);
				// -- 侦听：鼠标操控
				stage.addEventListener(MouseEvent.MOUSE_DOWN,onMouseDown);
				// -- 初始化物体相关信息
				initModel();
				// -- 初始化shader：着色语言
				initShader();
				// -- 创建镜头V矩阵
				viewMatrix = new Matrix3D();
				// -- 镜头拉后一点，因为屏幕向里是+，所以这个镜头实际在屏幕外的地方
				viewMatrix.appendTranslation(0,0,-3);
				// -- 创建投影P矩阵
				projectionMatrix = new PerspectiveMatrix3D();
				// -- 设定为透视矩阵，越远越小越接近屏幕中心的那种，右手坐标系RightHand  
				//    -- 第一个参数表示透视角度  
				//    -- 第二个参数表示宽高比例  
				//    -- 第三个参数表示裁剪的最近距离，比这个个还近就无法显示  
				//    -- 第四个参数表示裁剪的最远距离，比这个还远的东西就无法显示  
				projectionMatrix.perspectiveFieldOfViewRH(45.0,stage.stageWidth/stage.stageHeight,0.01,5000.0);
				
			}
			// 设备恢复的情况
			else{
			   restore();
			}
			
			
			
		}
		/**
		 * 初始化物体相关信息
		 * 
		 */		
		private function initModel():void{
			// -- 最终矩阵
			finalMatrix = new Matrix3D();
			// -- 该物体的矩阵
			modelMatrix = new Matrix3D();
			// -- 该物体的顶点信息（坐标XYZ+对应的颜色RGB）这里4个顶点，我们要绘制一个正方形
			var vecVb:Vector.<Number> = Vector.<Number>([
			  // X  Y Z R G B
				-1, 1,0,1,0,0, // 0 左上角的点 + 红色
				 1, 1,0,0,1,0, // 1 右上角的点 + 绿色
				 1,-1,0,0,0,1, // 2 右下角的点 + 蓝色
				-1,-1,0,1,1,0  // 3 左下角的点 + 黄色
			]);
			// -- 创建该物体的顶点缓冲：有多少个顶点（当然是4个），以及一个顶点包含多少个信息（上面一行的信息=6）
			modelVb = context3d.createVertexBuffer(vecVb.length/6,6);
			// -- 通过vector来上传顶点数据：顶点信息、偏移（由于这里vec全部信息只用于一个物体，偏移就是0）、顶点数
			modelVb.uploadFromVector(vecVb,0,vecVb.length/6);
			// -- 该物体的索引数据：按照下面的顺序来画三角形的
			var vecIdx:Vector.<uint> = Vector.<uint>([
				0,1,2, // 左上角的点 - 右上角的点 - 右下角的点   这里是顺时针绘制的吧，表示一个三角形
				2,3,0 // 右下角的点 - 左下角的点 - 左上角的点  这里也是顺时针绘制的吧，表示第二个三角形
			]);
			
			// -- 创建该物体的顶点索引缓冲：
			modelIb = context3d.createIndexBuffer(vecIdx.length);
			// -- 通过vector来上传顶点索引数据：顶点索引数据、偏移（同上由于整个vecIdx都用于一个物体了这里全部都是该物体的信息）、索引个数
			modelIb.uploadFromVector(vecIdx,0,vecIdx.length);
		   
		}
		/**
		 * 初始化着色语言 
		 * 
		 */		
		private function initShader():void{
			// -- 创建一个着色语言
			program = context3d.createProgram();
			// -- 创建一个AGALMiniAssembler辅助类用于写顶点着色代码
			//    主要用于输出最终的顶点位置，以及传一些数据给片段着色代码使用
			var vShader:AGALMiniAssembler = new AGALMiniAssembler();
			vShader.assemble(Context3DProgramType.VERTEX,
				"m44 op va0 vc0 \n" + // 输出 = 4个顶点 * 最终矩阵 （这里的*就是m44方法，表示每个点都作用了该矩阵）
				"mov v1 va1\n" // 将4个点的颜色传到中转站以便片段着色代码使用
			);
			
			// -- 创建一个AGALMiniAssembler辅助类用于写片段着色代码
			var fShader:AGALMiniAssembler = new AGALMiniAssembler();
			fShader.assemble(Context3DProgramType.FRAGMENT,
				"mov oc v1" // 输出 = 颜色信息（当然这里是4个点的颜色信息了）
			);
			program.upload(vShader.agalcode,fShader.agalcode);
		}
		/**
		 * 设备恢复的情况 
		 * 
		 */		
		private function restore():void{
			initModel();
			initShader();
		}
		/**
		 * 侦听回调：逐帧渲染 
		 * @param e
		 * 
		 */		
		private function onRender(e:Event):void{
			// -- 如果设备丢失的话就暂时不绘制不然就报错了，不信你试试注释掉这个并且CTRL+ALT+DEL
			if(isContextDispose)return;
			// -- 最终矩阵先归零
			finalMatrix.identity();
			// -- 乘上M矩阵
			finalMatrix.append(modelMatrix);
			// -- 乘上V矩阵
			finalMatrix.append(viewMatrix.clone());
			// -- 乘上P矩阵
			finalMatrix.append(projectionMatrix);
			// -- 设置状态机当前的VB的坐标 到 va0 ，因为只有XYZ，所以偏移是0，长度是3
			context3d.setVertexBufferAt(0,modelVb,0,Context3DVertexBufferFormat.FLOAT_3);
			// -- 设置状态机当前的VB的颜色 到 va0 
			context3d.setVertexBufferAt(1,modelVb,3,Context3DVertexBufferFormat.FLOAT_3);
			// -- 设置状态机当前的vc0 静态常量：最终矩阵
			context3d.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX,0,finalMatrix,true);
			// -- 设置状态机使用的代码
			context3d.setProgram(program);
			// -- 清除画面（实际就是将画布全部像素刷成黑色）
			context3d.clear();
			// -- 绘制三角形
			context3d.drawTriangles(modelIb);
			// -- 发送给GPU
			context3d.present();
		}
		/**
		 * 侦听回调：键盘操作 WASD=镜头移动  上下左右=物体移动
		 * （由于镜头和世界是相反的）所以镜头是反着动的
		 * @param e
		 * 
		 */		
		private function onKeyDown(e:KeyboardEvent):void{
		   switch(e.keyCode){
		     case Keyboard.W: // 镜头往屏幕里面移动 z+=0.1
				 viewMatrix.appendTranslation(0,0,0.1);
				 break;
			 case Keyboard.S: // 镜头往屏幕外面移动 z-=0.1
				 viewMatrix.appendTranslation(0,0,-0.1);
				 break;
			 case Keyboard.A: // 镜头往屏幕左边移动 x+=0.1
				 viewMatrix.appendTranslation(0.1,0,0);
				 break;
			 case Keyboard.D: // 镜头往屏幕右边移动 x-=0.1
				 viewMatrix.appendTranslation(-0.1,0,0);
				 break;
			 case Keyboard.UP: // 物体往屏幕里面移动 z-=0.1
				 viewMatrix.appendTranslation(0,0,-0.1);
				 break;
			 case Keyboard.DOWN: // 物体往屏幕外面移动 z+=0.1
				 viewMatrix.appendTranslation(0,0,0.1);
				 break;
			 case Keyboard.LEFT: // 物体往屏幕左边移动 x-=0.1
				 viewMatrix.appendTranslation(-0.1,0,0);
				 break;
			 case Keyboard.RIGHT: // 物体往屏幕右边移动 x+=0.1
				 viewMatrix.appendTranslation(0.1,0,0);
				 break;
		   }
		}
		/**
		 * 鼠标移动旋转物体
		 * 原理无非就是根据每次移动时的像素差距来计算让物体矩阵M在当前的状态下再围绕X和Y旋转（至于围绕Z轴旋转可以自己添加试试）
		 * @param e
		 * 
		 */		
		private function onMouseDown(e:MouseEvent):void{
			onMouseDownPt.x = e.stageX;
			onMouseDownPt.y = e.stageY;
			stage.addEventListener(MouseEvent.MOUSE_MOVE,onMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP,onMouseUp);
		}
		private function onMouseMove(e:MouseEvent):void{
		    var dx:Number = e.stageX - onMouseDownPt.x;
			var dy:Number = e.stageY - onMouseDownPt.y;
			var degreesY:Number = dx/2;
			var degreesX:Number = dy/2;
			onMouseDownPt.x = e.stageX;
			onMouseDownPt.y = e.stageY;
			modelMatrix.appendRotation(degreesY,Vector3D.Y_AXIS);
			modelMatrix.appendRotation(degreesX,Vector3D.X_AXIS);
		}
		private function onMouseUp(e:MouseEvent):void{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE,onMouseMove);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE,onMouseUp);
		}
		/**
		 * 判断设备丢失 
		 * 
		 */		
		private function get isContextDispose():Boolean{
		   return context3d==null||context3d.driverInfo=="Disposed"||context3d.driverInfo=="";
		}
		
		
	}
}