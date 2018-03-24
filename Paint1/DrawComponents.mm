#import "QuartzView.h"
#import "ViewController.h"
#import "QuartzGraphics.h"
#import "Persist.h"
#import "DrawComponents.h"

int xcoord(int index) { return scrollX + (index + sX) * gHop; }
int ycoord(int index) { return scrollY + (index) * gHop; }

int xcoord(CircuitEntry &ref) { return xcoord(ref.pt.x); }
int ycoord(CircuitEntry &ref) { return ycoord(ref.pt.y); }

#define UNUSED -1

void drawLabel(int x,int y,const char *strParent,bool highlight,int px = UNUSED, int py = UNUSED)
{
    if(viewStyle != VIEWSTYLE_DESIGN) return;
    if(strlen(strParent) == 0) return;
    
    int xMargin = 4;
    int yMargin = -1;
    
    char str[128];
	char str2[128];
    strcpy(str,strParent);
	CGSize sz = stringSize(str);

	// comma = 2nd line
	bool secondLine = false;
	char *cc = strstr(str,",");
	if(cc != NULL) {
		*cc = 0;
		strcpy(str2,cc+1);
		
		CGSize sz1 = stringSize(str);
		CGSize sz2 = stringSize(str2);
		sz = (sz1.width > sz2.width) ? sz1 : sz2;
		sz.height *= 2;
		secondLine = true;
	}
	
    if(semiColonClip) {
        char *ch = strchr(str,';');
        if(ch != NULL) *ch = 0;
    }
	
    x -= sz.width/2;
    y -= sz.height/2;
    
    GFillColor([NSColor whiteColor]);
    GLineWidth(1);
    
    if(highlight || !highlightCount) { // normal display
        GStrokeColor([NSColor blackColor]);
        GFilledRectangle(x-xMargin/2,y-yMargin,sz.width+xMargin,sz.height+yMargin);
    }
    else { // not part of highlighted group. draw in gray tones
		GStrokeColor(seeThroughGrayColor); //    [NSColor grayColor]);
        GFilledRectangle(x-xMargin/2,y-yMargin,sz.width+xMargin,sz.height+yMargin);
        GStrokeColor([NSColor darkGrayColor]);
		
		if(state == STATE_LOOK) return;
    }
    
    GText(x,y,str);
	if(secondLine) GText(x,y + sz.height/2,str2);
    
    // draw line connecting text to it's parent
    if(px != UNUSED)
        GLine(x+sz.width+xMargin,y+sz.height+yMargin,px,py);
}

//NSColor *colorOfPoint(CGPoint point) {
//	unsigned char pixel[4] = {0};
//
//	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//
//	CGContextRef context = CGBitmapContextCreate(pixel, 1, 1, 8, 4, colorSpace, kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedLast);
//
//	CGContextTranslateCTM(context, -point.x, -point.y);
//
//	[quartzView.layer renderInContext:context];
//
//	CGContextRelease(context);
//	CGColorSpaceRelease(colorSpace);
//
//	//NSLog(@"pixel: %d %d %d %d", pixel[0], pixel[1], pixel[2], pixel[3]);
//
//	NSColor *color = [NSColor colorWithRed:pixel[0]/255.0 green:pixel[1]/255.0 blue:pixel[2]/255.0 alpha:pixel[3]/255.0];
//
//	return color;
//}

void whiteBox(int x1,int y1,int x2,int y2)
{
    [[NSColor whiteColor] set];
	//[colorOfPoint(CGPointMake(CGFloat(x1),CGFloat(y1))) set];
	
    GFilledRectangle(x1,y1,x2-x1,y2-y1,false);
    GClearPath();
}


void drawCurvedWaypoint(int index)
{
    if(justLabels) return;
    
    CircuitEntry &ref = q.circuit[index];
    float xp = xcoord(ref);
    float yp = ycoord(ref);
    float gs = gHop / 2;
    int offset = isZoom ? 10 : 5;
    
    float width = isZoom ? CONNECTION_WIDTH_DESIGN*2 : CONNECTION_WIDTH_DESIGN;
    if(viewStyle == VIEWSTYLE_TRACE) width = isZoom ? CONNECTION_WIDTH_DESIGN*8+2 : CONNECTION_WIDTH_DESIGN*4+1;
    
    switch(ref.orient) {
        case HORZ : // 12 o'Clock - 3 o'Clock
            whiteBox(xp-offset,yp-gs,xp+gs,yp+offset);
            setHighlightStrokeColor(index);
            GMoveTo(xp+gs,yp);
            GAddArc(xp+gs,yp-gs,gs,90,180);
            GLineWidth(width);
            GStroke();
            break;
        case HORZ2 : // 3-6
            whiteBox(xp-offset,yp-offset,xp+gs,yp+gs);
            setHighlightStrokeColor(index);
            GMoveTo(xp,yp+gs);
            GAddArc(xp+gs,yp+gs,gs,180,270);
            GLineWidth(width);
            GStroke();
            break;
        case VERT : // 6-9
            whiteBox(xp-gs,yp-offset,xp+offset,yp+gs);
            setHighlightStrokeColor(index);
            GMoveTo(xp-gs,yp);
            GAddArc(xp-gs,yp+gs,gs,270,0);
            GLineWidth(width);
            GStroke();
            break;
        case VERT2 : // 9-12
            whiteBox(xp-gs+1,yp-gs+1,xp+offset,yp+offset);
            setHighlightStrokeColor(index);
            GMoveTo(xp,yp-gs);
            GAddArc(xp-gs,yp-gs,gs,0,90);
            GLineWidth(width);
            GStroke();
            break;
    }
}

