//
//  library.h
//  Circuit
//
//  Created by Harry Kosalos on 6/16/16.
//  Copyright © 2016 Harry Kosalos. All rights reserved.
//

#ifndef library_h
#define library_h

void drawLine(int x1,int y1,int x2,int y2)
{
    NSPoint np1,np2;
    np1.x = x1;
    np1.y = y1;
    np2.x = x2;
    np2.y = y2;
    
    [path removeAllPoints];
    [path moveToPoint:np1];
    [path lineToPoint:np2];
    [path stroke];
}

void drawRectangle(int x1,int y1,int x2,int y2)
{
    [path removeAllPoints];
    [path moveToPoint:NSMakePoint(x1,y1)];
    [path lineToPoint:NSMakePoint(x2,y1)];
    [path lineToPoint:NSMakePoint(x2,y2)];
    [path lineToPoint:NSMakePoint(x1,y2)];
    [path closePath];
    [path stroke];
}

void drawFilledRectangle(int x1,int y1,int x2,int y2)
{
    [path removeAllPoints];
    [path moveToPoint:NSMakePoint(x1,y1)];
    [path lineToPoint:NSMakePoint(x2,y1)];
    [path lineToPoint:NSMakePoint(x2,y2)];
    [path lineToPoint:NSMakePoint(x1,y2)];
    [path closePath];
    
    [path fill];
    [path stroke];
}

void drawFilledOval(int x1,int y1,int xs,int ys)
{
    [path removeAllPoints];
    NSRect rect = NSMakeRect(x1,y1,xs,ys);
    
    [path removeAllPoints];
    [path appendBezierPathWithOvalInRect: rect];
    
    [path fill];
    [path stroke];
}

void drawText(int x,int y,const char *text)
{
    NSString *hws = [NSString stringWithFormat:@"%s",text];
    NSPoint p = NSMakePoint(x,y);
    NSMutableDictionary *attribs = [[NSMutableDictionary alloc] init];
    NSColor *c = [NSColor blackColor];
    NSFont *fnt = [NSFont fontWithName:@"Helvetica" size:12];
    
    [attribs setObject:c forKey:NSForegroundColorAttributeName];
    [attribs setObject:fnt forKey:NSFontAttributeName];
    [hws drawAtPoint:p withAttributes:attribs];
}

void drawTextCentered(int x,int y,const char *text)
{
    int length = (int)strlen(text);
    drawText(x-length*4,y-9,text);
}

void drawGrid()
{
    int x;
    [[NSColor grayColor] set];
    
    for(x=0;x<=WINDOW_XS;x+=HOP)
        drawLine(x,0,x,WINDOW_YS);
    for(x=0;x<=WINDOW_YS;x+=HOP)
        drawLine(0,x,WINDOW_XS,x);
}

void drawWaypoint(int x,int y)
{
    int xp = x * HOP;
    int yp = y * HOP;
    
    [[NSColor blueColor] set];
    drawFilledRectangle(xp,yp,xp+5,yp+5);
}

void drawNode(int x,int y)
{
    int xp = x * HOP - NODE_RADIUS/2;
    int yp = y * HOP - NODE_RADIUS/2;
    
    [[NSColor blackColor] setFill];
    
    NSRect rect = NSMakeRect(xp,yp,NODE_RADIUS,NODE_RADIUS);
    
    [path removeAllPoints];
    [path appendBezierPathWithOvalInRect: rect];
    [path fill];
}

void drawGroundNode(int x,int y)
{
    int xp = x * HOP - NODE_RADIUS/2;
    int yp = y * HOP - NODE_RADIUS/2;
    
    [[NSColor greenColor] setFill];
    [[NSColor blackColor] setStroke];
    
    NSRect rect = NSMakeRect(xp,yp,NODE_RADIUS,NODE_RADIUS);
    
    [path removeAllPoints];
    [path appendBezierPathWithOvalInRect: rect];
    [path fill];
    [path stroke];
}

void drawResistor(CircuitEntry &ref)
{
    int xp = ref.x * HOP;
    int yp = ref.y * HOP;
    
    [resColor setFill];
    [[NSColor blackColor] setStroke];
    
    if(ref.orient == HORZ) {
        int xs = HOP * 3;
        int ys = HOP * 0;
        drawFilledRectangle(xp-OFFSET,yp-OFFSET,xp+xs+OFFSET,yp+ys+OFFSET);
        drawNode(ref.x,ref.y);
        drawNode(ref.x+3,ref.y);
        drawText(xp + xs/2-10,yp-8,ref.name);
    } else {
        int xs = HOP * 0;
        int ys = HOP * 3;
        drawFilledRectangle(xp-OFFSET,yp-OFFSET,xp+xs+OFFSET,yp+ys+OFFSET);
        drawNode(ref.x,ref.y);
        drawNode(ref.x,ref.y+3);
        drawText(xp-8,yp+ys/2-10,ref.name);
    }
}

