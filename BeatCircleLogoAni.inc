[Rainmeter]
OnRefreshAction=[!CommandMeasure MeasureActionTimer "Execute 1"][!CommandMeasure MeasureActionTimer "Execute 2"]

[Variables]
@Include2=#@#Variables.inc
ImageXScale=0
ImageYScale=0
ImageAlphaFactor=0
ImageXScaleFactor=(#Radius#*#ImageXScale#)
ImageYScaleFactor=(#Radius#*#ImageYScale#)
UpdateImgMeters=[!UpdateMeasure MeasureActionTimer][!UpdateMeter CenterLogo][!Redraw]
W=30

[MeasureActionTimer]
Measure=Plugin
Plugin=ActionTimer
ActionList1=Repeat CountUp, #W#, 100
ActionList2=Repeat AlphaUp, 10, 100 | Repeat AlphaDown, 15, 100
CountUp=[!SetVariable ImageXScaleFactor "(#ImageXScaleFactor#+(0.005*#Radius#))"][!SetVariable ImageYScaleFactor "(#ImageYScaleFactor#+(0.005*#Radius#))"]#UpdateImgMeters#
AlphaUp=[!SetVariable ImageAlphaFactor "(#ImageAlphaFactor#+(255/100))"]#UpdateImgMeters#
AlphaDown=[!SetVariable ImageAlphaFactor "(#ImageAlphaFactor#-(255/100))"]#UpdateImgMeters#
DynamicVariables=1
