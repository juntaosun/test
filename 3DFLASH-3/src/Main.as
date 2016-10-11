package
{
	import com.adobe.utils.AGALMiniAssembler;
	import com.adobe.utils.PerspectiveMatrix3D;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DRenderMode;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.ui.Keyboard;
	
	[SWF(width="800", height="600", frameRate="60", backgroundColor="#000000")]
	/**
	 * 锥形并且贴图纹理追加简单光照
	 * @author Xin Yan Kong 2016.4
	 * 
	 */
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
		/**
		 * 嵌入图片资源到SWF里 
		 */		
		[Embed(source = "wall.jpg")]  
		private var wallClass:Class;
		private var wallBmp:Bitmap = new wallClass() as Bitmap;
		/**
		 * flash要用到的纹理信息 
		 */		
		private var tex:Texture;
		/**
		 * 光照所在的点
		 */		
		private var lightPos:Vector3D = new Vector3D(0,0,-10,0);
		/**
		 * 光照强度 
		 */		
		private var lightStr:Number = 1;
		private var lightStrAdd:Number = -0.01;
		
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
			context3d.configureBackBuffer(stage.stageWidth, stage.stageHeight, 16, true);
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
			// -- 该物体的顶点信息（坐标XYZ+对应的颜色RGB）这里5个顶点，我们要绘制一个锥形
			var vecVb:Vector.<Number> = Vector.<Number>([
				// X  Y Z R G B U V nX nY nZ
				-1, 1,0,1,0,0,0,0,0,0,0, // 0 左上角的点 + 红色 + UV坐标纹理的左上角点 + 法线（后面计算下）
				1, 1,0,0,1,0,1,0,0,0,0, // 1 右上角的点 + 绿色 + UV坐标纹理的右上角点 + 法线（后面计算下）
				1,-1,0,0,0,1,1,1,0,0,0, // 2 右下角的点 + 蓝色 + UV坐标纹理的右下角点 + 法线（后面计算下）
				-1,-1,0,1,1,0,0,1,0,0,0,  // 3 左下角的点 + 黄色 + UV坐标纹理的左下角点 + 法线（后面计算下）
				0,0,-1,0,1,1,0.5,0.5,0,0,0 // 4 里面中心的点 + 青色 + UV坐标纹理的中间的点 + 法线（后面计算下）
			]);
			calcNormal(vecVb,5);
			// -- 创建该物体的顶点缓冲：有多少个顶点（当然是4个），以及一个顶点包含多少个信息（上面一行的信息=11）
			modelVb = context3d.createVertexBuffer(vecVb.length/11,11);
			// -- 通过vector来上传顶点数据：顶点信息、偏移（由于这里vec全部信息只用于一个物体，偏移就是0）、顶点数
			modelVb.uploadFromVector(vecVb,0,vecVb.length/11);
			// -- 该物体的索引数据：按照下面的顺序来画三角形的
			var vecIdx:Vector.<uint> = Vector.<uint>([
				0,1,2, // 左上角的点 - 右上角的点 - 右下角的点   这里是顺时针绘制的吧，表示一个三角形
				2,3,0, // 右下角的点 - 左下角的点 - 左上角的点  这里也是顺时针绘制的吧，表示第二个三角形
				0,1,4, // 锥形面1
				0,4,3, // 锥形面2
				3,4,2, // 锥形面3
				1,2,4  // 锥形面4
			]);
			// -- 创建该物体的顶点索引缓冲：
			modelIb = context3d.createIndexBuffer(vecIdx.length);
			// -- 通过vector来上传顶点索引数据：顶点索引数据、偏移（同上由于整个vecIdx都用于一个物体了这里全部都是该物体的信息）、索引个数
			modelIb.uploadFromVector(vecIdx,0,vecIdx.length);
			// -- 创建纹理，由于使用BitmapData方式转为texture所以模式是RGBA，如果是ATF格式的话则是COMPRESSED，纹理必须是2的n次方宽高，如果不是可以转化一下
			tex = context3d.createTexture(wallBmp.width,wallBmp.height,Context3DTextureFormat.BGRA,false);
			// -- 上传纹理
			tex.uploadFromBitmapData(wallBmp.bitmapData);
			
		}
		/**
		 * 计算法线 原理就是计算顶点所关联的所有三角形面的法线，然后取得它们平均值就是顶点的法线了（当然还有其他方式求得法线，比如权重）
		 * @param vecVb 顶点信息
		 * @param vertexNum 顶点数
		 * @param offsetNormal 法线的偏移值
		 * @param offsetVertex 顶点的偏移值
		 */		
		private function calcNormal(vecVb:Vector.<Number>,vertexNum:int):void{
			var data32PerVertex:int = vecVb.length/vertexNum;
			var vertexArr:Array = [];
			for (var i:int=0;i<vertexNum;i++){
			    var x:Number = vecVb[data32PerVertex*i];
				var y:Number = vecVb[data32PerVertex*i+1];
				var z:Number = vecVb[data32PerVertex*i+2];
				vertexArr.push(new Vector3D(x,y,z));
			}
			var calcNormal:Function = function(p1:Vector3D,p2:Vector3D,p3:Vector3D):Vector3D{
				var source2:Vector3D = new Vector3D(p2.x-p1.x,p2.y-p1.y,p2.z-p1.z);
				var source1:Vector3D = new Vector3D(p3.x-p1.x,p3.y-p1.y,p3.z-p1.z);
				var norV:Vector3D = new Vector3D();
				norV.x = source1.y * source2.z - source1.z * source2.y;
				norV.y = source1.z * source2.x - source1.x * source2.z;
				norV.z = source1.x * source2.y - source1.y * source2.x;
				norV.normalize();
				return norV;
			}
			// 计算平均法线：就是将N个三角面的法线平均一下，这里由于锥顶在背面，我们就将结果法线反向一下，让背面受光，而正面不受光,如果要双面受光的话后面再说
			var calcNormalAvg:Function = function(arr:Array,offsetNormal:int):void{
			    var sideLen:int = arr.length/3;
				var sideAvg:Vector3D = new Vector3D();
				for (var i:int=0;i<sideLen;i++){
					var side:Vector3D = calcNormal(vertexArr[arr[i*3]],vertexArr[arr[i*3+1]],vertexArr[arr[i*3+2]]);
					sideAvg=sideAvg.add(side);
				}
				sideAvg.x = sideAvg.x/sideLen;
				sideAvg.y = sideAvg.y/sideLen;
				sideAvg.z = sideAvg.z/sideLen;
				sideAvg.normalize();
				vecVb[offsetNormal] = -sideAvg.x;
				vecVb[offsetNormal+1] = -sideAvg.y;
				vecVb[offsetNormal+2] = -sideAvg.z;
			}
			// 4-顶点的平均法线
			calcNormalAvg([
				4,0,1,
				4,3,0,
				4,2,3,
				4,1,2
			],vertexNum*data32PerVertex-3);
			
			// 3-顶点的平均法线
			calcNormalAvg([
				3,0,2,   // 裁掉不受光的那个面，否则影响受光面的光照
				3,0,4,
				3,4,2
			],(vertexNum-1)*data32PerVertex-3);
			
			// 2-顶点的平均法线
			calcNormalAvg([
				2,3,4,
				2,3,1, // 裁掉不受光的那个面，否则影响受光面的光照
				2,4,1
			],(vertexNum-2)*data32PerVertex-3);
			
			// 1-顶点的平均法线
			calcNormalAvg([
				1,2,4,
				1,2,3,   // 裁掉不受光的那个面，否则影响受光面的光照
				1,4,0
			],(vertexNum-3)*data32PerVertex-3);
			
			// 0-顶点的平均法线
			calcNormalAvg([
				0,1,4,
				0,1,2,   // 裁掉不受光的那个面，否则影响受光面的光照
				0,4,3
			],(vertexNum-4)*data32PerVertex-3);
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
				"mov v1 va1\n" + // 将4个点的颜色传到中转站以便片段着色代码使用
				"mov v2 va2\n" +   // 将4个点的使用纹理的坐标点传到中转站以便片段着色代码使用
				"mov v3 va3" // 将4个点坐标点传到中转站以便片段着色代码使用
			);
			
			// -- 创建一个AGALMiniAssembler辅助类用于写片段着色代码
			var fShader:AGALMiniAssembler = new AGALMiniAssembler();
			fShader.assemble(Context3DProgramType.FRAGMENT,
				//------------------------------------------------------------------------------------------------------
				// 通用变量：
				//   -- 纹理颜色
				//   -- 世界光照点 globalLight
				//   -- 世界法线   globalNormal
				//------------------------------------------------------------------------------------------------------
				"tex ft0, v2, fs0 <2d,linear,repeat,nomip>\n"+ //临时变量 ft0 = v2（UV坐标点）和图片纹理作用的颜色点  关于linear repeat nomip后面再说
				"mov ft1 fc0\n" + // 世界光照点 ft1 = 光照点
				"mov ft2 v3\n" + // 本地法线 ft2 = 法线
				"m44 ft2 ft2 fc3\n" + // 世界法线 ft2 = 法线 m44 模型变换矩阵
				
				//------------------------------------------------------------------------------------------------------
				// 环境反射 fc1
				//------------------------------------------------------------------------------------------------------
				
				//------------------------------------------------------------------------------------------------------
				// 漫反射：
				//   -- 计算光线与法线的角度（点乘）
				//   -- 修正背面负数的情况反转，因为背面的话是负数，角度是负数的话就转为正数（取绝对值或多步骤实现反转）
				//   -- 计算光照加成的颜色 = 像素颜色*角度
				//------------------------------------------------------------------------------------------------------
				// -- 漫反射：计算角度
				"dp3 ft3.w ft1 ft2\n" + // 点乘，计算角度
				// -- 漫反射：修正背面负数的情况反转（取绝对值）
				"abs ft3.w ft3.w\n" + // 注释这一行并开启下面5行等同此效果，这只为多熟悉AGAL用法
//				"slt ft5.x ft3.w fc0.w\n" + // ft5.x = ft3.w<fc0.w?1:0    fc0.w=0 是否小于0 是的话就是1
//				"mul ft5.y ft5.x fc4.w\n" + // ft5.y = ft5.x*fc4.w   fc4.w=-1 不小于的情况 0*-1=0 小于的情况 -1*1=-1 
//				"mul ft5.y ft5.y ft3.w\n" + // ft5.y = 角度*0/-1
//				"max ft5.z ft3.w fc0.w\n" + // ft5.z = 角度>0?角度:0 取得ft3.w 和 fc0.w（0）的最大值
//				"add ft3.w ft5.z ft5.y\n" +// 角度 = 角度 + 角度*0/-1
				// -- 漫反射：计算光照加成的颜色和根据强度系数调整
				"mul ft4 ft0 ft3.wwww\n" + // 光照加成颜色 ft4 = 原始颜色*光照
				"mul ft4 ft4 fc1.wwww\n" + // 根据强度系数调整
				
				//------------------------------------------------------------------------------------------------------
				// 镜面反射（高光）：
				//   -- 计算入射角与光线一半的角度·世界法线
				//   
				//------------------------------------------------------------------------------------------------------
//				// -- 镜面反射：计算角度  ft2 = 入射角的一半·模型法线
				"dp3 ft6.w fc2 ft2\n" + 
				// -- 镜面反射：修正背面负数的情况反转和计算高光颜色
				"abs ft6.w ft6.w\n" + 
				"mul ft7 fc4 ft6.wwww\n" + 
				
				//------------------------------------------------------------------------------------------------------
				// 计算最终输出的颜色
				//  -- 原始颜色
				//  -- += 漫反射
				//  -- += 高光
				//  -- += 环境光
				//  -- 输出
				//------------------------------------------------------------------------------------------------------
				// -- 镜面反射：高光加成颜色
				"add ft0 ft0 ft4\n" + // 原始颜色 += 漫反射光照加成颜色
				"add ft0 ft0 ft7\n" + // 原始颜色 += 高光加成颜色
				"add ft0 ft0 fc1\n" + // 颜色叠加
				"mov oc, ft0\n" // 直接输出颜色点 ft0  从这里看的出来shader就是用来处理点的颜色信息的，比如颜色混合、光照等等
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
			// -- 设置状态机当前的VB的颜色 到 va1
			context3d.setVertexBufferAt(1,modelVb,3,Context3DVertexBufferFormat.FLOAT_3);
			// -- 设置状态机当前的VB的UV纹理坐标 到 va2
			context3d.setVertexBufferAt(2,modelVb,6,Context3DVertexBufferFormat.FLOAT_2);
			// -- 设置状态机当前的VB的UV纹理坐标 到 va3
			context3d.setVertexBufferAt(3,modelVb,8,Context3DVertexBufferFormat.FLOAT_3);
			// -- 设置状态机当前的vc0 静态常量：最终矩阵
			context3d.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX,0,finalMatrix,true);
			// -- 设置状态机当前的fc0 静态常量：用于光照计算（这里的光照要进行模型的矩阵变换，因为它直接与法线作用，法线是固定的如果这里不变换的话模型即使变动了受光也是一样的）
			var light:Vector3D=lightPos.clone(); // 不含平移元素的变换
			light.normalize(); // 单位化
			
			context3d.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,0,Vector.<Number>([light.x,light.y,light.z,0]));
			// -- 设置状态机当前的fc1 静态常量：xyz用于 环境光颜色叠加 W用于漫反射光照强度   这里叠加一个红色环境光
			var ambientR:Number = lightStr*0.2;
			var ambientG:Number = (1-lightStr)*0.2;
			var ambientB:Number = (lightStr/2)*0.2;
			context3d.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,1,Vector.<Number>([ambientR,ambientG,ambientB,lightStr]));//lightStr
			// -- 设置状态机当前的fc2 静态常量：用于 高光点 这个点是视点和光线点夹角的一半
			var halfEyeLightPos:Vector3D = viewMatrix.position.clone();
			halfEyeLightPos=halfEyeLightPos.add(lightPos);