void drawWaypoint(int index)
{
    if(justLabels) return;
    
    if(viewStyle != VIEWSTYLE_TRACE) {
        CircuitEntry &ref = q.circuit[index];
        
        if(designStyle && ref.name[0] != 0) {
            const int SZ = 7;
            int xp = xcoord(ref) - SZ;
            int yp = ycoord(ref) - SZ;
            
            if(ref.orient == SHARP) {
                GFillColor(highlightColor(isHighlighted(index)));
                GFilledOval(xp,yp,SZ*2,SZ*2);
            }
        }
        else {
            const int SZ = 3;
            int xp = xcoord(ref) - SZ;
            int yp = ycoord(ref) - SZ;
            
            if(ref.orient == SHARP) {
                bool highlight = isHighlighted(index);
                
                GFillColor(highlightColor(highlight));
                setHighlightStrokeColor(index);
                
                GFilledRectangle(xp,yp,SZ*2,SZ*2);
            }
            
            drawLabel(xp,yp- gHop/4,ref.name,false);
        }
    }
}

void drawLegend(int index)
{
    CircuitEntry &ref = q.circuit[index];
    GTextLegend(xcoord(ref),ycoord(ref),ref.name);
}

void drawNodeCircle(int x,int y)
{
    if(viewStyle == VIEWSTYLE_TRACE) { // on PCB nodes have a white center hole
        int sz = NODE_SIZE_PCB * gZoom;
        int xp = xcoord(x) - sz/2;
        int yp = ycoord(y) - sz/2;
        
        GFillColor([NSColor blackColor]);
        GFilledOval(xp,yp,sz,sz);
        
        sz = NODE_HOLE_SIZE * gZoom;
        xp = xcoord(x) - sz/2;
        yp = ycoord(y) - sz/2;
        
        GFillColor([NSColor whiteColor]);
        GFilledOval(xp,yp,sz,sz);
        
        return;
    }
    
    int sz = NODE_RADIUS * gZoom;
    int xp = xcoord(x) - sz/2;
    int yp = ycoord(y) - sz/2;
    
    GFilledOval(xp,yp,sz,sz);
    GStroke();
}

void drawNodeSquare(int x,int y)
{
    if(viewStyle == VIEWSTYLE_TRACE) { // on PCB nodes have a white center hole
        int sz = (NODE_SIZE_PCB-2) * gZoom;
        int xp = xcoord(x) - sz/2;
        int yp = ycoord(y) - sz/2;
        
        GFillColor([NSColor blackColor]);
        GFilledRectangle(xp,yp,sz,sz);
        
        sz = NODE_HOLE_SIZE * gZoom;
        xp = xcoord(x) - sz/2;
        yp = ycoord(y) - sz/2;
        
        GFillColor([NSColor whiteColor]);
        GFilledOval(xp,yp,sz,sz);
        
        return;
    }
    
    int sz = (NODE_RADIUS) * gZoom;
    int xp = xcoord(x) - sz/2;
    int yp = ycoord(y) - sz/2;
    
    GFilledRectangle(xp,yp,sz,sz);
    GStroke();
}
void drawNode(int index)
{
    bool highlight = isHighlighted(index);
    
    GFillColor(highlight ? [NSColor blackColor] : highlightColor(highlight));
    setHighlightStrokeColor(index);
    
    drawNodeCircle(q.circuit[index].pt.x,q.circuit[index].pt.y);
}

void drawPin(int x,int y,bool highlightStatus)
{
    GFillColor(highlightStatus ? [NSColor blackColor] : highlightColor(highlightStatus));
    setHighlightStrokeColor(highlightStatus);
    
    drawNodeCircle(x,y);
}

void drawSquarePin(CircuitEntry &ref,int offsetX,int offsetY,bool highlightStatus)
{
    int x = ref.pt.x + offsetX;
    int y = ref.pt.y + offsetY;
    
    GFillColor(highlightStatus ? [NSColor blackColor] : highlightColor(highlightStatus));
    setHighlightStrokeColor(highlightStatus);
    
    drawNodeSquare(x,y);
}

void drawPin(CircuitEntry &ref,int offsetX,int offsetY,bool highlightStatus,bool squarePin = false)
{
    if(squarePin)
        drawSquarePin(ref,offsetX,offsetY,highlightStatus);
    else
        drawPin(ref.pt.x + offsetX,ref.pt.y + offsetY,highlightStatus);
}

void drawPlus(int xp,int yp,bool highlightStatus)
{
    int o2 = gOffset+3;
    
    GLineWidth(2);
    GClearPath();
    GMoveTo(xp,yp-gOffset);
    GLineTo(xp+o2/2,yp-gOffset);
    GMoveTo(xp+o2/4,yp-gOffset-o2/4);
    GLineTo(xp+o2/4,yp-gOffset+o2/4);
    GStroke();
    
    GLineWidth(1);
}

void drawPlus(CircuitEntry &ref,int offsetX,int offsetY,bool highlightStatus)
{
    int xp = xcoord(ref) - gHop/2;
    int yp = ycoord(ref);
    
    drawPlus(xp + offsetX,yp + offsetY,highlightStatus);
}

void drawGroundNode(int index)
{
    if(designStyle) {
        int xp = xcoord(q.circuit[index].pt.x);
        int yp = ycoord(q.circuit[index].pt.y);
        
        setHighlightStrokeColor(isHighlighted(index));
        
        GClearPath();
        GLineWidth(3);
        GLine(xp,yp,xp,yp+gHop*3/4);
        
        int w = gHop/2;
        for(int i=0;i<4;++i) {
            yp += gHop/5;
            GLine(xp-w,yp,xp+w,yp);
            w -= gHop/7;
        }
        
        GStroke();
        GLineWidth(1);
    }
    else {
        if(viewStyle == VIEWSTYLE_JUMPER) return;
            
        int sz = NODE_RADIUS * gZoom;
        int xp = xcoord(q.circuit[index].pt.x) - sz/2;
        int yp = ycoord(q.circuit[index].pt.y) - sz/2;
        bool highlightStatus = isHighlighted(index);
        
        if(viewStyle == VIEWSTYLE_TRACE) {
            GFillColor([NSColor blackColor]);
            GFilledOval(xp,yp,sz,sz);
        }
        else {
			GFillColor(state == STATE_LOOK ? seeThroughGrayColor : [NSColor greenColor]);
            GFilledOval(xp,yp,sz,sz);
            
            setHighlightStrokeColor(highlightStatus);
            GStroke();
            
            setHighlightStrokeColor(index);
            GOval(xp-1,yp-1,sz+2,sz+2);
        }
    }
}