void drawCapacitor(CircuitEntry &ref)
{
    int xp = ref.x * HOP;
    int yp = ref.y * HOP;
    
    [capColor setFill];
    [[NSColor blackColor] setStroke];
    
    if(ref.orient == HORZ) {
        int xs = HOP * 7 / 2;
        int ys = HOP/2;
        drawFilledOval(xp-OFFSET,yp-OFFSET,xs+OFFSET,ys+OFFSET);
        drawNode(ref.x,ref.y);
        drawNode(ref.x+3,ref.y);
        drawText(xp + xs/2-10,yp-8,ref.name);
    } else {
        int xs = HOP/2;
        int ys = HOP * 7 / 2;
        drawFilledOval(xp-OFFSET,yp-OFFSET,xs+OFFSET,ys+OFFSET);
        drawNode(ref.x,ref.y);
        drawNode(ref.x,ref.y+3);
        drawText(xp-8,yp+ys/2-10,ref.name);
    }
}

void drawTransistor(CircuitEntry &ref)
{
    int xp = ref.x * HOP;
    int yp = ref.y * HOP;
    
    [resColor setFill];
    [[NSColor blueColor] setStroke];
    
    if(ref.orient == HORZ) {
        int xs = HOP * 2;
        int ys = HOP * 0;
        drawFilledRectangle(xp-OFFSET,yp-OFFSET,xp+xs+OFFSET,yp+ys+OFFSET);
        
        yp = yp+ys+OFFSET;
        [path removeAllPoints];
        [path moveToPoint:NSMakePoint(xp-OFFSET,yp)];
        [path lineToPoint:NSMakePoint(xp+xs+OFFSET,yp)];
        yp += HOP;
        [path lineToPoint:NSMakePoint(xp+xs-5,yp)];
        [path lineToPoint:NSMakePoint(xp+5,yp)];
        [path closePath];
        [path fill];
        [path stroke];
        
        drawNode(ref.x,ref.y);
        drawNode(ref.x+1,ref.y);
        drawNode(ref.x+2,ref.y);
        drawText(xp + HOP*3/2-20,yp-18,ref.name);
    } else {
        int xs = HOP * 0;
        int ys = HOP * 2;
        drawFilledRectangle(xp-OFFSET,yp-OFFSET,xp+xs+OFFSET,yp+ys+OFFSET);
        
        xp = xp+xs+OFFSET;
        [path removeAllPoints];
        [path moveToPoint:NSMakePoint(xp,yp-OFFSET)];
        [path lineToPoint:NSMakePoint(xp,yp+ys+OFFSET)];
        xp += HOP;
        [path lineToPoint:NSMakePoint(xp,yp+ys-5)];
        [path lineToPoint:NSMakePoint(xp,yp+5)];
        [path closePath];
        [path fill];
        [path stroke];
        
        drawNode(ref.x,ref.y);
        drawNode(ref.x,ref.y+1);
        drawNode(ref.x,ref.y+2);
        drawText(xp-12,yp+ys/2-5,ref.name);
    }
}

void drawChip(CircuitEntry &ref)
{
    int xp = ref.x * HOP;
    int yp = ref.y * HOP;
    int xs = HOP * 3;
    int height = chipHeight[ref.kind];
    int ys = HOP * height;
    
    [chipColor setFill];
    [[NSColor blackColor] setStroke];
    drawFilledRectangle(xp-OFFSET,yp-OFFSET,xp+xs+OFFSET,yp+ys+OFFSET);
    
    for(int i=0;i<=height;++i) {
        drawNode(ref.x,ref.y+i);
        drawNode(ref.x+3,ref.y+i);
    }
    
    drawTextCentered(xp + xs/2,yp + HOP * height/2,ref.name);
}

#pragma mark --------------

void addCircuitEntry(CircuitEntry &ref)
{
    if(q.cCount < MAX_CIRCUIT_ENTRY) {
        q.circuit[q.cCount] = ref;
        q.cIndex = q.cCount++;
    }
}


void addConnection(ConnectionData &ref)
{
    if(q.conCount < MAX_CONNECTIONS) {
        q.connection[q.conCount] = ref;
        ++q.conCount;
    }
}

#pragma mark --------------