//			halfEyeLightPos.scaleBy(0.5); 和下面的xyz/2是一个意思
			halfEyeLightPos.x/=2;
			halfEyeLightPos.y/=2;
			halfEyeLightPos.z/=2;
			halfEyeLightPos.normalize();
			context3d.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,2,Vector.<Number>([halfEyeLightPos.x,halfEyeLightPos.y,halfEyeLightPos.z,0]));
			// -- 设置状态机当前的fc3 静态常量：用于将模型矩阵变换传入
			context3d.setProgramConstantsFromMatrix(Context3DProgramType.FRAGMENT,3,modelMatrix);
			// -- 设置状态机当前的fc4 静态常量：高光颜色
			var specularStr:Number = lightStr*0.3;
			context3d.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,4,Vector.<Number>([1.0*specularStr,1.0*specularStr,1.0*specularStr,0]));
			
			
			// -- 设置状态机使用的纹理到当前的fs0
			context3d.setTextureAt(0,tex);
			// -- 设置状态机使用的代码
			context3d.setProgram(program);
			// -- 清除画面（实际就是将画布全部像素刷成黑色）
			context3d.clear();
			// -- 绘制三角形
			context3d.drawTriangles(modelIb);
			// -- 发送给GPU
			context3d.present();
			// -- 颜色系数改变
			lightStr+=lightStrAdd;
			if(lightStr>1){
				lightStr=1;
				lightStrAdd=-lightStrAdd;
			}
			else if(lightStr<0){
				lightStr=0;
				lightStrAdd=-lightStrAdd;
			}
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