void drawOpAmp(CircuitEntry &ref,bool highlight)
{
    int xp = xcoord(ref);
    int yp = ycoord(ref);
    
    GFillColor(resColor);
    setHighlightStrokeColor(highlight);
    
    GClearPath();
    GMoveTo(xp-gOffset/2,yp-gOffset);
    GLineTo(xp+gHop*2+gOffset,yp+gHop);
    GLineTo(xp-gOffset/2,yp+gHop*2+gOffset);
    GClosePath();
    
    if(viewStyle == VIEWSTYLE_DESIGN) {
        GFillColor(tranColor2);
        GFill();
    }
    GFillColor(tranColor);
    GStroke();
    
    drawPin(ref,0,0,highlight);
    drawPin(ref,0,2,highlight);
    drawPin(ref,2,1,highlight);
    
    // -,+
    int o2 = gOffset+3;
    GClearPath();
    GMoveTo(xp,yp+gOffset);
    GLineTo(xp+o2/2,yp+gOffset);
    
    GMoveTo(xp,yp+gHop*2-gOffset);
    GLineTo(xp+o2/2,yp+gHop*2-gOffset);
    GMoveTo(xp+o2/4,yp+gHop*2-gOffset-o2/4);
    GLineTo(xp+o2/4,yp+gHop*2-gOffset+o2/4);
    GStroke();
    
    // name -----------------------------
    if(viewStyle == VIEWSTYLE_TRACE) return;
    
    char name[NAME_WIDTH+1];
    strcpy(name,ref.name);
    
    int p1=0,p2=0,p3=0;
    char *semi = strchr(name,';');
    if(semi != NULL) {
        *semi++ = 0;
        p1 = atoi(semi);
        
        char *comma = strchr(semi,',');
        if(comma == NULL) return;
        ++comma;
        p2 = atoi(comma);
        
        comma = strchr(comma,',');
        if(comma == NULL) return;
        ++comma;
        p3 = atoi(comma);
    }
    
    GText(xp,yp+gHop-5*gZoom,name);
    
    if(semi == NULL) return;
    
    int x = xp+5*gZoom;
    sprintf(name,"%d",p1);
    GText(x,yp-2*gZoom,name);
    sprintf(name,"%d",p2);
    GText(x,yp+gHop*2-12*gZoom,name);
    sprintf(name,"%d",p3);
    GText(xp+gHop*2-16*gZoom,yp+gHop-6*gZoom,name);
}

void drawInverter(CircuitEntry &ref,bool highlight)
{
    int x,y,sz;
    int xp = xcoord(ref);
    int yp = ycoord(ref);
    
    GFillColor(resColor);
    setHighlightStrokeColor(highlight);
    
    GClearPath();
    GMoveTo(xp-gOffset/2,yp-gOffset);
    GLineTo(xp+gHop*2+gOffset,yp+gHop);
    GLineTo(xp-gOffset/2,yp+gHop*2+gOffset);
    GClosePath();
    
    if(viewStyle == VIEWSTYLE_DESIGN) {
        GFillColor(tranColor2);
        GFill();
    }
    GFillColor(tranColor);
    GStroke();
    
    GStrokeColor([NSColor blackColor]);
    GFillColor([NSColor whiteColor]);
    
    x = xp + gHop * 5 / 2 - 3 * gZoom;
    y = yp + gHop - 5 * gZoom;
    sz = 10 * gZoom;
    GFilledOval(x,y,sz,sz);
    GOval(x,y,sz,sz);
    
    drawPin(ref,0,1,highlight);
    drawPin(ref,3,1,highlight);
    
    // name -----------------------------
    if(viewStyle == VIEWSTYLE_TRACE) return;
    
    char name[NAME_WIDTH+1];
    strcpy(name,ref.name);
    
    int p1=0,p2=0;
    char *semi = strchr(name,';');
    if(semi != NULL) {
        *semi++ = 0;
        p1 = atoi(semi);
        
        char *comma = strchr(semi,',');
        if(comma == NULL) return;
        ++comma;
        p2 = atoi(comma);
    }
    
    x = xp + 7 * gZoom;
    y = yp;
    GText(x,yp,name);
    
    if(semi == NULL) return;
    
    y += gHop;
    sprintf(name,"%d",p1);
    GText(x,y,name);
    x += 3*gHop;
    sprintf(name,"%d",p2);
    GText(x,y,name);
}

void drawXOR(CircuitEntry &ref,bool highlight)
{
    int xp = xcoord(ref);
    int yp = ycoord(ref);
    int x1 = xp-gOffset/2;
    int y1 = yp-gOffset;
    int x2 = x1;
    int y2 = yp+gHop*2+gOffset;
    int x3 = xp+gHop*2+gOffset;
    int y3 = yp+gHop*1;
    int x4 = x1 + (x3-x1)*2/3;
    int y4 = y1 + (y3-y1)*1/3;
    int x5 = x4;
    int y5 = y3 + (y2-y3)*2/3;
    int x6 = x1 + gOffset;
    int y6 = (y1 + y2)/2;
    
    GFillColor(resColor);
    setHighlightStrokeColor(highlight);
    
    GClearPath();
    GMoveTo(x1,y1);
    GLineTo(x4,y4);
    GLineTo(x3,y3);
    GLineTo(x5,y5);
    GLineTo(x2,y2);
    GLineTo(x6,y6);
    GClosePath();
    
    if(viewStyle == VIEWSTYLE_DESIGN) {
        GFillColor(tranColor2);
        GFill();
    }
    GFillColor(tranColor);
    GStroke();
    
    GClearPath();
    int xx = gOffset/2;
    GMoveTo(x1-xx,y1);
    GLineTo(x6-xx,y6);
    GLineTo(x2-xx,y2);
    GStroke();
    
    drawPin(ref,0,0,highlight);
    drawPin(ref,0,2,highlight);
    drawPin(ref,2,1,highlight);
    
    // name -----------------------------
    if(viewStyle == VIEWSTYLE_TRACE) return;
    
    char name[NAME_WIDTH+1];
    strcpy(name,ref.name);
    
    int p1=0,p2=0,p3=0;
    char *semi = strchr(name,';');
    if(semi != NULL) {
        *semi++ = 0;
        p1 = atoi(semi);
        
        char *comma = strchr(semi,',');
        if(comma == NULL) return;
        ++comma;
        p2 = atoi(comma);
        
        comma = strchr(comma,',');
        if(comma == NULL) return;
        ++comma;
        p3 = atoi(comma);
    }
    
    GText(xp + gHop,yp-3*gZoom ,name);
    
    if(semi == NULL) return;
    
    int x = xp+5*gZoom;
    sprintf(name,"%d",p1);
    GText(x,yp-3*gZoom,name);
    sprintf(name,"%d",p2);
    GText(x,yp+gHop*2-6*gZoom,name);
    sprintf(name,"%d",p3);
    GText(xp+gHop*2-13*gZoom,yp+gHop-4*gZoom,name);
}