void drawCircuit()
{
    int xp=0,yp=0;
    
    for(int i=0;i<q.cCount;++i) {
        CircuitEntry &ref = q.circuit[i];
        switch(q.circuit[i].kind) {
            case KIND_NODE :
                drawNode(ref.x,ref.y);
                xp = ref.x * HOP - 20;
                yp = ref.y * HOP - 20;
                drawText(xp,yp,ref.name);
                break;
            case KIND_GROUND :
                drawGroundNode(ref.x,ref.y);
                break;
            case KIND_RES :
                drawResistor(ref);
                break;
            case KIND_CAP :
                drawCapacitor(ref);
                break;
            case KIND_TRANSISTOR :
                drawTransistor(ref);
                break;
            case KIND_WAYPOINT :
                drawWaypoint(ref.x,ref.y);
                break;
            case KIND_C8  :
            case KIND_C14 :
            case KIND_C16 :
                drawChip(ref);
                break;
        }
    }
}

#pragma mark --------------

NSPoint resistorNodePosition(CircuitEntry &cir,int pin)
{
    int xp = cir.x * HOP;
    int yp = cir.y * HOP;
    NSPoint pt = NSMakePoint(xp,yp);
    
    if(pin == 0) return pt;
    if(pin == 1) {
        if(cir.orient == HORZ) {
            pt.x += HOP*3;
            return pt;
        } else {
            pt.y += HOP*3;
            return pt;
        }
    }
    
    pt.x = NONE;
    return pt;
}

NSPoint transistorNodePosition(CircuitEntry &cir,int pin)
{
    int xp = cir.x * HOP;
    int yp = cir.y * HOP;
    NSPoint pt = NSMakePoint(xp,yp);
    
    if(pin == 0) return pt;
    if(pin == 1) {
        if(cir.orient == HORZ) {
            pt.x += HOP*1;
            return pt;
        } else {
            pt.y += HOP*1;
            return pt;
        }
    }
    if(pin == 2) {
        if(cir.orient == HORZ) {
            pt.x += HOP*2;
            return pt;
        } else {
            pt.y += HOP*2;
            return pt;
        }
    }
    
    pt.x = NONE;
    return pt;
}

NSPoint chipNodePosition(CircuitEntry &cir,int pin)
{
    int xp = cir.x * HOP;
    int yp = cir.y * HOP;
    NSPoint pt = NSMakePoint(xp,yp);
    int height = chipHeight[cir.kind];
    
    if(pin < 0 || pin >= height*2+2) {
        pt.x = NONE;
        return pt;
    }
    
    if(pin <= height) {
        pt.y += pin*HOP;
        return pt;
    }
    
    pt.x += HOP*3;
    pt.y += (height*2+1-pin)*HOP;
    return pt;
}

void drawConnection(ConnectionData &ref)
{
    NSPoint pt1,pt2;
    
    switch(q.circuit[ref.n1].kind) {
        case KIND_NODE :
        case KIND_GROUND :
        case KIND_WAYPOINT :
            pt1 = resistorNodePosition(q.circuit[ref.n1],0);
            break;
        case KIND_RES :
        case KIND_CAP :
            pt1 = resistorNodePosition(q.circuit[ref.n1],ref.p1);
            break;
        case KIND_TRANSISTOR :
            pt1 = transistorNodePosition(q.circuit[ref.n1],ref.p1);
            break;
        case KIND_C8  :
        case KIND_C14 :
        case KIND_C16 :
            pt1 = chipNodePosition(q.circuit[ref.n1],ref.p1);
            break;
    }
    
    switch(q.circuit[ref.n2].kind) {
        case KIND_NODE :
        case KIND_GROUND :
        case KIND_WAYPOINT :
            pt2 = resistorNodePosition(q.circuit[ref.n2],0);
            break;
        case KIND_RES :
        case KIND_CAP :
            pt2 = resistorNodePosition(q.circuit[ref.n2],ref.p2);
            break;
        case KIND_TRANSISTOR :
            pt2 = transistorNodePosition(q.circuit[ref.n2],ref.p2);
            break;
        case KIND_C8  :
        case KIND_C14 :
        case KIND_C16 :
            pt2 = chipNodePosition(q.circuit[ref.n2],ref.p2);
            break;
    }
    
    [path removeAllPoints];
    [path moveToPoint:pt1];
    [path lineToPoint:pt2];
    [path stroke];
    
    //    NSPoint pc,pw1,pw2;
    //    pc.x = (pt1.x + pt2.x)/2;
    //    pc.y = (pt1.y + pt2.y)/2;
    //    pw1 = pc;
    //    pw2 = pc;
    //
    //    [path moveToPoint:pt1];
    //
    //    if(fabs(pt1.x-pt2.x) > fabs(pt1.y-pt2.y)) {
    //        pw1.y = pt1.y;
    //        pw2.y = pt2.y;
    //    } else {
    //        pw1.x = pt1.x;
    //        pw2.x = pt2.x;
    //    }
    //
    //    [path moveToPoint:pt1];
    //    [path lineToPoint:pw1];
    //    [path lineToPoint:pw2];
    //    [path lineToPoint:pt2];
    //    [path stroke];
}

