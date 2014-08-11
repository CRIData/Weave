/*
	Weave (Web-based Analysis and Visualization Environment)
	Copyright (C) 2008-2011 University of Massachusetts Lowell
	
	This file is a part of Weave.
	
	Weave is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License, Version 3,
	as published by the Free Software Foundation.
	
	Weave is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with Weave. If not, see <http://www.gnu.org/licenses/>.
*/

package weave.ui
{
	import flash.display.Graphics;
	import flash.events.MouseEvent;
    import flash.utils.Timer;
    import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.ui.ContextMenu;
	
	import mx.core.UIComponent;
	import mx.core.mx_internal;

	import mx.collections.ArrayCollection;
	//import mx.formatters.DateFormatter;
	
	import weave.api.WeaveAPI;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableObject;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableDynamicObject;
	
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.core.LinkableHashMap;
	import weave.api.ui.ILinkableContainer;
	import weave.api.ui.IPlotter;
	import weave.api.registerLinkableChild;
	import weave.api.primitives.IBounds2D;
	
	import weave.utils.CustomCursorManager;
	import weave.primitives.Bounds2D;

	import weave.visualization.layers.Visualization;
	import weave.visualization.plotters.CirclePlotter;
	import weave.visualization.layers.PlotManager;
		
	use namespace mx_internal;
	
	/**
	 * This is a customized pen tool class for WEAVE based off of PenTool.as
	 * 
	 * @author maciaktj
	 */
	public class CRIPenTool extends UIComponent implements ILinkableObject, IDisposableObject
	{
		
		/*************************************************/
		/** static section                              **/
		/*************************************************/
		// private
		//private const _tempPoint:Point = new Point();
		private const _tempScreenBounds:IBounds2D = new Bounds2D();
		private const _tempDataBounds:IBounds2D = new Bounds2D();
		private const _maskObject:UIComponent = new UIComponent();
	
		//private var mouseDownTime:Date = null;
		//private var mouseClickTime:Date = null;
		private var mouseDownTimer:Timer = new Timer(1000);
		private var mouseDownTimerCount:int = 0
		
		// Global class static variable for cgPoints 
		private static const gs_CirclePlotterName:Array = new Array();

		// This one doesn't need to be global and should be renamed to cgPoints
		private var cgPoints:ArrayCollection = new ArrayCollection();

	
	// public
		// POLYGON_DRAW_MODE needs to be defined because we have this in the .js code:
		//					w().evaluateExpression(['MapTool', 'children', name], 'drawingMode.value = POLYGON_DRAW_MODE', null, ['weave.ui::CRIPenTool']);
		public static const POLYGON_DRAW_MODE:String = "Polygon Draw Mode";
		public static const FREE_DRAW_MODE:String = "Free Draw Mode";
		
		// TJM - 11/27/13 - For all instances of the tool we only have one variable for what mode it is currently in
		public static var toolMode:Boolean = false; // true when drawing a custom geography

		//public const bufferBitmap:Bitmap = new Bitmap(null, 'auto', true);
		//private var _drawing:Boolean = false; // true when editing and mouse is down
		//private var _coordsArrays:Array = []; // parsed from coords LinkableString

		/**
		 * The current mode of the drawing.
		 * @default POLYGON_DRAW_MODE 
		 */		
		public const drawingMode:LinkableString = registerLinkableChild(this, new LinkableString(POLYGON_DRAW_MODE, verifyDrawingMode));
		// TJM - 11/27/13 - adding cg points available to the JS dom ?!? I hope!
		//public const cgPoints2:LinkableHashMap = registerLinkableChild(this, new LinkableHashMap(cgPoints));

		public const plotters:LinkableHashMap = registerLinkableChild(this, new LinkableHashMap(IPlotter));
		
		//private const classNameXXX:String = "CRIPenTool";
		//private const debugPrefix:String = "DEBUG - TJM - " + getQualifiedClassName(this) + " - ";
		public static const debugPrefix:String = "DEBUG - TJM - " + "CRIPenTool.as" + " - ";

		public static var debugOn:Boolean = false; 				// turns trace messages on/off
		public static var debugOffMsgDisplayed:Boolean = false; // this should ALWAYS be set to false as it is used to display a single message
		public static function criDebug(s:String):void {
			if(debugOn) {
				trace(debugPrefix + s);				
			} else {
				if(!debugOffMsgDisplayed) {
					trace(debugPrefix + "Debug Messages turned off for this class");
					debugOffMsgDisplayed = true;
				} 
			}
		}	
		
		public function CRIPenTool()
		{
						
			criDebug("START CRIPenTool constructor");

			if(!toolMode) {
				toolMode = true;

				percentWidth = 100;
				percentHeight = 100;
				
				CustomCursorManager.showCursor(PEN_CURSOR);
				addEventListener(MouseEvent.MOUSE_DOWN, handleMouseDown);		
				addEventListener(MouseEvent.CLICK, handleMouseClick);
				addEventListener(MouseEvent.DOUBLE_CLICK, handleDoubleClick);
				
				mouseDownTimer.addEventListener(TimerEvent.TIMER, mouseDownTimerOn);

			} else {
				toolMode = false;				
				handleEraseDrawings();
				// show normal cursor
				CustomCursorManager.hack_removeAllCursors();
			}
			
			criDebug("toolMode: " + toolMode);

			
			criDebug("END CRIPenTool constructor");
		}

		/**
		 * This function occurs when Remove All Drawings is pressed.
		 * It removes the PenMouse object and clears all of the event listeners.
		 */
		private function handleEraseDrawings():void
		{
						
			criDebug("handleEraseDrawings");
			
			criDebug("Try #3  getChildNames");
			var objectPath:Array = ['MapTool', 'children' , 'visualization'];
			//var objectPath:Array = [ "MapTool", "children", "visualization", "plotManager","plotters", "circle" ];
			criDebug("objectPath: " + objectPath);
			var object:ILinkableObject = getObject(objectPath);
			criDebug("object: " + object);			
			if (object == null) {
				criDebug("object: null");							
				//	return null;					
			} else if (object is ILinkableHashMap) {
				criDebug("object is ILinkableHashMap");		
				
				//return (object as ILinkableHashMap).getNames();

			} else if (object is ILinkableDynamicObject) {
				criDebug("object is ILinkableDynamicObject");							
				//return [(object as ILinkableDynamicObject).globalName];
			//return (WeaveAPI.SessionManager as SessionManager).getLinkablePropertyNames(object);
			} else if (object is CirclePlotter) {
				criDebug("We have a CirclePlotter");

				var newPlotter1:CirclePlotter = object as CirclePlotter;
				criDebug("CirclePlotter X: " + newPlotter1.dataX.value);
				criDebug("CirclePlotter Y: " + newPlotter1.dataY.value);
								
			} else if (object is Visualization) {
				criDebug("We have a Visualization");
				var visualization:Visualization = object as Visualization;

				if (visualization) 
				{
								
					criDebug("We have a visualization to remove");				
					criDebug("getLinkableContainer(visualization): " + getLinkableContainer(visualization));

					var pm:PlotManager = visualization.plotManager;
					var tmpArray:Array = pm.plotters.getNames();
					for each (var propertyName:String in tmpArray)
					{
						criDebug("Get Names: " + propertyName);
						if(propertyName.indexOf("circle") >= 0) {
							criDebug("We have a circle plotter and we are going to try to remove it");
							pm.plotters.removeObject(propertyName);						
						} else {
							criDebug("Not a circle");
						}
					}
					
					var tmpArray2:Array = pm.plotters.getObjects();
					for each (var propertyName2:String in tmpArray2)
					{
						criDebug("1 Get Objects: " + propertyName2);
						if(propertyName2 is CirclePlotter) {
							criDebug("We have a circle plotter and we are going to try to remove it");
							pm.plotters.removeObject(propertyName2);						

						}							
					}
					/* TJM - 12/10/13 - this is not necessary, but should keep it as code reference
					for (var i:int = 0; i < gs_CirclePlotterName.length; i++) {
						var pm:PlotManager = visualization.plotManager;
						var newPlotter:CirclePlotter = pm.plotters.getObject(gs_CirclePlotterName[i]) as CirclePlotter;
						if(newPlotter != null) {
							criDebug("1 CirclePlotter X: " + newPlotter.dataX.value);
							criDebug("1 CirclePlotter Y: " + newPlotter.dataY.value);						
						} else {
							criDebug("1 newPlotter is null");
						}						
					}
					*/
				} else {
					criDebug("No visualization available");
				}
			}			 
		}
		
		// TJM - this function talen from ExternalSessionStateInterface.as
		/**
		 * This function returns a pointer to an object appearing in the session state.
		 * This function is not intended to be accessible through JavaScript.
		 * @param objectPath A sequence of child names used to refer to an object appearing in the session state.
		 * @return A pointer to the object referred to by objectPath.
		 */
		public function getObject(objectPath:Array):ILinkableObject
		{
			criDebug("call to getObject");
			var _rootObject:ILinkableObject = WeaveAPI.globalHashMap;
			var object:ILinkableObject = _rootObject;
			for each (var propertyName:String in objectPath)
			{
				if (object == null)
					return null;
				if (object is ILinkableHashMap)
				{
					object = (object as ILinkableHashMap).getObject(propertyName);
				}
				else if (object is ILinkableDynamicObject)
				{
					// ignore propertyName and always return the internalObject
					object = (object as ILinkableDynamicObject).internalObject;
				}
				else
				{
					//if ((WeaveAPI.SessionManager as SessionManager).getLinkablePropertyNames(object).indexOf(propertyName) < 0)
					//{
					//	return null;
					//}
					object = object[propertyName] as ILinkableObject;
				}
			}
			return object;
		}
		
		 /*
		 * TJM - 11/05/13 - renamed the original handleMouseDown event to handleMouseClick
		 */
		private function handleMouseClick(event:MouseEvent):void
		{
			
			if(toolMode) {
				if(mouseDownTimerCount < 3) {
					criDebug("Probably a Click");
					criDebug("handleMouseClick");
					// project the point to data coordinates
					handleScreenCoordinate(mouseX, mouseY);
					criDebug("drawingMode: " + drawingMode.value);
				} else {
					criDebug("Probably a Drag/PAN");
					// TODO - change into pan mode
				}
				
				mouseDownTimerCount = 0;
				mouseDownTimer.stop();
				
			
				//_circlePlotter.dataX(mouseX);
				//_circlePlotter.dataY(mouseY);
				//_circlePlotter.radius(20);				
			}
			
		}
		
		private function mouseDownTimerOn(event:TimerEvent):void {
			if(mouseDownTimerCount > 10) {
				mouseDownTimer.stop();
				criDebug( " Stopping the timer so its not in a loop");  				
			} else {
				mouseDownTimerCount += 1;
				criDebug( " mouseDownTimerCount: " + mouseDownTimerCount);  				
			}
		}
		
		private function handleDoubleClick(event:MouseEvent):void
		{
			if(toolMode){
				criDebug( "handleDoubleClick");				
			}
		}

		// TJM - 11/05/13 - first attempt at updating code for mouse down
		private function handleMouseDown(event:MouseEvent):void
		{
			if(toolMode) {
				criDebug( "suggested place to PAN");
				mouseDownTimer.reset();
				mouseDownTimer.start();				
			}

		}

		/**
		 * Handle a screen coordinate and project it into the data bounds of the parent visualization. 
		 * @param x The x value in screen coordinates.
		 * @param y The y value in screen coordinates.
		 */		
		private function handleScreenCoordinate(x:Number, y:Number):void
		{
			var tmpPoint:Point = new Point();
			criDebug("Parent: " + parent);
			var visualization:Visualization = getVisualization(parent);
			criDebug( "handleScreenCoordinate: " + visualization);
			if (visualization)
			{

				visualization.plotManager.zoomBounds.getScreenBounds(_tempScreenBounds);
				visualization.plotManager.zoomBounds.getDataBounds(_tempDataBounds);
				
				criDebug( "handleScreenCoordinate - x: " + x);
				criDebug( "handleScreenCoordinate - y: " + y);
				
				// TJM - give our temp point the values of X and Y
				tmpPoint.x = x;
				tmpPoint.y = y;
								
				_tempScreenBounds.projectPointTo(tmpPoint, _tempDataBounds);					
				criDebug( "handleScreenCoordinate - 2 tmpPoint.x: " + tmpPoint.x);
				criDebug( "handleScreenCoordinate - 2 tmpPoint.y: " + tmpPoint.y);
				criDebug( "handleScreenCoordinate - 2 tmpPoint: " + tmpPoint);
				
				criDebug( "adding point to the cgPoints array which currently has a size of: " + cgPoints.length);
				//cgPoints.addItem(tmpPoint);
				cgPoints.source.push(tmpPoint);
				cgPoints.refresh();
				criDebug( "cgPoints array now has a size of: " + cgPoints.length);
				
				if(cgPoints.length > 1) {
					
					
					for (var index:int = 0; index < cgPoints.length; index++) {
						criDebug("cgPoints[" + index + "] : " + cgPoints[index]);					
						criDebug("cgPoints[" + index + "].x : " + cgPoints[index].x);					
						criDebug("cgPoints[" + index + "].y : " + cgPoints[index].y);
					}
					
					var firstRoundedLng:Number = Math.round(cgPoints[0].x*10)/10;
					var firstRoundedLat:Number = Math.round(cgPoints[0].y*10)/10;
					criDebug("first Lat: " + firstRoundedLat);
					criDebug("first Lng: " + firstRoundedLng);

					var lastRoundedLng:Number = Math.round(cgPoints[cgPoints.length-1].x*10)/10;
					var lastRoundedLat:Number = Math.round(cgPoints[cgPoints.length-1].y*10)/10;
					criDebug("last Lat: " + lastRoundedLat);
					criDebug("last Lng: " + lastRoundedLng);
					
					if((firstRoundedLng == lastRoundedLng)) {
						criDebug("Longitudes Match!");
					}

					if((firstRoundedLat == lastRoundedLat)) {
						criDebug("Latitudes Match!");
					}

					// TODO - see if the first one and the last one match
					// TODO - may have to do some narrowing down to tenth of a fraction for lat/lng

				}


/* TJM - 11/22/13 - this method did not work
				criDebug("DEBUG - TJM - getting ready to call CirclePlotter");
				var _circlePlotter:CirclePlotter = new CirclePlotter();
				_circlePlotter.dataX.value = output.x;
				_circlePlotter.dataY.value = output.y;
				_circlePlotter.radius.value = 100;
				
				criDebug("DEBUG - TJM - handleScreenCoordinate - _tempDataBounds: " + _tempDataBounds);
				criDebug("DEBUG - TJM - handleScreenCoordinate - _tempScreenBounds: " + _tempScreenBounds);
				
				var sampleBmp:BitmapData = new BitmapData(100, 100, true);
				
				criDebug("DEBUG - TJM - handleScreenCoordinate - sampleBmp: " + sampleBmp);				
				_circlePlotter.drawBackground(_tempDataBounds,_tempScreenBounds,sampleBmp);

 TJM - 11/22/13 - however the method below DOES work :)
*/
				
				criDebug( "[START] second attempt to add a circle");	
				var pm:PlotManager = visualization.plotManager;
				var name:String = pm.plotters.generateUniqueName("circle");
				criDebug("New Plotter Name: " + name);
				var newPlotter:CirclePlotter = pm.plotters.requestObject(name, CirclePlotter, false);
				gs_CirclePlotterName.push(name);
				
				var anchorPoint:Point = new Point();
				var localAnchorPoint:Point = visualization.globalToLocal(anchorPoint);
				pm.zoomBounds.projectScreenToData(localAnchorPoint);
				
				newPlotter.dataX.value = tmpPoint.x;
				newPlotter.dataY.value = tmpPoint.y;
				newPlotter.radius.value = 80;
				newPlotter.lineColor.value = 3368652;
				criDebug( "[END] of second attempt to add a circle");	
			}
		}
		
		/**
		 * @param target The UIComponent for which to get its PlotLayerContainer.
		 * @return The PlotLayerContainer visualization for the target if it has one. 
		 */		
		private static function getVisualization(mouseTarget:Object):Visualization
		{
			var linkableContainer:ILinkableContainer = getLinkableContainer(mouseTarget);
			if (!linkableContainer)
				return null;
			
			return linkableContainer.getLinkableChildren().getObjects(Visualization)[0] as Visualization;
		}
		
		/**
		 * This function is passed a target and checks to see if the target is an ILinkableContainer.
		 * Either a ILinkableContainer or null will be returned.
		 */
		private static function getLinkableContainer(target:*):*
		{
			var targetComponent:* = target;
			
			while (targetComponent)
			{
				if (targetComponent is ILinkableContainer)
					return targetComponent as ILinkableContainer;
				
				targetComponent = targetComponent.parent;
			}
			
			return targetComponent;
		}

		// TJM - 11/12/13 - added this method to get rid of compile error -> /Users/maciaktj/git/Weave/WeaveUISpark/src/weave/ui/CRIPenTool.as(62): col: 15 Error: Interface method dispose in namespace weave.api.core:IDisposableObject not implemented by class weave.ui:CRIPenTool.
		public function dispose():void
		{
			//editMode = false; // public setter cleans up event listeners and cursor
		}
		
		/**
		 * Verification function for the drawing mode property.
		 */		
		private function verifyDrawingMode(value:String):Boolean
		{
			return value == FREE_DRAW_MODE || value == POLYGON_DRAW_MODE;
		}

		// TJM - 11/13/13 - seems like the function updateDisplayList is required for tool to work
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var visualization:Visualization = getVisualization(parent); 
			if (visualization) 
			{
				var lastShape:Array;
				var g:Graphics = graphics;
				g.clear();

				//if (_editMode)
				//{
					// draw invisible rectangle to capture mouse events
					g.lineStyle(0, 0, 0);
					g.beginFill(0, 0);
					g.drawRect(0, 0, unscaledWidth, unscaledHeight);
					g.endFill();
				//}
				
				//if (drawingMode.value == POLYGON_DRAW_MODE && polygonFillAlpha.value > 0)
				//	g.beginFill(polygonFillColor.value, polygonFillAlpha.value);					

				//g.lineStyle(lineWidth.value, lineColor.value, lineAlpha.value);
				/*
				for (var line:int = 0; line < _coordsArrays.length; line++)
				{
					var points:Array = _coordsArrays[line];
					for (var i:int = 0; i < points.length - 1 ; i += 2 )
					{
					//	projectCoordToScreenBounds(points[i], points[i+1], _tempPoint);
						
						if (i == 0)
							g.moveTo(_tempPoint.x, _tempPoint.y);
						else
							g.lineTo(_tempPoint.x, _tempPoint.y);
					}
				
					// If we are not drawing (or this is not the last shape), always connect back to first point in the shape.
					// The effect of this is either completing the polygon by drawing a line or
					// drawing to the current position of the graphics object. This is only used to
					// draw complete polygons without affecting the polygon's internal representation.					
					if (points.length >= 2 &&			// at least 2 points 
						(!_drawing || line < (_coordsArrays.length - 1)) && 	// not drawing or not on the last line
						drawingMode.value == POLYGON_DRAW_MODE)	// and drawing polygons
					{
						//projectCoordToScreenBounds(points[0], points[1], _tempPoint);
						
						g.lineTo(_tempPoint.x, _tempPoint.y);
					}
				}
				*/
				// If we are drawing, show what the last polygon would look like if we add the current mouse position
				// If the user drew two of three points for a triangle, this would show what the completed triangle
				// would look like if the final point was placed under the cursor. Note that if the PenTool is disabled,
				// the final point is not put into coords.
/*
				if (_drawing && drawingMode.value == POLYGON_DRAW_MODE)
				{
					g.lineTo(mouseX, mouseY);
					
					lastShape = _coordsArrays[_coordsArrays.length - 1];
					if (lastShape && lastShape.length >= 2)
					{
						//projectCoordToScreenBounds(lastShape[0], lastShape[1], _tempPoint);
						
						g.lineStyle(lineWidth.value, lineColor.value, 0.35);
						g.lineTo(_tempPoint.x, _tempPoint.y);
					}
				}
*/				
				//if (drawingMode.value == POLYGON_DRAW_MODE && polygonFillAlpha.value > 0)
				//	g.endFill();
			} // if (visualization)
		}
		
		/**
		 * Embedded cursors
		 */
		public static const PEN_CURSOR:String = "penCursor";
		[Embed(source="/weave/resources/images/penpointer.png")]
		private static var penCursor:Class;
		CustomCursorManager.registerEmbeddedCursor(PEN_CURSOR, penCursor, 3, 22);
		
		// ----> START ADDING REST OF PenTOOL.as code just to try to figure out why its not working correctly

	}
}