void drawPot(int index)
{
    CircuitEntry &ref = q.circuit[index];
    bool highlight = isHighlighted(index);
    
    int xp = xcoord(ref);
    int yp = ycoord(ref);
    int x1 = xp - gHop - gOffset;
    int x2 = xp + gOffset;
    int y1 = yp - gHop;
    int y2 = yp + gHop * 5;
    
    if(!justLabels) {
        if(viewStyle != VIEWSTYLE_TRACE) {
            setHighlightFillColor(chipColor2,highlight);
            setHighlightStrokeColor(index);
            GFilledRectangle(x1,y1,x2-x1,y2-y1);
        }
    }
    
    GStrokeColor([NSColor blackColor]);
    
    char str[20];
    for(int i=0;i<3;++i) {
        drawPin(ref,0,i*2,highlight);
        
        if(viewStyle == VIEWSTYLE_DESIGN) {
            sprintf(str,"%d",i+1);
            GText(xp-gHop,yp+i*gHop*2-gHop+gOffset,str);
        }
    }
    
    if(viewStyle == VIEWSTYLE_DESIGN)
        GText(xp-gHop,yp-gHop,ref.name);
}

void drawPower(int index)
{
    CircuitEntry &ref = q.circuit[index];
    bool highlight = isHighlighted(index);
    
    int xp = xcoord(ref);
    int yp = ycoord(ref);
    
    setHighlightFillColor(resColor,highlight);
    setHighlightStrokeColor(index);
    
    if(ref.orient == HORZ || ref.orient == HORZ2) {
        if(viewStyle != VIEWSTYLE_TRACE) {
            int xs = gHop * 4;
            GRectangle(xp-gOffset,yp-gOffset,xp+xs+gOffset,yp+gOffset);
            GRectangle(xp+gHop*7/2,yp-gOffset,xp+xs+gOffset,yp+gOffset);
        }
        
        for(int i=0;i<5;++i)
            drawPin(ref,i,0,highlight,i==4);
    } else { // vertical
        if(viewStyle != VIEWSTYLE_TRACE) {
            int ys = gHop * 4;
            GRectangle(xp-gOffset,yp-gOffset,xp+gOffset,yp+ys+gOffset);
            GRectangle(xp-gOffset,yp-gOffset,xp+gOffset,yp+gHop/2);
        }
        
        for(int i=0;i<5;++i)
            drawPin(ref,0,i,highlight,i==0);
    }
}

void drawResistor(int index)
{
    CircuitEntry &ref = q.circuit[index];
    bool highlight = isHighlighted(index);
    int xp = xcoord(ref);
    int yp = ycoord(ref);
    
    setHighlightFillColor(resColor,highlight);
    setHighlightStrokeColor(index);
	
    if(ref.orient == HORZ || ref.orient == HORZ2) {
        int xs = gHop * ref.size;
        int ys = 0;
        
        if(!justLabels) {
            if(viewStyle != VIEWSTYLE_TRACE) {
                setHighlightFillColor(resColor2,highlight);
                GFilledRectangle(xp-gOffset+1,yp-gOffset+1,xs+gOffset*2-2,ys+gOffset*2-2);
				if(state == STATE_LOOK) return;
            }
            drawPin(ref,0,0,highlight);
            drawPin(ref,ref.size,0,highlight);
        }
		
		if(state == STATE_LOOK) return;
        drawLabel(xp + xs/2,yp,ref.name,highlight);
        
    } else { // vertical
        int xs = 0;
        int ys = gHop * ref.size;
        
        if(!justLabels) {
            if(viewStyle != VIEWSTYLE_TRACE) {
                setHighlightFillColor(resColor2,highlight);
                GFilledRectangle(xp-gOffset+1,yp-gOffset+1,xs+gOffset*2-2,ys+gOffset*2-2);
				if(state == STATE_LOOK) return;
            }
            drawPin(ref,0,0,highlight);
            drawPin(ref,0,ref.size,highlight);
        }
		if(state == STATE_LOOK) return;
        drawLabel(xp,yp+ys/2,ref.name,highlight);
    }
}