void drawConnections()
{
    [[NSColor redColor] set];
    [path setLineWidth:3];
    
    for(int i=0;i<q.conCount;++i)
        drawConnection(q.connection[i]);
    
    [path setLineWidth:1];
}


NSPoint connectionCenter(ConnectionData &ref)
{
    NSPoint pt1,pt2;
    
    switch(q.circuit[ref.n1].kind) {
        case KIND_NODE :
        case KIND_GROUND :
        case KIND_WAYPOINT :
            pt1 = resistorNodePosition(q.circuit[ref.n1],0);
            break;
        case KIND_RES :
        case KIND_CAP :
            pt1 = resistorNodePosition(q.circuit[ref.n1],ref.p1);
            break;
        case KIND_TRANSISTOR :
            pt1 = transistorNodePosition(q.circuit[ref.n1],ref.p1);
            break;
        case KIND_C8  :
        case KIND_C14 :
        case KIND_C16 :
            pt1 = chipNodePosition(q.circuit[ref.n1],ref.p1);
            break;
    }
    
    switch(q.circuit[ref.n2].kind) {
        case KIND_NODE :
        case KIND_GROUND :
        case KIND_WAYPOINT :
            pt2 = resistorNodePosition(q.circuit[ref.n2],0);
            break;
        case KIND_RES :
        case KIND_CAP :
            pt2 = resistorNodePosition(q.circuit[ref.n2],ref.p2);
            break;
        case KIND_TRANSISTOR :
            pt2 = transistorNodePosition(q.circuit[ref.n2],ref.p2);
            break;
        case KIND_C8  :
        case KIND_C14 :
        case KIND_C16 :
            pt2 = chipNodePosition(q.circuit[ref.n2],ref.p2);
            break;
    }
    
    pt1.x = (pt1.x + pt2.x)/2;
    pt1.y = (pt1.y + pt2.y)/2;
    return pt1;
}

#pragma mark --------------- File related

NSString *dataPath = @"/Users/harrykosalos/Circuit/";
NSString *previousName = @"name.circuit";

-(void)saveToFile :(NSURL *)url
{
    previousName = [url lastPathComponent];
    
    q.version = VERSION;
    NSString *path = [dataPath stringByAppendingString:[url lastPathComponent]];
    NSData *data = [NSData dataWithBytes:&q length:sizeof(Persist)];
    [data writeToFile:path atomically:YES];
}

-(void)readFromFile :(NSURL *)url
{
    previousName = [url lastPathComponent];
    
    NSString *path = [dataPath stringByAppendingString:[url lastPathComponent]];
    NSData *data = [NSData dataWithContentsOfFile:path];
    memcpy(&q,data.bytes,sizeof(Persist));
    
    if(q.version != VERSION)
        q.reset();
        
        [self setNeedsDisplay:TRUE];
}

- (IBAction)openDocument:(id)sender
{
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *url = [[panel URLs] objectAtIndex:0];
            [self readFromFile:url];
        }
    }];
}

- (IBAction)saveDocument:(id)sender
{
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setNameFieldStringValue:previousName];
    
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            [self saveToFile:[panel URL]];
        }
    }];
}

#pragma mark --------------- Config

//typedef struct {
//    int x,y;
//    PaintPosition p1,p2;
//} ConfigData;
//
//ConfigData config;
//
//NSString *configPath = @"/Users/harrykosalos/CNC/config.dat";
//
//-(void)configTest
//{
//    config.x = 12;
//    config.y = 13;
//    config.p1.x = 29;
//    config.p1.y = 30;
//    config.p2.x = 31;
//    config.p2.y = 32;
//
//    [self saveConfig];
//
//    config.x = 112;
//    config.y = 113;
//    config.p1.x = 229;
//    config.p1.y = 330;
//    config.p2.x = 431;
//    config.p2.y = 532;
//
//    [self loadConfig];
//
//    printf("Config %d,%d p1 %d,%d p2 %d,%d\n",
//           config.x,config.y,config.p1.x,config.p1.y,config.p2.x,config.p2.y);
//
//}
//
//-(void)saveConfig
//{
//    NSData *d = [NSData dataWithBytes:(Byte *)&config length: sizeof(config)];
//
//    [d writeToFile:configPath  atomically:YES];
//}
//
//-(void)loadConfig
//{
//    NSData *d =  [NSData dataWithContentsOfFile:configPath];
//
//    memcpy(&config,d.bytes,sizeof(config));
//}
//

#endif /* library_h */
