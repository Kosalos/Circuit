#import "QuartzGraphics.h"

static NSBezierPath *path = nil;
NSColor *sColor = [NSColor blackColor];

void GStrokeColor(NSColor *color)
{
    sColor = color;
    [sColor setStroke];
}

void GFillColor(NSColor *color)
{
    [color setFill];
}

void GClearPath() { [path removeAllPoints]; }
void GLineWidth(int v) { [path setLineWidth:CGFloat(v)]; }
void GMoveTo(int x, int y) { [path moveToPoint:NSMakePoint(x,y)]; }
void GLineTo(int x, int y) { [path lineToPoint:NSMakePoint(x,y)]; }
void GClosePath() { [path closePath]; }
void GStroke() { [path stroke]; }
void GFill() { [path fill]; }

void GAddArc(int x,int y,int r,int sa,int ea)
{
    [path appendBezierPathWithArcWithCenter:NSMakePoint(x,y) radius:r startAngle:sa endAngle:ea];
}

NSPoint centerPt(NSPoint p1,NSPoint p2)
{
    return NSMakePoint((p1.x+p2.x)/2,(p1.y+p2.y)/2);
}

void GInit()
{
    if(path == nil) {
        path = [[NSBezierPath alloc]init];
        [[NSColor blackColor] set];
        [[NSGraphicsContext currentContext] setShouldAntialias:NO];
        GLineWidth(1);
    }
}

void GLine(int x1,int y1,int x2,int y2)
{
    [path removeAllPoints];
    [path moveToPoint:NSMakePoint(x1,y1)];
    [path lineToPoint:NSMakePoint(x2,y2)];
    [path stroke];
}

void GLine(NSPoint p1,NSPoint p2)
{
    GLine(p1.x,p1.y,p2.x,p2.y);
}

void GDashedLine(int x1,int y1,int x2,int y2)
{
    [path removeAllPoints];
    [path moveToPoint:NSMakePoint(x1,y1)];
    [path lineToPoint:NSMakePoint(x2,y2)];
    
    CGFloat dashes[] = { 2, 2 };
    [path setLineDash:dashes count:2 phase:0];
    [path stroke];
    
    [path setLineDash:dashes count:0 phase:0];
}

void GDashedLine(NSPoint p1,NSPoint p2)
{
    GDashedLine(p1.x,p1.y,p2.x,p2.y);
}

void GRectangle(int x1,int y1,int x2,int y2)
{
    [path removeAllPoints];
    [path appendBezierPathWithRect:NSMakeRect(x1,y1,x2-x1,y2-y1)];
    [path stroke];
}

void GFilledRectangle(int x1,int y1,int xs,int ys,bool strokeFlag)
{
    [path removeAllPoints];
    [path appendBezierPathWithRect:NSMakeRect(x1,y1,xs,ys)];
    [path fill];
    if(strokeFlag) [path stroke];
}

void GFilledOval(int x1,int y1,int xs,int ys)
{
    [path removeAllPoints];
    NSRect rect = NSMakeRect(x1,y1,xs,ys);
    
    [path removeAllPoints];
    [path appendBezierPathWithOvalInRect: rect];
    [path fill];
}

void GOval(int x1,int y1,int xs,int ys)
{
    [path removeAllPoints];
    NSRect rect = NSMakeRect(x1,y1,xs,ys);
    
    [path removeAllPoints];
    [path appendBezierPathWithOvalInRect: rect];
    [path stroke];
}

// -----------------------------------------------------------------

static NSMutableDictionary *fHandle = nil;
static NSMutableDictionary *fHandle2 = nil;
static NSMutableDictionary *fHandleP = nil;
static NSMutableDictionary *fHandleL = nil;

void allocFonts()
{
    if(fHandle == nil) {
        NSFont *fnt = [NSFont fontWithName:@"Helvetica" size:18];
        fHandle = [[NSMutableDictionary alloc] init];
        [fHandle setObject:fnt forKey:NSFontAttributeName];
        
        fnt = [NSFont fontWithName:@"Helvetica" size:28];
        fHandle2 = [[NSMutableDictionary alloc] init];
        [fHandle2 setObject:fnt forKey:NSFontAttributeName];
        
        fnt = [NSFont fontWithName:@"Helvetica Bold" size:45];
        fHandleP = [[NSMutableDictionary alloc] init];
        [fHandleP setObject:fnt forKey:NSFontAttributeName];
        
        fnt = [NSFont fontWithName:@"Apple Symbols" size:40];
        fHandleL = [[NSMutableDictionary alloc] init];
        [fHandleL setObject:fnt forKey:NSFontAttributeName];
    }
}