void drawCapacitor(int index)
{
    CircuitEntry &ref = q.circuit[index];
    bool highlight = isHighlighted(index);
    int xp = xcoord(ref);
    int yp = ycoord(ref);
    int longAxis = ref.size * gHop + gHop/2;
    int shortAxis = gHop/2;
    
    setHighlightFillColor(capColor,highlight);
    setHighlightStrokeColor(index);
    
    if(ref.orient == HORZ || ref.orient == HORZ2) {
        int xs = longAxis;
        int ys = shortAxis;
        if(!justLabels) {
            if(viewStyle != VIEWSTYLE_TRACE) {
                setHighlightFillColor(capColor2,highlight);
                GFilledOval(xp-gOffset,yp-gOffset,xs+gOffset,ys+gOffset);
            }
            GStroke();
			if(state == STATE_LOOK) return;
            GFillColor([NSColor blackColor]);
            drawPin(ref,0,0,highlight);
            drawPin(ref,ref.size,0,highlight);
        }
		if(state == STATE_LOOK) return;
        drawLabel(xp + (xs-gHop/2)/2,yp,ref.name,highlight);
        
    } else { // vertical
        int xs = shortAxis;
        int ys = longAxis;
        if(!justLabels) {
            if(viewStyle != VIEWSTYLE_TRACE) {
                setHighlightFillColor(capColor2,highlight);
                GFilledOval(xp-gOffset,yp-gOffset,xs+gOffset,ys+gOffset);
            }
            GStroke();
			if(state == STATE_LOOK) return;
            GFillColor([NSColor blackColor]);
            drawPin(ref,0,0,highlight);
            drawPin(ref,0,ref.size,highlight);
        }
		if(state == STATE_LOOK) return;
        drawLabel(xp,yp+(ys-gHop/2)/2,ref.name,highlight);
    }
}

void drawECapacitor(int index)
{
    CircuitEntry &ref = q.circuit[index];
    bool highlight = isHighlighted(index);
    int xp = xcoord(ref);
    int yp = ycoord(ref);
    int longAxis = ref.size * gHop + gHop/2;
    int shortAxis = gHop/2;
    
    setHighlightFillColor(capColor,highlight);
    setHighlightStrokeColor(index);
    
    if(ref.orient == HORZ || ref.orient == HORZ2) {
        int xs = longAxis;
        int ys = shortAxis;
        if(!justLabels) {
            if(viewStyle != VIEWSTYLE_TRACE) {
                setHighlightFillColor(capColor2,highlight);
                GFilledOval(xp-gOffset,yp-gOffset,xs+gOffset,ys+gOffset);
            }
            GStroke();
			if(state == STATE_LOOK) return;
            GFillColor([NSColor blackColor]);
            drawPin(ref,0,0,highlight,ref.orient == HORZ);
            drawPin(ref,ref.size,0,highlight,ref.orient != HORZ);
            
            if(viewStyle == VIEWSTYLE_DESIGN) {
                int xx = 0;
                if(ref.orient == HORZ2) xx += (ref.size+1) * gHop;
                drawPlus(ref,xx,0,highlight);
            }
        }
		if(state == STATE_LOOK) return;
        drawLabel(xp + (xs-gHop/2)/2,yp,ref.name,highlight);
        
    } else { // vertical
        int xs = shortAxis;
        int ys = longAxis;
        if(!justLabels) {
            if(viewStyle != VIEWSTYLE_TRACE) {
                setHighlightFillColor(capColor2,highlight);
                GFilledOval(xp-gOffset,yp-gOffset,xs+gOffset,ys+gOffset);
            }
            GStroke();
			if(state == STATE_LOOK) return;
            GFillColor([NSColor blackColor]);
            drawPin(ref,0,0,highlight,ref.orient == VERT);
            drawPin(ref,0,ref.size,highlight,ref.orient != VERT);
            
            if(viewStyle == VIEWSTYLE_DESIGN) {
                int yy = 0;
                if(ref.orient == VERT2) yy += (ref.size+1) * gHop;
                drawPlus(ref,0,yy,highlight);
            }
            
        }
		if(state == STATE_LOOK) return;
        drawLabel(xp,yp+(ys-gHop/2)/2,ref.name,highlight);
    }
}

void drawDiode(int index)
{
    CircuitEntry &ref = q.circuit[index];
    bool highlight = isHighlighted(index);
    int xp = xcoord(ref);
    int yp = ycoord(ref);
    int x1,x2,y1,y2;
    
    setHighlightFillColor(resColor,highlight);
    setHighlightStrokeColor(index);
    
    if(ref.orient == HORZ || ref.orient == HORZ2) {
        int xs = gHop * ref.size + gOffset;
        int ys = gOffset;;
        
        if(!justLabels) {
            if(viewStyle != VIEWSTYLE_TRACE) {
                setHighlightFillColor(resColor2,highlight);
                GFilledRectangle(xp-gOffset+1,yp-gOffset+1,xs+gOffset-2,ys+gOffset-2);
            }
            
            drawPin(ref,0,0,highlight,ref.orient == HORZ);
            drawPin(ref,ref.size,0,highlight,ref.orient != HORZ);
            
            if(viewStyle == VIEWSTYLE_DESIGN) {
                if(ref.orient == HORZ) {
                    x1 = xp+xs/2 - gOffset;
                    x2 = x1 + gOffset;
                    y1 = yp - gOffset/2;
                    y2 = yp + gOffset/2;
                }
                else {
                    x1 = xp+xs/2;
                    x2 = x1 - gOffset;
                    y1 = yp - gOffset/2;
                    y2 = yp + gOffset/2;
                }
                
                GClearPath();
                GMoveTo(x1,y1);
                GLineTo(x2,yp);
                GLineTo(x1,y2);
                GClosePath();
                GFill();
                GLineWidth(2);
                GLine(xp,yp,xp+xs-gOffset,yp);
                GLine(x2,y1,x2,y2);
                GLineWidth(1);
            }
        }
        drawLabel(xp + xs/2+1,yp-10,ref.name,highlight);
        
    } else { // vertical
        int xs = gOffset;;
        int ys = gHop * ref.size + gOffset;
        
        if(!justLabels) {
            if(viewStyle != VIEWSTYLE_TRACE) {
                setHighlightFillColor(resColor2,highlight);
                GFilledRectangle(xp-gOffset+1,yp-gOffset+1,xs+gOffset-2,ys+gOffset-2);
            }
            
            drawPin(ref,0,0,highlight,ref.orient == VERT);
            drawPin(ref,0,ref.size,highlight,ref.orient != VERT);
            
            if(viewStyle == VIEWSTYLE_DESIGN) {
                if(ref.orient == VERT) {
                    y1 = yp+ys/2 - gOffset;
                    y2 = y1 + gOffset;
                    x1 = xp - gOffset/2;
                    x2 = xp + gOffset/2;
                }
                else {
                    y1 = yp+ys/2;
                    y2 = y1 - gOffset;
                    x1 = xp - gOffset/2;
                    x2 = xp + gOffset/2;
                }
                
                GClearPath();
                GMoveTo(x1,y1);
                GLineTo(x2,y1);
                GLineTo(xp,y2);
                GClosePath();
                GFill();
                GLineWidth(2);
                GLine(xp,yp,xp,yp+ys-gOffset);
                GLine(x1,y2,x2,y2);
                GLineWidth(1);
            }
        }
        drawLabel(xp-10,yp+ys/2,ref.name,highlight);
    }
}

