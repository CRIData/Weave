/*
    Weave (Web-based Analysis and Visualization Environment)
    Copyright (C) 2008-2011 University of Massachusetts Lowell

    This file is a part of Weave.

    Weave is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License, Version 3,
    as published by the Free Software Foundation.

    Weave is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/

package weave.utils
{
	import flash.display.Stage;
	import flash.utils.getQualifiedClassName;
	
	import mx.core.IToolTip;
	import mx.core.UIComponent;
	import mx.managers.ToolTipManager;
	
	import weave.Weave;
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;
	import weave.compiler.StandardLib;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableFunction;
	import weave.core.LinkableHashMap;
	import weave.primitives.Bounds2D;
	
	import weave.visualization.layers.InteractiveVisualization;
	//import weave.visualization.layers.Visualization;

	/**
	 * A static class containing functions to manage a list of probed attribute columns
	 * 
	 * @author adufilie
	 */
	public class ProbeTextUtils
	{
		public static const enableProbeToolTip:LinkableBoolean = new LinkableBoolean(true);
		public static const showEmptyProbeRecordIdentifiers:LinkableBoolean = new LinkableBoolean(true);
		
		public static function get probedColumns():ILinkableHashMap
		{
			// this initializes the probed columns object map if not created yet, otherwise just returns the existing one
			return Weave.root.requestObject("Probed Columns", LinkableHashMap, true);
		}
		
		public static function get probeHeaderColumns():ILinkableHashMap
		{
			return Weave.root.requestObject("Probe Header Columns", LinkableHashMap, true);
		}
		
		public static const DEFAULT_LINE_FORMAT:String = 'str = replace(lpad(string, 8, "\\t"), "\\t", "  ");\nstr + " (" + title + ")"';
		
		/**
		 * This function is used to format each line corresponding to a column in probedColumns.
		 */
		public static const probeLineFormatter:LinkableFunction = new LinkableFunction(DEFAULT_LINE_FORMAT, true, false, ['column', 'key', 'string', 'title']);
		
		public static function criGetProbeKeyByName(keyName:String):IQualifiedKey {
			criDebug("[START] getProbeKeyByName function");
			var key:IQualifiedKey;
			var keys:Array = null;
			
			criDebug("searching for: " + keyName);
			//var iv:InteractiveVisualization= new InteractiveVisualization();
			////var iv:Visualization = getVisualization(parent);
			//key = iv.criGetKey(keyName);

			
			
			//getProbeText();
			
			
			criDebug("key: " + key);

			criDebug("[END] getProbeKeyByName function");
			return key;
		}
		
		public static function criGetAllProbeKeys(criAllProbedKeys:Array):Array {
			criDebug("[START] criGetAllProbeKeys");
			criDebug("[END] criGetAllProbeKeys");						
			return criAllProbedKeys;
		}
		
		/**
		 * getProbeText
		 * @param keySet The key set you are interested in.
		 * @param additionalColumns An array of additional columns (other than global probed columns) to be displayed in the probe tooltip
		 * @param maxRecordsShown Maximum no. of records shown in one probe tooltip
		 * @return A string to be displayed on a tooltip while probing 
		 */
		public static function getProbeText(keys:Array, additionalColumns:Array = null):String
		{						
			var result:String = '';
			var headers:Array = probeHeaderColumns.getObjects(IAttributeColumn);
			// include headers in list of columns so that those appearing in the headers won't be duplicated.
			var columns:Array = headers.concat(probedColumns.getObjects(IAttributeColumn));
			if (additionalColumns != null)
				columns = columns.concat(additionalColumns);
			var keys:Array = keys.concat();
			AsyncSort.sortImmediately(keys);
			var key:IQualifiedKey;
			var recordCount:int = 0;
			var maxRecordsShown:Number = Weave.properties.maxTooltipRecordsShown.value;

			// TJM - 04/02/14 - trying to get this to return the keys instead of the result so I know what the keys look like that are being passed
			//var myKeys:String = 'BLANK';
			//for (var z:int = 0; z < keys.length; z++) {
			//	myKeys += ',';
			//	myKeys += keys[z] as IQualifiedKey;
			//}
			
			//criDebug("myKeys: " + myKeys);
			//criDebug("keys: " + keys);
			//criDebug("keysLength: " + keys.length);
			//criDebug("columns: " + columns);

			for (var iKey:int = 0; iKey < keys.length && iKey < maxRecordsShown; iKey++)
			{

				key = keys[iKey] as IQualifiedKey;
				if(key != null) {
					criDebug("[START] getProbeText");

					criDebug("key[" +iKey +"]: " + key);
					criDebug("key.localName: " + key.localName);
					criDebug("key.keyType: " + key.keyType);

					var record:String = '';
					for (var iHeader:int = 0; iHeader < headers.length; iHeader++)
					{
						var header:IAttributeColumn = headers[iHeader] as IAttributeColumn;
						var headerValue:String = StandardLib.asString(header.getValueFromKey(key, String));
						if (headerValue == '')
							continue;
						if (record)
							record += ', ';
						record += headerValue;
					}
					criDebug("record: " + record);
					if (record)
						record += '\n';
					var lookup:Object = new Object() ;
					for (var iColumn:int = 0; iColumn < columns.length; iColumn++)
					{
						//criDebug("lookup: " + lookup);
						
						var column:IAttributeColumn = columns[iColumn] as IAttributeColumn;
						var value:String = String(column.getValueFromKey(key, String));
						if (!value || value == 'NaN')
							continue;
						var title:String = ColumnUtils.getTitle(column);
						try
						{
							//criDebug("try start");
							var line:String = probeLineFormatter.apply(null, [column, key, value, title]) + '\n';
							// prevent duplicate lines from being added
							if (lookup[line] == undefined)
							{
								if (!(value.toLowerCase() == 'undefined' || title.toLowerCase() == 'undefined'))
								{
									lookup[line] = true; // this prevents the line from being duplicated
									// the headers are only included so that the information will not be duplicated
									if (iColumn >= headers.length)
										record += line;
								}
							}
							
							//criDebug("try end");

						}
						catch (e:Error)
						{
							criDebug("Error");
							//reportError(e);
						}
					}
					if (record)
					{
						result += record + '\n';
						recordCount++;
					}
				} else {
					//criDebug("key is null");
				}

			}
			// remove ending '\n'
			while (result.substr(result.length - 1) == '\n')
				result = result.substr(0, result.length - 1);

			criDebug("BEFORE IF --> result: " + result);
			criDebug("BEFORE IF --> showEmptyProbeRecordIdentifiers.value: " + showEmptyProbeRecordIdentifiers.value);

			if (!result && showEmptyProbeRecordIdentifiers.value)
			{
				
				//result = 'Record Identifier' + (keys.length > 1 ? 's' : '') + ':\n';
				for (var i:int = 0; i < keys.length && i < maxRecordsShown; i++)
				{

					key = keys[i] as IQualifiedKey;
					//trace("key: " + key);
					//trace("key.keyType: " + key.keyType);
					//trace("key.localName: " + key.localName);

					// TJM - 04/04/14 - was getting this weird error in weave console box so now I added check to only add to result if key was not null, otherwise return N/A
					/*
					 * getProbeText([this.visualization.lastProbedKey])
							Error #1009: Cannot access a property or method of a null object reference.
							Stack trace: ProbeTextUtils$/getProbeText():214; apply(); Function/<anonymous>(); apply(); Function/<anonymous>(); apply(); ExternalSessionStateInterface/evaluateExpression(); apply(); Function/<anonymous>(); apply(); ExternalInterface$/_callIn(); Function/<anonymous>()
					 */
					if(key != null) {
						//result += '    ' + key.keyType + '#' + key.localName + '\n';
						result += '**ENTRY NOT IN WEAVE PROBE INFO EDITOR via ADMIN CONSOLE** for layer: ' + key.keyType + ' key ID:' + key.localName + '\n';
					} else {
						result = 'N/A';
					}
					recordCount++;						

				}
			}
			
			if (result && recordCount >= maxRecordsShown && keys.length > maxRecordsShown)
			{
				result += '\n... (' + keys.length + ' records total, ' + recordCount + ' shown)';
			}
			
			criDebug("result: " + result);
			criDebug("[END] getProbeText function");

			return result;
		}
		
		private static function setProbeToolTipAppearance():void
		{
			(probeToolTip as UIComponent).setStyle("backgroundAlpha", Weave.properties.probeToolTipBackgroundAlpha.value);
			if (isFinite(Weave.properties.probeToolTipBackgroundColor.value))
				(probeToolTip as UIComponent).setStyle("backgroundColor", Weave.properties.probeToolTipBackgroundColor.value);
			Weave.properties.defaultTextFormat.copyToStyle(probeToolTip as UIComponent);
		}

		public static var yAxisToolTip:IToolTip;
		public static var xAxisToolTip:IToolTip;
		//For now the toolTipLocation.value parameter will be utilised by the ColorBinLegendTool. In the future this feature can be generalised for every tool.
		public static function showProbeToolTip(probeText:String, stageX:Number, stageY:Number, stageBounds:IBounds2D = null, margin:int = 5):void
		{
			hideProbeToolTip();
		
			if (!enableProbeToolTip.value)
				return;
			
			if (!probeText || WeaveAPI.globalHashMap.getObject("ProbeToolTipWindow"))
				return;
			
			if (!probeToolTip)
				probeToolTip = ToolTipManager.createToolTip('', 0, 0);
		
			var stage:Stage = WeaveAPI.topLevelApplication.stage;
			tempBounds.setBounds(stage.x, stage.y, stage.stageWidth, stage.stageHeight);
		
			if (stageBounds == null)
				stageBounds = tempBounds;
		
			// create new tooltip
			probeToolTip.text = probeText;
			probeToolTip.visible = true;
		
			// make tooltip completely opaque because text + graphics on same sprite is slow
			setProbeToolTipAppearance();
		
			//this step is required to set the height and width of probeToolTip to the right size.
			(probeToolTip as UIComponent).validateNow();
		
			var xMin:Number = stageBounds.getXNumericMin();
			var yMin:Number = stageBounds.getYNumericMin();
			var xMax:Number = stageBounds.getXNumericMax() - probeToolTip.width;
			var yMax:Number = stageBounds.getYNumericMax() - probeToolTip.height;
		
			// calculate y coordinate
			var y:int;
			// calculate y pos depending on toolTipAbove setting
			if (toolTipAbove)
			{
				y = stageY - (probeToolTip.height + 2 * margin);
				if (yAxisToolTip != null)
					y = yAxisToolTip.y - margin - probeToolTip.height ;
			}
			else // below
			{
				y = stageY + margin * 2;
				if (yAxisToolTip != null)
					y = yAxisToolTip.y + yAxisToolTip.height+margin;
			}
		
			// flip y position if out of bounds
			if ((y < yMin && toolTipAbove) || (y > yMax && !toolTipAbove))
				toolTipAbove = !toolTipAbove;
			
			// calculate x coordinate
			var x:int;
			if (cornerToolTip)
			{
				// check twice to prevent flipping back and forth when weave desktop size is very small
				for (var checkTwice:int = 0; checkTwice < 2; checkTwice++)
				{
					// want toolTip corner to be near probe point
					if (toolTipToTheLeft)
					{
						x = stageX - margin - probeToolTip.width;
						if(xAxisToolTip != null)
							x = xAxisToolTip.x - margin - probeToolTip.width; 
					}
					else // to the right
					{
						x = stageX + margin;
						if(xAxisToolTip != null)
							x = xAxisToolTip.x+xAxisToolTip.width+margin;
					}
				
					// flip x position if out of bounds
					if ((x < xMin && toolTipToTheLeft) || (x > xMax && !toolTipToTheLeft))
						toolTipToTheLeft = !toolTipToTheLeft;
				}
			}
			else // center x coordinate
			{
				x = stageX - probeToolTip.width / 2;
			}
		
			// if at lower-right corner of mouse, shift to the right 10 pixels to get away from the mouse pointer
			if (x > stageX && y > stageY)
				x += 10;
			
			// enforce min/max values and position tooltip
			x = Math.max(xMin, Math.min(x, xMax));
			y = Math.max(yMin, Math.min(y, yMax));
		
			probeToolTip.move(x, y);
		}
		
		
		/**
		 * cornerToolTip:
		 * false = center of tooltip will be aligned with x probe coordinate
		 * true = corner of tooltip will be aligned with x probe coordinate
		 */
		private static var cornerToolTip:Boolean = true;
		private static var toolTipAbove:Boolean = true;
		private static var toolTipToTheLeft:Boolean = false;
		private static var probeToolTip:IToolTip = null;
		private static const tempBounds:IBounds2D = new Bounds2D();	
		
		
		public static function hideProbeToolTip():void
		{
			if (probeToolTip)
				probeToolTip.visible = false;
		}
		
		private static const debugPrefix:String = "DEBUG - TJM - " + "ProbeTextUtils.as" + " - ";
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

	}
}
