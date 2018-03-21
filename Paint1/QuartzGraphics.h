#pragma once

#import <Cocoa/Cocoa.h>

void GInit();
void GStrokeColor(NSColor *color);
void GFillColor(NSColor *color);

void GClearPath();
void GLineWidth(int v);
void GMoveTo(int x, int y);
void GLineTo(int x, int y);
void GClosePath();
void GStroke();
void GFill();

void GLine(NSPoint p1,NSPoint p2);
void GDashedLine(NSPoint p1,NSPoint p2);
void GLine(int x1,int y1,int x2,int y2);
void GDashedLine(int x1,int y1,int x2,int y2);
void GBezierLine(NSPoint p1,NSPoint p2);

void GRectangle(int x1,int y1,int x2,int y2);
void GFilledRectangle(int x1,int y1,int xs,int ys,bool strokeFlag = true);
void GFilledOval(int x1,int y1,int xs,int ys);
void GOval(int x1,int y1,int xs,int ys);
void GAddArc(int x,int y,int r,int sa,int ea);

void GText(int x,int y,const char *text);
void GTextL(int x,int y,const char *text);
void GTextPCB(int x,int y,const char *text);
void GTextLegend(int x,int y,const char *text);
void GSmallText(int x,int y,const char *text);
void GTextCentered(int x,int y,const char *text);
void GCalcColor(int index);

CGSize stringSize(const char *str);
CGSize stringSizeL(const char *str);

NSPoint centerPt(NSPoint p1,NSPoint p2);