void drawTransistor(int index)
{
    CircuitEntry &ref = q.circuit[index];
    bool highlight = isHighlighted(index);
    float xp = xcoord(ref);
    float yp = ycoord(ref);
    float xs = gHop * 2;
    float ys = gHop * 2;
    float gs = gHop / 2;
    float gs2= gHop * 1.5;
    
    setHighlightFillColor(tranColor,highlight);
    setHighlightStrokeColor(index);
    
    if(!justLabels) {
        GClearPath();
        
        switch(ref.orient) {
            case HORZ : // flat up
                if(viewStyle != VIEWSTYLE_TRACE) {
                    GMoveTo(xp-gs,yp);
                    GLineTo(xp-gs,yp-gs);
                    GLineTo(xp+xs+gs,yp-gs);
                    GLineTo(xp+xs+gs,yp);
                    GAddArc(xp+xs/2,yp,gs2,0,180);
                    setHighlightFillColor(tranColor2,highlight);
                    GFill();
                    setHighlightFillColor(tranColor2,highlight);
                    GStroke();
                }
                for(int i=0;i<3;++i)
                    drawPin(ref,i,0,highlight);
                break;
            case HORZ2 : // flat down
                if(viewStyle != VIEWSTYLE_TRACE) {
                    GMoveTo(xp+xs+gs,yp);
                    GLineTo(xp+xs+gs,yp+gs);
                    GLineTo(xp-gs,yp+gs);
                    GLineTo(xp-gs,yp);
                    GAddArc(xp+xs/2,yp,gs2,180,360);
                    setHighlightFillColor(tranColor2,highlight);
                    GFill();
                    GStroke();
                }
                for(int i=0;i<3;++i)
                    drawPin(ref,i,0,highlight);
                break;
            case VERT : // flat right
                if(viewStyle != VIEWSTYLE_TRACE) {
                    GMoveTo(xp,yp-gs);
                    GLineTo(xp+gs,yp-gs);
                    GLineTo(xp+gs,yp+ys+gs);
                    GAddArc(xp,yp+ys/2,gs2,90,270);
                    setHighlightFillColor(tranColor2,highlight);
                    GFill();
                    GStroke();
                }
                for(int i=0;i<3;++i)
                    drawPin(ref,0,i,highlight);
                break;
            case VERT2 : // flat left
                if(viewStyle != VIEWSTYLE_TRACE) {
                    GMoveTo(xp,yp+ys+gs);
                    GLineTo(xp-gs,yp+ys+gs);
                    GLineTo(xp-gs,yp-gs);
                    GLineTo(xp,yp-gs);
                    GAddArc(xp,yp+ys/2,gs2,270,90);
                    setHighlightFillColor(tranColor2,highlight);
                    GFill();
                    GStroke();
                }
                for(int i=0;i<3;++i)
                    drawPin(ref,0,i,highlight);
                break;
        }
    }
    
    // name -----------------------------
    if(viewStyle != VIEWSTYLE_DESIGN) return;
	if(state == STATE_LOOK) return;
    
    GStrokeColor((highlight || !highlightCount) ? [NSColor blackColor] : [NSColor darkGrayColor]);
    
    // if the transistor name contains a ';'  the next 3 characters are labels for the 3 pins.
    // example:  "BC547;CBE"  will labels the pins 'C','B' and 'E' for collector, base, emmiter
    
    char name[32];
    strcpy(name,ref.name);
    char n1='a',n2='a',n3='a',*semi = strchr(name,';');
    if(semi != NULL) {
        *semi = 0;
        n1 = semi[1];
        n2 = semi[2];
        n3 = semi[3];
    }
    
    switch(ref.orient) {
        case HORZ : // flat up
            drawLabel(xp + gHop*3/2-10*gZoom,yp-10*gZoom,name,highlight);
            if(semi != NULL) {
                int x1 = xp-3*gZoom;
                int x2 = xp+18*gZoom;
                int x3 = xp+40*gZoom;
                int y = yp+4*gZoom;
                name[1] = 0;
                name[0] = n3;   GText(x1,y,name);
                name[0] = n2;   GText(x2,y,name);
                name[0] = n1;   GText(x3,y,name);
            }
            break;
        case HORZ2 : // flat down
            drawLabel(xp + gHop*3/2-10*gZoom,yp-20*gZoom,name,highlight);
            if(semi != NULL) {
                int x1 = xp-3*gZoom;
                int x2 = xp+18*gZoom;
                int x3 = xp+40*gZoom;
                int y = yp-14*gZoom;
                name[1] = 0;
                name[0] = n1;   GText(x1,y,name);
                name[0] = n2;   GText(x2,y,name);
                name[0] = n3;   GText(x3,y,name);
            }
            break;
        case VERT : // flat right
            drawLabel(xp-10*gZoom,yp+11*gZoom,name,highlight);
            if(semi != NULL) {
                int x = xp-13*gZoom;
                int y1 = yp-05*gZoom;
                int y2 = yp+17*gZoom;
                int y3 = yp+39*gZoom;
                name[1] = 0;
                name[0] = n3;   GText(x,y1,name);
                name[0] = n2;   GText(x,y2,name);
                name[0] = n1;   GText(x,y3,name);
            }
            break;
        case VERT2 : // flat left
            drawLabel(xp+10*gZoom,yp+11*gZoom,name,highlight);
            if(semi != NULL) {
                int x = xp+5*gZoom;
                int y1 = yp-05*gZoom;
                int y2 = yp+17*gZoom;
                int y3 = yp+39*gZoom;
                name[1] = 0;
                name[0] = n3;   GText(x,y3,name);
                name[0] = n2;   GText(x,y2,name);
                name[0] = n1;   GText(x,y1,name);
            }
            break;
    }
}