void GText(int x,int y,const char *text)
{
    allocFonts();
    [fHandle setObject:sColor forKey:NSForegroundColorAttributeName];
    
    NSString *hws = [NSString stringWithUTF8String:text];
    [hws drawAtPoint:NSMakePoint(x,y) withAttributes:fHandle];
}

void GTextL(int x,int y,const char *text)
{
    allocFonts();
    [fHandle2 setObject:sColor forKey:NSForegroundColorAttributeName];
    
    NSString *hws = [NSString stringWithUTF8String:text];
    [hws drawAtPoint:NSMakePoint(x,y) withAttributes:fHandle2];
}

void GTextPCB(int x,int y,const char *text)
{
    allocFonts();
    [fHandleP setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
    
    NSString *hws = [NSString stringWithUTF8String:text];
    
    CGContextRef gc = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(gc);
    
    CGContextScaleCTM(gc,-1,1);
    CGContextTranslateCTM(gc,-x,0);
    
    GFillColor([NSColor blackColor]);
    GFilledRectangle(0,y,500,50);
    
    [hws drawAtPoint:NSMakePoint(0,y-5) withAttributes:fHandleP];
    
    CGContextRestoreGState(gc);
}

void GTextLegend(int x,int y,const char *text)
{
    allocFonts();
    [fHandleL setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
    
    NSString *hws = [NSString stringWithUTF8String:text];
    
    CGContextRef gc = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(gc);
    
    CGContextScaleCTM(gc,-1,1);
    CGContextTranslateCTM(gc,-x,0);
    
    [hws drawAtPoint:NSMakePoint(0,y-5) withAttributes:fHandleL];
    
    CGContextRestoreGState(gc);
}

CGSize stringSize(const char *str)
{
    allocFonts();
    
    NSString *s = [NSString stringWithUTF8String:str];
    
    return [s sizeWithAttributes:fHandle];
}

CGSize stringSizeL(const char *str)
{
    allocFonts();
    
    NSString *s = [NSString stringWithUTF8String:str];
    
    return [s sizeWithAttributes:fHandle2];
}

void GTextCentered(int x,int y,const char *text)
{
    CGSize sz = stringSize(text);
    GText(x - sz.width/2,y-9,text);
}

// -----------------------------------------------------------------

static NSMutableDictionary *smattribs = nil;

void GSmallText(int x,int y,const char *text)
{
    if(smattribs == nil) {
        NSFont *fnt = [NSFont fontWithName:@"Helvetica" size:16];
        
        smattribs = [[NSMutableDictionary alloc] init];
        [smattribs setObject:fnt forKey:NSFontAttributeName];
        [smattribs setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
    }
    
    NSString *hws = [NSString stringWithUTF8String:text];
    [hws drawAtPoint:NSMakePoint(x,y) withAttributes:smattribs];
}

// ==============================================================

void GCalcColor(int index)
{
    float min = 0.2;
    float max = (1.0 - min)/8.0;
    
    float r = 0.2 + float(index % 8) * max;
    float g = 0.2 + float((index+2) % 8) * max;
    float b = 0.2 + float((index+5) % 8) * max;
    
    if((index % 3)==0) r = 0;
    if((index % 3)==1) g = 0;
    if((index % 3)==2) b = 0;
    
    NSColor *c = [NSColor colorWithRed:r green:g blue:b alpha:1];
    [c set];
    
}

void GBezierLine(NSPoint p1,NSPoint p2)
{
    float angle = atan2(p2.y - p1.y,p2.x - p1.x) + M_PI/2.0f;
    float offset = 80;
    float ss = sinf(angle) * offset;
    float cc = cosf(angle) * offset;

    NSPoint n1 = p1;
    NSPoint n2 = p2;
    n1.x += cc;
    n1.y += ss;
    n2.x -= cc;
    n2.y -= ss;
    
//    [path removeAllPoints];
//    [path moveToPoint:p1];
//    [path lineToPoint:n1];
//    [path lineToPoint:n2];
//    [path lineToPoint:p2];
//    [path stroke];

    [path removeAllPoints];
    [path moveToPoint:p1];
    [path curveToPoint:p2 controlPoint1:n1 controlPoint2:n2];
    [path stroke];
}