void drawTrimmer(int index)
{
    CircuitEntry &ref = q.circuit[index];
    bool highlight = isHighlighted(index);
    float xp = xcoord(ref);
    float yp = ycoord(ref);
    float xs = gHop * 2;
    float ys = gHop * 2;
    float gs = gHop / 2;
    float gs2= gHop * 1.5;
    
    setHighlightFillColor(tranColor,highlight);
    setHighlightStrokeColor(index);
    
    if(!justLabels) {
        GClearPath();
        
        switch(ref.orient) {
            case HORZ : // flat up
            if(viewStyle != VIEWSTYLE_TRACE) {
                GMoveTo(xp-gs,yp+gHop);
                GLineTo(xp-gs,yp-gs);
                GLineTo(xp+xs+gs,yp-gs);
                GLineTo(xp+xs+gs,yp+gHop);
                GAddArc(xp+xs/2,yp+gHop,gs2,0,180);
                setHighlightFillColor(tranColor2,highlight);
                GFill();
                GStroke();
            }
                drawPin(ref,0,0,highlight);
                drawPin(ref,1,2,highlight);
                drawPin(ref,2,0,highlight);
                break;
            case HORZ2 : // flat down
                if(viewStyle != VIEWSTYLE_TRACE) {
                    GMoveTo(xp+xs+gs,yp-gHop);
                    GLineTo(xp+xs+gs,yp+gs);
                    GLineTo(xp-gs,yp+gs);
                    GLineTo(xp-gs,yp-gHop);
                    GAddArc(xp+xs/2,yp-gHop,gs2,180,360);
                    setHighlightFillColor(tranColor2,highlight);
                    GFill();
                    GStroke();
                }
                drawPin(ref,0,0,highlight);
                drawPin(ref,1,-2,highlight);
                drawPin(ref,2,0,highlight);
                break;
            case VERT : // flat right
                if(viewStyle != VIEWSTYLE_TRACE) {
                    GMoveTo(xp-gHop,yp-gs);
                    GLineTo(xp+gs,yp-gs);
                    GLineTo(xp+gs,yp+ys+gs);
                    GAddArc(xp-gHop,yp+ys/2,gs2,90,270);
                    setHighlightFillColor(tranColor2,highlight);
                    GFill();
                    GStroke();
                }
                drawPin(ref,0,0,highlight);
                drawPin(ref,-2,1,highlight);
                drawPin(ref,0,2,highlight);
                break;
            case VERT2 : // flat left
                if(viewStyle != VIEWSTYLE_TRACE) {
                    GMoveTo(xp+gHop,yp+ys+gs);
                    GLineTo(xp-gs,yp+ys+gs);
                    GLineTo(xp-gs,yp-gs);
                    GLineTo(xp+gHop,yp-gs);
                    GAddArc(xp+gHop,yp+ys/2,gs2,270,90);
                    setHighlightFillColor(tranColor2,highlight);
                    GFill();
                    GStroke();
                }
                drawPin(ref,0,0,highlight);
                drawPin(ref,2,1,highlight);
                drawPin(ref,0,2,highlight);
                break;
        }
    }
    // name -----------------------------
    if(viewStyle == VIEWSTYLE_TRACE) return;
    
    GStrokeColor((highlight || !highlightCount) ? [NSColor blackColor] : [NSColor darkGrayColor]);
    
    switch(ref.orient) {
        case HORZ : // flat up
            drawLabel(xp + gHop*3/2-10*gZoom,yp-10*gZoom+gHop*3/2,ref.name,highlight);
            break;
        case HORZ2 : // flat down
            drawLabel(xp + gHop*3/2-10*gZoom,yp-20*gZoom,ref.name,highlight);
            break;
        case VERT : // flat right
            drawLabel(xp-10*gZoom-gHop/4,yp+11*gZoom+gHop/2,ref.name,highlight);
            break;
        case VERT2 : // flat left
            drawLabel(xp+10*gZoom+gHop/4,yp+11*gZoom+gHop/2,ref.name,highlight);
            break;
    }
}

void drawChip(int index)
{
    char str[16];
    CircuitEntry &ref = q.circuit[index];
    bool highlight = isHighlighted(index);
    
    int xp = xcoord(ref);
    int yp = ycoord(ref);
    int height = 0;
    int chipWidth = 3;
    
    if(ref.kind == KIND_C40) {
        height = 19;
        chipWidth = 6;
    }
    else
        height = chipHeight[ref.kind];
    
    int xs = gHop * chipWidth;
    int ys = gHop * height;
    
    if(ref.orient == HORZ || ref.orient == HORZ2) {
        xs = gHop * height;
        ys = gHop * chipWidth;
    }
    
    xs += gOffset;
    ys += gOffset;
    
    setHighlightFillColor(chipColor,highlight);
    setHighlightStrokeColor(index);
    
    if(!justLabels) {
        if(viewStyle != VIEWSTYLE_TRACE) {
            int x2,y2;
            float sz = xs/4;
            setHighlightFillColor(chipColor2,highlight);
            GFilledRectangle(xp-gOffset+1,yp-gOffset+1,xs+gOffset-2,ys+gOffset-2);
            GClearPath();
            
            switch(ref.orient) {
                case VERT :
                    x2 = xp - gOffset +xs/3;
                    y2 = yp - gOffset+1;
                    GMoveTo(x2,y2);
                    GAddArc(x2+sz,y2,sz,0,180);
                    break;
                case VERT2 :
                    x2 = xp - gOffset + xs/3;
                    y2 = yp + ys-1;
                    GMoveTo(x2,y2);
                    GAddArc(x2+sz,y2,sz,180,0);
                    break;
                case HORZ :
                    sz = ys/4;
                    x2 = xp - gOffset;
                    y2 = yp - gOffset + ys/3;
                    GMoveTo(x2,y2);
                    GAddArc(x2,y2+sz,sz,270,90);
                    break;
                case HORZ2 :
                    sz = ys/4;
                    x2 = xp + xs;
                    y2 = yp + ys/3 + gOffset/2;
                    GMoveTo(x2,y2);
                    GAddArc(x2,y2,sz,90,270);
                    break;
            }
            
            GStroke();
        }
    }
	
	if(state == STATE_LOOK) return;
	
    int xx = ref.pt.x + sX;
    
    switch(ref.orient) {
        case VERT :
            if(!justLabels) {
                for(int i=0;i<=height;++i) {
                    if(!justLabels) {
                        drawPin(ref,0,i,highlight,i==0);
                        drawPin(ref,chipWidth,i,highlight);
                        
                        if(viewStyle == VIEWSTYLE_DESIGN) {
                            int x = scrollX+xx*gHop+8*gZoom;
                            int y = scrollY+(ref.pt.y+i)*gHop-6*gZoom;
                            
                            sprintf(str,"%d",i+1);
                            GSmallText(x,y,str);
                            
                            sprintf(str,"%d",(height+1) * 2 - i);
                            GSmallText(x + (chipWidth-1)*gHop,y,str);
                        }
                    }
                }
            }
            drawLabel(xp + xs/2,yp + gHop * height/2 - gHop/2,ref.name,highlight);
            break;
        case VERT2 :
            if(!justLabels) {
                for(int i=0;i<=height;++i) {
                    drawPin(ref,chipWidth,height-i,highlight,i==0);
                    drawPin(ref,0,height-i,highlight);
                    
                    if(viewStyle == VIEWSTYLE_DESIGN) {
                        int x = scrollX+xx*gHop+8*gZoom;
                        int y = scrollY+(ref.pt.y+height-i)*gHop-6*gZoom;
                        
                        sprintf(str,"%d",(height+1) * 2 - i);
                        GSmallText(x,y,str);
                        
                        sprintf(str,"%d",i+1);
                        GSmallText(x + (chipWidth-1)*gHop,y,str);
                    }
                }
            }
            drawLabel(xp + xs/2+5,yp + gHop * height/2 - gHop/2,ref.name,highlight);
            break;
        case HORZ :
            if(!justLabels) {
                for(int i=0;i<=height;++i) {
                    drawPin(ref,i,0,highlight);
                    drawPin(ref,i,chipWidth,highlight,i==0);
                    
                    if(viewStyle == VIEWSTYLE_DESIGN) {
                        int x = scrollX+(xx+i)*gHop-6*gZoom;
                        int y = scrollY+(ref.pt.y + chipWidth)*gHop-18*gZoom;
                        
                        //if(ref.kind == KIND_C40) y -= gHop*2;
                        
                        sprintf(str,"%d",i+1);
                        GSmallText(x,y,str);
                        
                        sprintf(str,"%d",(height+1) * 2 - i);
                        GSmallText(x,y-gHop*(chipWidth-1),str);
                    }
                }
            }
            drawLabel(xp + gHop * height/2,yp + ys/2+2,ref.name,highlight);
            break;
        case HORZ2 :
            if(!justLabels) {
                for(int i=0;i<=height;++i) {
                    drawPin(ref,i,0,highlight,i==height);
                    drawPin(ref,i,chipWidth,highlight);
                    
                    if(viewStyle == VIEWSTYLE_DESIGN) {
                        int x = scrollX+(xx+i)*gHop-6*gZoom;
                        int y = scrollY+(ref.pt.y + chipWidth)*gHop-18*gZoom;
                        
                        sprintf(str,"%d",-(height- (height+1) * 2 - i));
                        GSmallText(x,y,str);
                        
                        sprintf(str,"%d",height- i+1);
                        GSmallText(x,y-gHop*(chipWidth-1),str);
                    }
                }
            }
            drawLabel(xp + gHop * height/2,yp + ys/2+2,ref.name,highlight);
            break;
    }
}

void drawCircuit()
{
    int xx,yy;
    
    for(int i=0;i<q.count;++i) {
        CircuitEntry &ref = q.circuit[i];
        
        if(ref.kind == KIND_DELETED) continue;
        
        bool highlight = isHighlighted(i);
        
        switch(ref.kind) {
            case KIND_NODE :
                if(!justLabels)
                    drawNode(i);
                xx = scrollX + (ref.pt.x + sX) * gHop;
                yy = scrollY + ref.pt.y * gHop;
                drawLabel(xx - 20,yy - 15,ref.name,highlight,xx,yy);
                break;
            case KIND_GROUND :
                drawGroundNode(i);
                break;
            case KIND_RES :
                drawResistor(i);
                break;
            case KIND_CAP :
                drawCapacitor(i);
                break;
            case KIND_ECAP :
                drawECapacitor(i);
                break;
            case KIND_TRANSISTOR :
                drawTransistor(i);
                break;
            case KIND_WAYPOINT :
                drawWaypoint(i);
                break;
            case KIND_LEGEND :
                drawLegend(i);
                break;
            case KIND_C8  :
            case KIND_C14 :
            case KIND_C16 :
            case KIND_C40 :
                drawChip(i);
                break;
            case KIND_POWER :
                drawPower(i);
                break;
            case KIND_OPAMP :
                drawOpAmp(ref,highlight);
                break;
            case KIND_POT :
                drawPot(i);
                break;
            case KIND_INVERTER :
                drawInverter(ref,highlight);
                break;
            case KIND_XOR :
                drawXOR(ref,highlight);
                break;
            case KIND_DIODE :
                drawDiode(i);
                break;
            case KIND_TRIMMER :
                drawTrimmer(i);
                break;
        }
    }
    
//    // over-draw rounded waypoints
//    for(int i=0;i<q.count;++i) {
//        CircuitEntry &ref = q.circuit[i];
//
//        if(ref.kind != KIND_WAYPOINT) continue;
//        if(ref.orient == SHARP) continue;
//
//        drawCurvedWaypoint(i);
//    }
	
}

