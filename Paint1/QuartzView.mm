
#import <CoreServices/CoreServices.h>
#import "QuartzView.h"
#import "ViewController.h"
#import "QuartzGraphics.h"
#import "CircuitEntry.h"
#import "Persist.h"
#import "DrawComponents.h"
#import "undo.h"
#import "RenameController.h"

QuartzView *quartzView = nil;

char viewStyle = VIEWSTYLE_DESIGN;
char pcbName[128];
bool isMouseDown  = false;
bool isZoom = false;
bool gridFlag = true;
bool justLabels = false;
bool eKeyDown = false;  // 'E' + wheel = resize resisters and caps
char recentName[NAME_WIDTH+1];
bool rotateView = false;
bool designStyle = false;
bool semiColonClip = false;

NSPoint pnt,basePoint;

ConnectionData globalConnection;
NSColor *resColor,*resColor2,*capColor,*capColor2,*chipColor,*chipColor2,*tranColor,*tranColor2,*seeThroughGrayColor;
NSColor *ecapColor,*diodeColor;

const NSString *stateLegends[] = {
    @"<M> Move",
    @"<C> Add Connections",
    @"<D> Delete object",
    @"<Q> Multi Select",
    @"<Arrows> Multi Move",
    @"<I> Connection Info",
    @"<L> Search Selected",
    @"<R> Mark as checked",
};

void refresh()
{
    [quartzView setNeedsDisplay:TRUE];
}

// ----------------------------------------------------------------

@implementation QuartzView

- (BOOL)acceptsFirstResponder { return YES; }
- (BOOL)isFlipped { return TRUE; }

- (void)awakeFromNib
{
    NSRect f = self.frame;
    f.size.width = 900;
    f.size.height = 1000;
    self.frame = f;
    
    pcbName[0] = 0;
}

-(void)reset
{
    pcbName[0] = 0;
    q.reset();
    newState(STATE_MOVE);
    refresh();
    
    strcpy(recentName,"None");
}

#pragma mark:::::::::::::::::::::::::::::::::::::::::::::::::

NSString *circuitName = @" ";

void newState(int s)
{
    state = s;
    connectState = CONNECTION_STATE_FIRST_PIN;
    
    if(state == STATE_CHECK) {
        memset(connectionData,0,sizeof(connectionData));
        memset(componentData,0,sizeof(componentData));
    }
    
    circuitName = lastFilename.lastPathComponent;
    if(circuitName == nil) circuitName = @" ";
    
    quartzView.statusLabel.stringValue =
    [NSString stringWithFormat:@"%@ (%d nodes, %d connections)     BoardSize: %.1f x %.1f\"     Name: %@",
     stateLegends[state],q.count,q.connectionCount,
     (float)bsz[boardSize].x/10.0f,(float)bsz[boardSize].y/10.0f,
     circuitName];
}

// ----------------------------------------------------------------
// exchange connection points on selected component (if resistor or cap)

void flipConnections()
{
    char &kind = q.circuit[q.index].kind;
    
    if(kind == KIND_RES ||
       kind == KIND_CAP ||
       kind == KIND_ECAP ||
       kind == KIND_DIODE) {
        for(int i=0;i<q.connectionCount;++i) {
            if(q.connection[i].node1 == q.index)
                q.connection[i].pin1 = 1 - q.connection[i].pin1;
            if(q.connection[i].node2 == q.index)
                q.connection[i].pin2 = 1 - q.connection[i].pin2;
        }
    }
}

// ----------------------------------------------------------------
// create copy of selected component. place it to the left of original

void clone()
{
    if(q.index != NONE) {
        CircuitEntry c = q.circuit[q.index];
        c.pt.x -= 4;
        
        addCircuitEntry(c,false);
    }
}

// ----------------------------------------------------------------
// they have multi-selected components.  Is the specifed connection point in the group?

bool isHighlightedConnectionPoint(int index)
{
    for(int i=0;i<highlightCount;++i)
        if(highlightIndex[i] == index)
            return true;
    
    return false;
}

// ----------------------------------------------------------------
// a clone group has been made. determine which cloned item is the copy of the specifed index

int clonedIndexOfComponent(int index)
{
    for(int i=0;i<highlightCount;++i)
        if(highlightIndex[i] == index)
            return highlightCloneIndex[i];
    
    return 0;
}

// ----------------------------------------------------------------
// they have multi-selected components, and have commanded to clone whole group.

void multiClone()
{
    CircuitEntry c;
    
    // clone all the selected components ---------
    for(int i=0;i<highlightCount;++i) {
        c = q.circuit[highlightIndex[i]];
        c.pt.x -= 10;
        addCircuitEntry(c,false);
        
        highlightCloneIndex[i] = q.newIndex;  // memorize the original's index
    }
    
    // clone all connections whose both ends are in the selected original group
    for(int i=0;i<q.connectionCount;++i) {
        if(isHighlightedConnectionPoint(q.connection[i].node1) &&
           isHighlightedConnectionPoint(q.connection[i].node2)) {
            
            globalConnection = q.connection[i];
            globalConnection.node1 = clonedIndexOfComponent(q.connection[i].node1);
            globalConnection.node2 = clonedIndexOfComponent(q.connection[i].node2);
            addConnection(globalConnection);
        }
    }
    
    // the newly created clone group becomes the selected items
    memcpy(highlightIndex,highlightCloneIndex,highlightCount * sizeof(int));
    
    refresh();
}

// ===============================================================
// search popup dialog session.  set 'selected items' group to just the components whose name matches

void search()
{
    static NSAlert *alert = nil;
    static NSTextField *input = nil;
    
    if(alert == nil) {
        alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Name to search for"];
        [alert addButtonWithTitle:@"Ok"];
        [alert addButtonWithTitle:@"Cancel"];
        
        input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
        [alert setAccessoryView:input];
    }
    
    [input setStringValue:@""];
    NSInteger button = [alert runModal];
    
    if(button == NSAlertFirstButtonReturn) {
        resetSelectedItemsList();
        
        for(int i=0;i<q.count;++i) {
            if(q.circuit[i].kind == KIND_DELETED) continue;
            
            if(strstr(q.circuit[i].name,input.stringValue.UTF8String) != NULL)
                toggleMultiSelectEntry(i);
        }
    }
}

// ===============================================================
// in <L> Look mode,  highlight all items whose name matches the selected component's

void searchSelected()
{
    if(q.index != NONE) {  // there IS a currently selected component
        resetSelectedItemsList();
        
        for(int i=0;i<q.count;++i) {
            if(q.circuit[i].kind == KIND_DELETED) continue;
            
            if(strstr(q.circuit[i].name,q.circuit[q.index].name) != NULL)
                toggleMultiSelectEntry(i);
        }
        
        refresh();
    }
}

// ===============================================================
// move components in selected items list

void move(int dx,int dy)
{
    if(state == STATE_MULTISELECT) { // transistion from selecting items to moving them
        newState(STATE_MULTIMOVE);
        pushUndo();
    }
    
    // the mult-select list is empty, but there is a currently select component
    // make him a 'group of one'
    if(highlightCount == 0 && q.index != NONE) {
        highlightIndex[0] = q.index;
        highlightCount = 1;
    }
    
    for(int i=0;i<highlightCount;++i) {
        q.circuit[highlightIndex[i]].pt.x += dx;
        q.circuit[highlightIndex[i]].pt.y += dy;
    }
    
    refresh();
}

#pragma mark:::::::::::::::::::::::::::::::::::::::::::::::::
#pragma mark Draw

NSColor *highlightColor(bool highlightStatus)
{
	if(viewStyle == VIEWSTYLE_JUMPER) return  seeThroughGrayColor;  //          [NSColor grayColor];

    // there IS a highlighted group. gray = Not part of group
    if(highlightCount)
        if(!highlightStatus) return seeThroughGrayColor; // [NSColor grayColor];
    
    return [NSColor blackColor];
}

NSColor *highlightColor(int index)
{
    if(viewStyle == VIEWSTYLE_JUMPER) return seeThroughGrayColor;//[NSColor grayColor];

    if(state == STATE_CHECK && componentData[index].selected) {
        GLineWidth(3);
        return [NSColor blueColor];
    }
    
    // there IS a highlighted group. gray = Not part of group
    if(highlightCount)
        if(!isHighlighted(index)) return seeThroughGrayColor;//[NSColor grayColor];
    
    if(index == q.index) { // single selected component has highlighted drawing
        GLineWidth(3);
        return [NSColor redColor];
    }
    
    return [NSColor blackColor];
}

void setHighlightStrokeColor(bool highlightStatus)
{
    GLineWidth(1);
    GStrokeColor(highlightColor(highlightStatus));
}

void setHighlightStrokeColor(int index)
{
    GLineWidth(1);
    GStrokeColor(highlightColor(index));
    
    if(viewStyle == VIEWSTYLE_JUMPER)  [seeThroughGrayColor set];
}

void setHighlightFillColor(NSColor *color,bool highlightStatus)
{
    GFillColor((!highlightCount || highlightStatus) ? color : seeThroughGrayColor);
}

// ==============================================================

void drawVia(int index)
{
    ConnectionData &ref = q.connection[index];
    NSPoint pt1 = q.circuit[ref.node1].nodePosition(ref.pin1);
    NSPoint pt2 = q.circuit[ref.node2].nodePosition(ref.pin2);
    
    [[NSColor redColor] set];
    
    GDashedLine(pt1,pt2);
}

// ==============================================================

void drawConnection(int index)
{
    ConnectionData &ref = q.connection[index];
    NSPoint pt1 = q.circuit[ref.node1].nodePosition(ref.pin1);
    NSPoint pt2 = q.circuit[ref.node2].nodePosition(ref.pin2);
    
    if(viewStyle == VIEWSTYLE_TRACE && ref.type == CONNECTION_TYPE_VIA) return;
    
    // horiz lines on PCB style have X coordinates tweaked to ensure solid line overlap
    if(viewStyle == VIEWSTYLE_TRACE) {
		const float AA = (5 * gZoom) - 1;
        if(pt1.y == pt2.y) {
            if(pt1.x < pt2.x) {
                pt1.x -= AA;
                pt2.x += AA;
            }
            else {
                pt1.x += AA;
                pt2.x -= AA;
            }
        }
    }
    
    if(state == STATE_CHECK && connectionData[index].selected) {
        GLineWidth(isZoom ? CONNECTION_WIDTH_DESIGN*3 : CONNECTION_WIDTH_DESIGN*2);
        [[NSColor blueColor] set];
    }
    else {
        if(state == STATE_INFO && connectionData[index].selected) {
            [[NSColor redColor] set];
            if(viewStyle != VIEWSTYLE_TRACE)
                GLineWidth(isZoom ? CONNECTION_WIDTH_DESIGN*5 : CONNECTION_WIDTH_DESIGN*2);
        }
        else {
            [[NSColor blackColor] set];
            
            // ground connections in Green
            if(!designStyle) {
                if((viewStyle != VIEWSTYLE_TRACE) && (q.circuit[ref.node1].kind == KIND_GROUND || q.circuit[ref.node2].kind == KIND_GROUND))
                    [[NSColor  greenColor] set];
            }
            
            if(highlightCount) {
                if(!isHighlightedConnectionPoint(q.connection[index].node1) ||
                   !isHighlightedConnectionPoint(q.connection[index].node2))
                    [seeThroughGrayColor set];
            }
        }
    }
    
    
    // via connections
    if(ref.type == CONNECTION_TYPE_VIA) {
        if(viewStyle == VIEWSTYLE_JUMPER) {
            [[NSColor blackColor] set];
            GLineWidth(isZoom ? CONNECTION_WIDTH_DESIGN*4 : CONNECTION_WIDTH_DESIGN*3);
            GBezierLine(pt1,pt2);
            
            GCalcColor(index);
            GLineWidth(isZoom ? CONNECTION_WIDTH_DESIGN*3 : CONNECTION_WIDTH_DESIGN*2);
            GBezierLine(pt1,pt2);
        }
        return;
    }
    
    if(viewStyle == VIEWSTYLE_JUMPER)  [seeThroughGrayColor set];
 
    GLine(pt1,pt2);
}

void drawJustVias()
{
    if(viewStyle != VIEWSTYLE_JUMPER) return;
    
    GLineWidth(isZoom ? CONNECTION_WIDTH_DESIGN*2 : CONNECTION_WIDTH_DESIGN);

    for(int i=0;i<q.connectionCount;++i) {
        if(q.connection[i].type == CONNECTION_TYPE_VIA)
            drawConnection(i);
    }
    
    GLineWidth(1);
}

void drawConnections()
{
    for(int i=0;i<q.connectionCount;++i) {
        switch(viewStyle) {
            case VIEWSTYLE_DESIGN :
            case VIEWSTYLE_CLEAR  :
            case VIEWSTYLE_JUMPER  :
                GLineWidth(isZoom ? CONNECTION_WIDTH_DESIGN*2 : CONNECTION_WIDTH_DESIGN);
                break;
            case VIEWSTYLE_TRACE :
                GLineWidth(isZoom ? CONNECTION_WIDTH_PCB*2 : CONNECTION_WIDTH_PCB);
                break;
        }
        
        drawConnection(i);
    }

    // just Vias
    for(int i=0;i<q.connectionCount;++i) {
        if(viewStyle == VIEWSTYLE_JUMPER) {
            if(q.connection[i].type == CONNECTION_TYPE_VIA)
                drawConnection(i);
        }
    }

    GLineWidth(1);
}

// tenths of inch
//int boardXS = 28,boardYS = 40; // small board
int boardXS = 38,boardYS = 45; // small board + 1" wider + 0.5" taller
//int boardXS = 38,boardYS = 59; // 1/4 OF 20x30 cm board

int boardSize = 0;
IPoint bsz[] = {
    28,40,  // small board
    38,45,  // small board + 1" wider + 0.5" taller
    38,59  // 1/4 OF 20x30 cm board
};

void drawGrid()
{
    if(gridFlag && viewStyle != VIEWSTYLE_TRACE) {
        [[NSColor lightGrayColor] set];
        GLineWidth(1);
        for(int x=scrollX;x<=scrollX+WINDOW_XS;x+=gHop) GLine(x,scrollY,x,scrollY+WINDOW_YS);
        for(int x=scrollY;x<=scrollY+WINDOW_YS;x+=gHop) GLine(scrollX,x,scrollX+WINDOW_XS,x);
    }
    
    [[NSColor blackColor] set];
    
    int bsx = 1 + sX,bsy = 2;
    int bex = bsx + bsz[boardSize].x;
    int bey = bsy + bsz[boardSize].y;
    int x1 = scrollX+bsx*gHop;
    int y1 = scrollY+bsy*gHop;
    
    GLineWidth(1);
    GRectangle(x1,y1,scrollX+bex*gHop,scrollY+bey*gHop);
    
    if(viewStyle == VIEWSTYLE_DESIGN) {
        [[NSColor blackColor] set];
        
        char str[60];
        strcpy(str,circuitName.UTF8String);
        char *p = strstr(str,".");
        if(p != NULL) *p = 0;
        
        GText(x1,y1-30,str); // circuit name in UL cornaerS
    }
}


- (void)drawRect2:(NSRect)dirtyRect
{
    // --------------------------------------------------
    // set cursor graphic according to program mode.
    [self resetCursorRects];
    static CGRect aRect = CGRectMake(0,0,WINDOW_XS,WINDOW_YS);
    NSCursor *aCursor = nil;
    
    switch(state) {
        case STATE_CONNECT :
            aCursor = (connectState == CONNECTION_STATE_FIRST_PIN) ? [NSCursor openHandCursor] : [NSCursor closedHandCursor];
            break;
        case STATE_VIA :
            aCursor = [NSCursor dragLinkCursor];
            break;
        case STATE_DELETE :
            aCursor = [NSCursor disappearingItemCursor];
            break;
        case STATE_INFO :
            aCursor = [NSCursor contextualMenuCursor];
            break;
        case STATE_LOOK :
            aCursor = [NSCursor pointingHandCursor];
            break;
        default :
            aCursor = [NSCursor arrowCursor];
            break;
    }
    
    [self addCursorRect:aRect cursor:aCursor];
    [aCursor set];
    
    // --------------------------------------------------
    static bool first = true;
    if(first) {
        first = false;
        
        quartzView = self;
        
        GInit();
        resColor  = [NSColor colorWithRed:0.7   green:0.5   blue:0.5 alpha:1];
        resColor2 = [NSColor colorWithRed:0.7   green:0.5   blue:0.5 alpha:0.3];
        capColor  = [NSColor colorWithRed:0.5   green:0.7   blue:0.5 alpha:1];
        capColor2 = [NSColor colorWithRed:0.5   green:0.7   blue:0.5 alpha:0.3];
        chipColor = [NSColor colorWithRed:0.5   green:0.5   blue:0.7 alpha:1];
        chipColor2= [NSColor colorWithRed:0.5   green:0.5   blue:0.7 alpha:0.3];
        tranColor = [NSColor colorWithRed:0.8   green:0.8   blue:0.6 alpha:1];
        tranColor2= [NSColor colorWithRed:0.8   green:0.8   blue:0.6 alpha:0.3];
        ecapColor = [NSColor colorWithRed:1     green:0     blue:0   alpha:0.3];
        diodeColor= [NSColor colorWithRed:1     green:1     blue:0   alpha:0.5];
		seeThroughGrayColor = [NSColor colorWithRed:0 green:0 blue:0 alpha:0.1];

        [self reset];
        q.openDocument();
    }
    
    [[NSColor whiteColor] set];
    GFilledRectangle(scrollX,scrollY,WINDOW_XS-scrollX,WINDOW_YS-scrollY);
    
    drawGrid();
    drawConnections();
    
    // draw twice.  1st = components + labels,  2nd = just the labels (so they are not obscured)
    justLabels = false;
    drawCircuit();
    
    if(viewStyle == VIEWSTYLE_DESIGN) {
        justLabels = true;
        drawCircuit();
    }
    
    // draw blue selection rectangle if they are selecting a region
    if(state == STATE_MULTISELECT && isMouseDown) {
        GStrokeColor([NSColor blueColor]);
        GClearPath();
        GLineWidth(2);
        GMoveTo(basePoint.x,basePoint.y);
        GLineTo(pnt.x,basePoint.y);
        GLineTo(pnt.x,pnt.y);
        GLineTo(basePoint.x,pnt.y);
        GClosePath();
        GStroke();
    }
    
    partsSummary();
    bom();
    drawPcbName();
    
    drawJustVias();
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
    //   [[NSGraphicsContext currentContext] setShouldAntialias:!(viewStyle == VIEWSTYLE_TRACE)];
    
    if(rotateView) {
        CGContextRef gc = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
        CGFloat xMid = CGRectGetMidX(rect);
        CGFloat yMid = CGRectGetMidY(rect);
        
        CGContextSaveGState(gc);
        CGContextTranslateCTM(gc, xMid, yMid);
        
        CGContextRotateCTM(gc, 90 * M_PI / 180);
        
        [self drawRect2:rect];
        
        CGContextRestoreGState(gc);
    }
    else {
        [self drawRect2:rect];
    }
}

#pragma mark:::::::::::::::::::::::::::::::::::::::::::::::::
#pragma partsSummary
// display names of all components for each row to the right of the board region

#define MAX_ITEMS 100    // max #components per row
#define MAX_ROWS 100    // max #rows on board

typedef struct {
    int iCount;
    int indices[MAX_ITEMS];
    int xp,yp;
    NSString *summary;
    bool addComma;
    
    void reset() { iCount = 0; summary = @""; }
    void resetSummaryString();
    void terminateSummaryString();
    void addComponent(int index);
    void display(int row);
    void displayFragment(NSColor *color);
} PartSummaryRowData;

void PartSummaryRowData::addComponent(int index)
{
    if(iCount >= MAX_ITEMS) return;
    
    CircuitEntry &c = q.circuit[index];
    if(c.kind == KIND_DELETED) return;
    if(c.kind == KIND_C8) return;
    if(c.kind == KIND_C14) return;
    if(c.kind == KIND_C16) return;
    if(c.kind == KIND_C40) return;
    if(c.kind == KIND_WAYPOINT) return;
    if(c.kind == KIND_LEGEND) return;
    if(!strlen(c.name)) {
        if(c.kind != KIND_DIODE)
            return;
    }
    
    // insert sort into storage by component kind, and then by X coordinate
    for(int i=0;i<iCount;++i) {
        if((c.kind < q.circuit[indices[i]].kind) || (c.kind == q.circuit[indices[i]].kind && c.pt.x < q.circuit[indices[i]].pt.x)) {
            for(int j=MAX_ITEMS-1;j>i;--j)
                indices[j] = indices[j-1];
            indices[i] = index;
            ++iCount;
            return;
        }
    }
    
    indices[iCount++] = index;
}

void PartSummaryRowData::resetSummaryString()
{
    summary = @"";
    addComma = false;
}

void PartSummaryRowData::terminateSummaryString()
{
    summary = [summary stringByAppendingString:@" "];
    addComma = false;
}

void PartSummaryRowData::displayFragment(NSColor *color)
{
    CGSize sz = stringSizeL(summary.UTF8String);
    int yc = yp - sz.height/2 - 4;
    
    GStrokeColor([NSColor clearColor]);
    GFillColor(color);
    GFilledRectangle(xp-2,yc,sz.width+4,sz.height);
    GStrokeColor([NSColor blackColor]);
    
    GTextL(xp,yc,summary.UTF8String);
    
    xp += stringSizeL(summary.UTF8String).width + 10;
    resetSummaryString();
}

NSColor *summaryColor[KIND_COUNT];

void PartSummaryRowData::display(int row)
{
    if(!iCount) return;
    
    xp = scrollX + 1 + (bsz[boardSize].x + sX + 2) * gHop;
    yp = scrollY + 2 + row * gHop;
    int currentKind = q.circuit[indices[0]].kind;
    
    resetSummaryString();
    
    for(int i=0;i<iCount;++i) {
        if(i > 0) {
            terminateSummaryString();
            displayFragment(summaryColor[currentKind]);
            currentKind = q.circuit[indices[i]].kind;
        }
        
        summary = [summary stringByAppendingString:[NSString stringWithUTF8String:q.circuit[indices[i]].summaryName()]];
    }
    
    terminateSummaryString();
    displayFragment(summaryColor[currentKind]);
}

PartSummaryRowData pSum[MAX_ROWS];

void partsSummary()
{
    if(summaryColor[0] == nil) {
        summaryColor[KIND_NODE] = tranColor2;
        summaryColor[KIND_TRANSISTOR] = tranColor2;
        summaryColor[KIND_RES] = resColor2;
        summaryColor[KIND_CAP] = capColor2;
        summaryColor[KIND_ECAP] = ecapColor;
        summaryColor[KIND_DIODE] = diodeColor;
        summaryColor[KIND_TRIMMER] = tranColor2;
        summaryColor[KIND_POT] = tranColor2;
        summaryColor[KIND_C8] = tranColor2;
        summaryColor[KIND_C14] = tranColor2;
        summaryColor[KIND_C16] = tranColor2;
        summaryColor[KIND_C40] = tranColor2;
    }
    
    for(int row=0;row<MAX_ROWS;++row) {
        PartSummaryRowData &s = pSum[row];
        
        s.reset();
        
        for(int i=0;i<q.count;++i) {
            if(q.circuit[i].kind == KIND_DELETED) continue;
            
            if(q.circuit[i].pt.y == row)
                s.addComponent(i);
        }
        
        s.display(row);
    }
}

#pragma mark:::::::::::::::::::::::::::::::::::::::::::::::::
#pragma BOM

enum {
    BOM_SHORT = 0,
    BOM_LONG,
    BOM_NONE
};

int bomStyle = BOM_SHORT;


#define MAX_BOM 200

typedef struct {
    char name[32];
    int kind;
    int count;
} BOMEntry;

typedef struct {
    int bCount;
    BOMEntry entry[MAX_ITEMS];
    int xp,yp;
    void build();
    void addComponent(int index);
    void display();
    void displayEntry(int index);
    bool nameOrder(int index);
} BomData;

void BomData::addComponent(int index)
{
    CircuitEntry &c = q.circuit[index];
    if(c.kind == KIND_DELETED) return;
    if(c.kind == KIND_WAYPOINT) return;
    if(c.kind == KIND_LEGEND) return;
    if(c.kind == KIND_POWER) return;
    if(c.kind == KIND_GROUND) return;
    
    if(bomStyle != BOM_LONG) {
        if(c.kind == KIND_C8) return;
        if(c.kind == KIND_C14) return;
        if(c.kind == KIND_C16) return;
        if(c.kind == KIND_C40) return;
        if(c.kind == KIND_NODE) return;
    }
    
    // already in list?
    bool found = false;
    for(int i=0;i<bCount;++i) {
        if(c.kind == entry[i].kind && !strcmp(c.summaryName(),entry[i].name)) {
            found = true;
            ++entry[i].count;
            break;
        }
    }
    
    if(!found) {
        if(bCount == MAX_BOM) return;
        
        entry[bCount].kind  = c.kind;
        strcpy(entry[bCount].name,c.summaryName());
        entry[bCount].count = 1;
        ++bCount;
    }
}

float resistorValue(const char *str) {
	float mult = 1;
	if(strstr(str,"K") != NULL) mult = 1000;
	if(strstr(str,"M") != NULL) mult = 1000000;
	return atof(str) * mult;
}

float capValue(const char *str) {
	float mult = 1; // for pico
	if(strstr(str,"n") != NULL || strstr(str,"N") != NULL) mult = 1000;
	if(strstr(str,"u") != NULL || strstr(str,"U") != NULL) mult = 1000000;
	return atof(str) * mult;
}

bool BomData::nameOrder(int i) {
    const char *n1 = entry[i].name;
    const char *n2 = entry[i+1].name;
	
	if(entry[i].kind == KIND_RES) return resistorValue(n1) < resistorValue(n2);
	if(entry[i].kind == KIND_CAP) return capValue(n1) < capValue(n2);

    return strcmp(n1,n2) <= 0;
}

void BomData::build()
{
    bCount = 0;
    
    for(int i=0;i<q.count;++i){
        if(q.circuit[i].kind == KIND_DELETED) continue;
        
        addComponent(i);
    }
    
    // sort by kind, then by name
    for(;;) {
        bool okay = true;
        for(int i=0;i<bCount-1;++i) {
            if(entry[i].kind > entry[i+1].kind) okay = false; else
                if((entry[i].kind == entry[i+1].kind) && !nameOrder(i)) okay = false;
            
            if(!okay) {
                BOMEntry t = entry[i];
                entry[i] = entry[i+1];
                entry[i+1] = t;
                okay = false;
            }
        }
        
        if(okay) break;
    }
}

void BomData::displayEntry(int index)
{
    char str[128];
    
    if(entry[index].count == 1)
        strcpy(str,entry[index].name);
    else
        sprintf(str,"%s (%d)",entry[index].name,entry[index].count);
    
    CGSize sz = stringSizeL(str);
    int yc = yp - sz.height/2 - 4;
    
    GStrokeColor([NSColor clearColor]);
    GFillColor(summaryColor[entry[index].kind]);
	GFilledRectangle(xp-2,yc,sz.width+4,sz.height);
    GStrokeColor([NSColor blackColor]);
    
    GTextL(xp,yc,str);
    yp += gHop;
}

void BomData::display()
{
    if(bomStyle == BOM_NONE) return;
    
    xp = scrollX + gHop;
    yp = scrollY + 2 * gHop;
    
    GStrokeColor([NSColor blackColor]);
    GTextL(xp,yp,"BOM");
    yp += gHop*2;
    
    for(int i=0;i<bCount;++i)
        displayEntry(i);
}

BomData bomData;

void bom()
{
    bomData.build();
    bomData.display();
}

#pragma mark:::::::::::::::::::::::::::::::::::::::::::::::::

void drawPcbName()
{
    if(viewStyle != VIEWSTYLE_TRACE) return;
    if(pcbName[0] == 0) return;
    
    [[NSColor blackColor] set];
    
    int bsx = 1 + sX,bsy = 2;
    int x1 = scrollX+bsx*gHop + bsz[boardSize].x*gHop - 5; // right edge
    int y1 = scrollY+bsy*gHop;
    
    GTextPCB(x1,y1,pcbName);
}

#pragma mark:::::::::::::::::::::::::::::::::::::::::::::::::

void addCircuitEntry(CircuitEntry &ref,bool launchNameEdit = true)
{
    int index = NONE;
    
    // any Deleted entry to reuse?
    for(int i=0;i<q.count;++i) {
        if(q.circuit[i].kind == KIND_DELETED) {
            index = i;
            break;
        }
    }
    
    // need to add new entry
    if(index == NONE) {
        if(q.count < MAX_CIRCUIT_ENTRY) {
            index = q.count;
            ++q.count;
        }
        else return; // no more room
    }
    
    //printf("Entry Index %d\n",index);
    
    q.circuit[index] = ref;
    q.newIndex = index;
    q.index = index;
    q.circuit[index].index = index;
    
    newState(STATE_MOVE);
    
    if(launchNameEdit)
        changeName();
}

void addConnection(ConnectionData &ref)
{
    if(ref.node1 == ref.node2 && ref.pin1 == ref.pin2)
        return; // degenerate
    
    if(q.connectionCount < MAX_CONNECTIONS)
        q.connection[q.connectionCount++] = ref;
}

#pragma mark:::::::::::::::::::::::::::::::::::::::::::::::::
#pragma mark multi select

// is specified entry in the highlight list?
bool isMultiSelected(int index)
{
    for(int i=0;i<highlightCount;++i)
        if(highlightIndex[i] == index)
            return true;
    
    return false;
}

// remove specified entry from the highlight list
void removeMultiSelected(int index)
{
    for(int i=0;i<highlightCount;++i) {
        if(highlightIndex[i] == index) {
            for(int j=i;j<highlightCount-1;++j)
                highlightIndex[j] = highlightIndex[j+1];
            --highlightCount;
            return;
        }
    }
}

// remove specified entry from the highlight list
void addMultiSelectEntry(int index)
{
    if(highlightCount < MAX_CIRCUIT_ENTRY) {
        if(!isMultiSelected(index))
            highlightIndex[highlightCount++] = index;
    }
}

// toggle specified entries' inclusion in the highlight list
void toggleMultiSelectEntry(int index)
{
    if(!isMultiSelected(index))
        addMultiSelectEntry(index);
    else
        removeMultiSelected(index);
}

// toggle all components inside the specified bounding box to the highlight list
void performMultiSelect(NSPoint p1,NSPoint p2)
{
    // bounding box stretched over desired compoents
    int x1 = (p1.x < p2.x) ? p1.x : p2.x;
    int x2 = (p1.x > p2.x) ? p1.x : p2.x;
    int y1 = (p1.y < p2.y) ? p1.y : p2.y;
    int y2 = (p1.y > p2.y) ? p1.y : p2.y;
    
    int xoff = scrollX + sX * gHop;
    x1 -= xoff; // graphics coordinates to logical coordinates
    x2 -= xoff;
    y1 -= scrollY;
    y2 -= scrollY;
    x1 /= gHop;
    x2 /= gHop;
    y1 /= gHop;
    y2 /= gHop;
    
    for(int x=x1;x<=x2;++x) {
        for(int y=y1;y<=y2;++y) {
            for(int i=0;i<q.count;++i) {
                if(q.circuit[i].kind == KIND_DELETED) continue;
                
                if(q.circuit[i].pt.x == x && q.circuit[i].pt.y == y) {
                    addMultiSelectEntry(i);
                }
            }
        }
    }
}

// ===========================================

void deleteConnection(int index)
{
    if(index < 0 || index >= q.connectionCount) return;
    
    for(int j=index;j<q.connectionCount-1;++j)
        q.connection[j] = q.connection[j+1];
    
    --q.connectionCount;
}

// ==========================================================
// return index of component closest to specifed graphic coordinate

int closestComponent(NSPoint pnt)
{
    float closestDistance = FAR_AWAY;
    int closestIndex = NONE;
    
    for(int i=0;i<q.count;++i) {
        if(q.circuit[i].kind == KIND_DELETED) continue;
        
        float d = hypotf(pnt.x - (scrollX + q.circuit[i].pt.x * gHop), pnt.y - (scrollY + q.circuit[i].pt.y * gHop));
        if(d < gHop*gZoom && d < closestDistance) {
            closestDistance = d;
            closestIndex = i;
        }
    }
    
    return closestIndex;
}

// -------------------------------------------

NSPoint pBest;

int closestConnection(NSPoint pnt)
{
    const float RMHOP = 0.05;
    float ratio,distance = FAR_AWAY;
    int iBest = NONE;
    
    for(int i=0;i<q.connectionCount;++i) {
        for(ratio = RMHOP;ratio < 1.0-RMHOP; ratio += RMHOP) {
            NSPoint lerp = q.connection[i].connectionLerp(ratio);
            
            float d = hypotf(pnt.x - lerp.x, pnt.y - lerp.y);
            if(d < distance) {
                distance = d;
                iBest = i;
                pBest = lerp;
            }
        }
    }
    
    if(distance > gHop)
        return NONE;
    
    return iBest;
}

void clickLineCenterToDelete(NSPoint pnt)
{
    int iBest = closestConnection(pnt);
    
    if(iBest != NONE) {
        pushUndo();
        deleteConnection(iBest);
        refresh();
    }
}

#pragma mark:::::::::::::::::::::::::::::::::::::::::::::::::
#pragma mark mouse

- (void)rightMouseDown:(NSEvent *)theEvent
{
    pnt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    //  pnt.x -= sX * gHop;
    
    //printf("Right mouse %d,%d\n",(int)pt.x,(int)pt.y);
    
    // toggle check status ----------------
    if(state == STATE_CHECK) {
        int index = closestConnection(pnt);
        if(index != NONE) {
            connectionData[index].toggleSelected();
            refresh();
        }
        return;
    }
    
    
    // delete existing waypoint
    // 1. did they click on a waypoint?
    float distance = FAR_AWAY;
    int iBest = NONE;
    
    for(int i=0;i<q.count;++i) {
        if((q.circuit[i].kind != KIND_WAYPOINT) && (q.circuit[i].kind != KIND_LEGEND)) continue;
        
        float d = hypotf(pnt.x - xcoord(q.circuit[i].pt.x), pnt.y - ycoord(q.circuit[i].pt.y));
        if(d < distance) {
            distance = d;
            iBest = i;
        }
    }
    
    // 2. yes. remove waypoint and connect nodes that it was in between
    if(distance < gHop) {
        // find two connection entries that refer to this waypoint
        int c1 = NONE,c2 = NONE,otherNode1=0,otherNode2=0,otherPin1=0,otherPin2=0;
        
        for(int i=0;i<q.connectionCount;++i) {
            if(q.connection[i].node1 == iBest) {
                if(c1 == NONE) {
                    c1 = i;
                    otherNode1 = q.connection[i].node2;
                    otherPin1 = q.connection[i].pin2;
                }
                else {
                    c2 = i;
                    otherNode2 = q.connection[i].node2;
                    otherPin2 = q.connection[i].pin2;
                }
            }
            if(q.connection[i].node2 == iBest) {
                if(c1 == NONE) {
                    c1 = i;
                    otherNode1 = q.connection[i].node1;
                    otherPin1 = q.connection[i].pin1;
                }
                else {
                    c2 = i;
                    otherNode2 = q.connection[i].node1;
                    otherPin2 = q.connection[i].pin1;
                }
            }
        }
        
//        printf("want to delete waypoint at Circuit index %d\n",iBest);
//        printf("two Con entries:\n");
//        printf("%d:  %d,%d - %d,%d\n",c1,q.connection[c1].node1,q.connection[c1].pin1,q.connection[c1].node2,q.connection[c1].pin2);
//        printf("%d:  %d,%d - %d,%d\n",c2,q.connection[c2].node1,q.connection[c2].pin1,q.connection[c2].node2,q.connection[c2].pin2);
//        printf("New connection: %d - %d\n",otherNode1,otherNode2);
        
        deleteCircuitObject(iBest,false);
        
        globalConnection.node1 = otherNode1;
        globalConnection.pin1 = otherPin1;
        globalConnection.node2 = otherNode2;
        globalConnection.pin2 = otherPin2;
        globalConnection.type = CONNECTION_TYPE_CONNECT;
        addConnection(globalConnection);
        
        refresh();
        return;
    }
    
    // add waypoint ---------------------------
    // they have right clicked on a connection line
    // walk the length of each existing connection line, hopping 5% at a time.
    // memorize the index of the connection line that has a point on it that is closest to the user click position
    iBest = closestConnection(pnt);
    
    // they clicked too far away from any connection line == 'clicking in air'
    // cycle roundrobin through move,connect,delete modes
    if(iBest == NONE) { // distance > gHop) {
        switch(state) {
            case STATE_MOVE :
                newState(STATE_CONNECT);
                break;
            case STATE_CONNECT :
                newState(STATE_DELETE);
                break;
            case STATE_DELETE :
                newState(STATE_MOVE);
                break;
        }
    }
    else {
        // they clicked on a connection line
        // 0. if the connection is a jumper then ignore
        // 1. delete connection line they clicked on
        // 2. add a waypoint at the place they clicked
        // 3. connect both old connection endpoints to new waypoint
        ConnectionData old = q.connection[iBest];
        
        if(old.type != CONNECTION_TYPE_VIA) {
            deleteConnection(iBest);
            
            CircuitEntry c;
            c.pt.x = (int)(pBest.x - scrollX)/gHop - sX;
            c.pt.y = (int)(pBest.y - scrollY)/gHop;
            c.orient = SHARP;
            c.kind = KIND_WAYPOINT;
            addCircuitEntry(c,false);
            
            globalConnection = old;
            globalConnection.node2 = q.newIndex;
            globalConnection.pin2 = 0;
            globalConnection.type = CONNECTION_TYPE_CONNECT;
            addConnection(globalConnection);
            
            globalConnection = old;
            globalConnection.node1 = q.newIndex;
            globalConnection.pin1 = 0;
            globalConnection.type = CONNECTION_TYPE_CONNECT;
            addConnection(globalConnection);
        }
    }
    
    refresh();
}

// ==========================================================

bool mouseWasMovedBetweenAddSessions = false;
int oldIndex;
bool isMouseMoving = false;

NSTimer *checkTimer = nil;
int checkLatch = 0;
-(void)resetCheckTimerLatch:(NSTimer *)timer { checkLatch = 0; }

- (void)mouseDown:(NSEvent *)theEvent
{
    mouseWasMovedBetweenAddSessions = true;
    
    NSPoint pntOrg = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    pnt = pntOrg;
    if(state == STATE_MOVE || state == STATE_CHECK  || state == STATE_LOOK)
        pnt.x -= sX * gHop;
    
    // toggle check status ----------------
    if(state == STATE_CHECK) {
        if(checkLatch == 0) {
            int index = closestComponent(pnt);
            if(index != NONE) {
                componentData[index].toggleSelected();
                refresh();
                checkLatch = 1;
                checkTimer = [NSTimer scheduledTimerWithTimeInterval:0.10 target:self selector:@selector(resetCheckTimerLatch:) userInfo:nil repeats:NO];
            }
        }
        return;
    }
    
    if(state == STATE_INFO) {
        highlightConnections();
        return;
    }
    
    if(state == STATE_DELETE) {
        float distance = FAR_AWAY;
        int iBest = NONE;
        
        for(int i=0;i<q.connectionCount;++i) {
            
            if(viewStyle == VIEWSTYLE_JUMPER && q.connection[i].type != CONNECTION_TYPE_VIA) continue;

            NSPoint center = q.connection[i].connectionCenter();
            
            float d = hypotf(pnt.x - center.x, pnt.y - center.y);
            if(d < distance) {
                distance = d;
                iBest = i;
            }
        }
        
        if(distance < gHop) {
            pushUndo();
            deleteConnection(iBest);
            refresh();
        }
        
        return;
    }
    
    if(state == STATE_CONNECT || state == STATE_VIA) {
        // determine closest pin
        float bestDistance = FAR_AWAY;
        int bestNode=0,bestPin=0;
        
        for(int i=0;i<q.count;++i) {
            if(q.circuit[i].kind == KIND_DELETED) continue;
            
            for(int p=0;p<q.circuit[i].numberPins();++p) {
                float d = q.circuit[i].distanceToPin(pnt,p);
                if(d < bestDistance) {
                    bestDistance = d;
                    bestNode = i;
                    bestPin = p;
                }
            }
        }
        
        // clicked in air = reset connectionion session
        if(bestDistance > gHop*gZoom) {
            connectState = CONNECTION_STATE_FIRST_PIN;
        }
        else {
            // first pin in the pair to connect
            if(connectState == CONNECTION_STATE_FIRST_PIN) {
                globalConnection.node1 = bestNode;
                globalConnection.pin1 = bestPin;
                ++connectState;
            }
            else {   // second pin
                globalConnection.node2 = bestNode;
                globalConnection.pin2 = bestPin;
                globalConnection.type = (state == STATE_CONNECT) ? CONNECTION_TYPE_CONNECT : CONNECTION_TYPE_VIA;
                addConnection(globalConnection);
                connectState = CONNECTION_STATE_FIRST_PIN;
                
                //printf("Connect pin2 = %d,%d\n",i,n);
            }
        }
        
        refresh();
        return;
    }
    
    if(state == STATE_MULTISELECT || state == STATE_MULTIMOVE) {
        basePoint = pnt;
        return;
    }
    
    // select component -------------------
    if(q.newIndex == NONE) {
        q.newIndex = closestComponent(pnt);
        
        //printf("Closest Index = %d (Q %d)\n",q.newIndex,q.index);
        
        if(q.newIndex == NONE) {  // click air == reset memory of last clicked component
            q.index = NONE;
            clickLineCenterToDelete(pntOrg);
            return;
        }
        
        if(q.newIndex != q.index) { // new selection
            oldIndex = q.index;
            q.index = q.newIndex;
            
            if(state == STATE_LOOK)
                searchSelected();
            else {
                isMouseDown  = true;
                basePoint = pnt;
            }
            
            refresh();
            return;
        }
    }
    
    if(state == STATE_MOVE && q.newIndex != NONE) {
        
        if(!isMouseMoving) {
            isMouseMoving = true;
            pushUndo();
        }
        
        pnt.x -= scrollX;
        pnt.y -= scrollY;
        q.circuit[q.newIndex].logicalCoord(pnt);
    }
    
    refresh();
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    pnt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    switch(state) {
        case STATE_INFO :
            highlightConnections();
            break;
        case STATE_MOVE :
            [self mouseDown:theEvent];
            return;
        case STATE_MULTISELECT :
            isMouseDown  = true;
            refresh();
            return;
        case STATE_MULTIMOVE :
            
            if(!isMouseMoving) {
                isMouseMoving = true;
                pushUndo();
            }
            
            int dx = (int)(pnt.x - basePoint.x)/gHop * 3/2;
            int dy = (int)(pnt.y - basePoint.y)/gHop * 3/2;
            
            if(dx || dy) {
                for(int i=0;i<q.count;++i) {
                    if(q.circuit[i].kind == KIND_DELETED) continue;
                    if(!isMultiSelected(i)) continue;
                    
                    q.circuit[i].pt.x += dx;
                    q.circuit[i].pt.y += dy;
                }
                
                basePoint = pnt;
            }
            
            refresh();
            break;
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if(state == STATE_MULTISELECT) {
        pnt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        performMultiSelect(basePoint,pnt);
        q.index = NONE;  // no indivdual selection any more
        refresh();
        return;
    }
    
    isMouseDown = false;
    isMouseMoving = false;
    q.index = q.newIndex;
    q.newIndex = NONE;
    
    setAllWaypointsSharp();
}

- (void)scrollWheel:(NSEvent *)theEvent
{
    int dirX = 0,dirY = 0;
    if(theEvent.deltaX < 0) dirX = -1; else if(theEvent.deltaX > 0) dirX = +1;
    if(theEvent.deltaY < 0) dirY = -1; else if(theEvent.deltaY > 0) dirY = +1;
    
    //printf("Scroll Wheel %f,%f,%f = %d,%d\n",theEvent.deltaX,theEvent.deltaY,theEvent.deltaZ,dirX,dirY);
    
    // 'E' + scrollWheel = change size of cap,resistor,diode
    if(eKeyDown && q.index != NONE) {
        q.circuit[q.index].changeSize(-dirY);
        refresh();
        return;
    }
    
    if(isZoom && q.newIndex == NONE)
        scroll(-dirX*2,-dirY*2);
}

// ----------------------------------------------------------------------------

void flipXcoordinatesOfMultiSelect()
{
    // 1. determine X coord range
    int x;
    int left = FAR_AWAY;
    int right = 0;
    
    for(int i=0;i<q.count;++i) {
        if(isMultiSelected(i)) {
            CircuitEntry &c = q.circuit[i];
            
            x = c.pt.x;
            if(x < left) left = x;
            
            if((c.kind == KIND_RES || c.kind == KIND_CAP  || c.kind == KIND_ECAP || c.kind == KIND_DIODE) && c.isHorz()) x += c.size;
            
            if(x > right) right = x;
        }
    }
    
    if(left == FAR_AWAY) return;
    
    for(int i=0;i<q.count;++i) {
        if(isMultiSelected(i)) {
            q.index = i;
            
            CircuitEntry &c = q.circuit[i];
            c.pt.x = left + (right - c.pt.x);
            
            if((c.kind == KIND_RES || c.kind == KIND_CAP || c.kind == KIND_ECAP || c.kind == KIND_DIODE) && c.isHorz()) {
                flipConnections();
                
                int r = c.pt.x + c.size;
                if(r > right) {
                    c.pt.x -= (r - right);
                }
            }
        }
    }
    
    refresh();
}

// ----------------------------------------------------------------------------
// in <I> info mode, they have clicked on a node.
// build a list of all pins/nodes 'connected' to this node by recursively searching the connections database.

#pragma mark:::::::::::::::::::::::::::::::::::::::::::::::::
#pragma mark highlightConnections

typedef struct {
    short node,pin;
} ConnectionDataStack;

ConnectionDataStack cds[MAX_CONNECTIONS];
int cdsCount = 0;

void addCDSEntry(int conIndex) {
    connectionData[conIndex].selected = true;
    connectionData[conIndex].tested = true;
    
    bool alreadyInList = false;
    for(int i=0;i<cdsCount;++i) {
        if(cds[i].node == q.connection[conIndex].node1 &&  cds[i].pin == q.connection[conIndex].pin1)
            alreadyInList = true;
    }
    if(!alreadyInList) {
        cds[cdsCount].node = q.connection[conIndex].node1;
        cds[cdsCount].pin = q.connection[conIndex].pin1;
        ++cdsCount;
    }
    
    alreadyInList = false;
    for(int i=0;i<cdsCount;++i) {
        if(cds[i].node == q.connection[conIndex].node2 &&  cds[i].pin == q.connection[conIndex].pin2)
            alreadyInList = true;
    }
    if(!alreadyInList) {
        cds[cdsCount].node = q.connection[conIndex].node2;
        cds[cdsCount].pin = q.connection[conIndex].pin2;
        ++cdsCount;
    }
}


void resetConnectionData()
{
    cdsCount = 0;       // reset connected items list
    memset(connectionData,0,sizeof(connectionData));
}

void highlightConnections()
{
    resetConnectionData();
    
    // clicked near a connection point? ----------------
    NSPoint pinPosition;
    float d,bestDistance = FAR_AWAY;
    int bestIndex = NONE;
    
    for(int i=0;i<q.connectionCount;++i) {
        for(int pin = 0;pin < MAX_PINS;++pin) {
            pinPosition = q.circuit[q.connection[i].node1].nodePosition(pin);
            if(pinPosition.x == NONE) continue;
            
            d = hypotf(pinPosition.x - pnt.x,pinPosition.y - pnt.y);
            if(d < bestDistance) {
                bestDistance = d;
                bestIndex = i;
            }
        }
        for(int pin = 0;pin < MAX_PINS;++pin) {
            pinPosition = q.circuit[q.connection[i].node2].nodePosition(pin);
            if(pinPosition.x == NONE) continue;
            
            d = hypotf(pinPosition.x - pnt.x,pinPosition.y - pnt.y);
            if(d < bestDistance) {
                bestDistance = d;
                bestIndex = i;
            }
        }
    }
    
    if(bestDistance > gHop) return;  // no.
    
    addCDSEntry(bestIndex);
    
    // walk connections, adding connected neighbors to the group
    for(;;) {
        bool addedEntry = false;
        
        for(int cdsIndex=0;cdsIndex<cdsCount;++cdsIndex) {
            for(int i=0;i<q.connectionCount;++i) {
                if(connectionData[i].tested) continue;
                
                if(cds[cdsIndex].node == q.connection[i].node1 &&  cds[cdsIndex].pin == q.connection[i].pin1) {
                    addCDSEntry(i);
                    addedEntry = true;
                }
                if(cds[cdsIndex].node == q.connection[i].node2 &&  cds[cdsIndex].pin == q.connection[i].pin2) {
                    addCDSEntry(i);
                    addedEntry = true;
                }
            }
        }
        
        if(!addedEntry) break;
    }
    
    refresh();
}

// ----------------------------------------------------------------------------

void autoResistorSuffix()
{
    CircuitEntry &c = q.circuit[q.index];
    if(c.kind != KIND_RES) return;
    if(strstr(c.name,"K") != NULL) return;
    if(strstr(c.name,"R") != NULL) return;
    if(strstr(c.name,"M") != NULL) return;
    if(strstr(c.name,"V") != NULL) return;  // Vactrol
    
    strcat(c.name,"K");
}

#pragma mark:::::::::::::::::::::::::::::::::::::::::::::::::
#pragma mark autoWiring

void autoWiring()
{
    // delete existing jumpers
    for(int j=q.connectionCount-1;j>=0;--j) {
        if(q.connection[j].type == CONNECTION_TYPE_VIA) {
            deleteConnection(j);
        }
    }
    
top:
    for(int i=0;i<q.count;++i) {
        CircuitEntry &ref = q.circuit[i];
        if(ref.kind != KIND_NODE) continue;
        if(ref.name[0] == 0) continue;          // node without a name
        
        bool hasWire = false;
        for(int j=0;j<q.connectionCount;++j) {
            if(q.connection[j].node1 == i || q.connection[j].node2 == i) {
                if(q.connection[j].type == CONNECTION_TYPE_VIA) {
                    hasWire = true;
                    break;
                }
            }
        }
        if(hasWire) continue;
        
        for(int j=i+1;j<q.count;++j) {
            CircuitEntry &ref2 = q.circuit[j];
            if(ref2.kind != KIND_NODE) continue;
            
            bool hasWire2 = false;
            for(int k=0;k<q.connectionCount;++k) {
                if(q.connection[k].node1 == j || q.connection[k].node2 == j) {
                    if(q.connection[k].type == CONNECTION_TYPE_VIA) {
                        hasWire2 = true;
                        break;
                    }
                }
            }
            if(hasWire2) continue;
            
            if(!strcmp(ref.name,ref2.name)) {
                globalConnection.node1 = i;
                globalConnection.pin1 = 0;
                globalConnection.node2 = j;
                globalConnection.pin2 = 0;
                globalConnection.type = CONNECTION_TYPE_VIA;
                addConnection(globalConnection);
                goto top;
            }
        }
    }
}

// ----------------------------------------------------------------------------

void changeName()
{
    if(q.index == NONE) return;
    
    renameString = q.circuit[q.index].name;
    [viewController performSegueWithIdentifier:@"renamePopover" sender:viewController];
}

void deleteCircuitObject(int index,bool askConfirmation = true)
{
    if(askConfirmation) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Delete Circuit Object?"];
        [alert addButtonWithTitle:@"Yes"];
        [alert addButtonWithTitle:@"No"];
        
        NSInteger button = [alert runModal];
        
        if(button != NSAlertFirstButtonReturn) return;
    }
    
    // also delete all connections that connected to this node
    bool deletionMade;
    for(;;) {
        deletionMade = false;
        
        for(int i=0;i<q.connectionCount;++i) {
            if(q.connection[i].node1 == index || q.connection[i].node2 == index) {
                for(int j=i;j<q.connectionCount-1;++j)
                    q.connection[j] = q.connection[j+1];
                --q.connectionCount;
                deletionMade = true;
            }
        }
        
        if(!deletionMade) break;
    }
    
    // leave deleted entry in the list, mark as available for re-use
    q.circuit[index].kind = KIND_DELETED;
    strcpy(q.circuit[index].name,"");
    q.newIndex = NONE;
    q.index = NONE;
}

void multiDelete()
{
    for(int i=0;i<q.count;++i) {
        if(isMultiSelected(i)) {
            deleteCircuitObject(i,false);
        }
    }
    
    refresh();
}

void becomeWaypoint()
{
    if(q.index != NONE) {
        CircuitEntry &ref = q.circuit[q.index];
        ref.kind = KIND_WAYPOINT;
        ref.name[0] = 0;
        ref.orient = SHARP;
        refresh();
    }
}

void cycleViewStyle()
{
    if(++viewStyle > VIEWSTYLE_TRACE)
        viewStyle = VIEWSTYLE_DESIGN;
}

void scroll(int dx,int dy)
{
    if(isZoom) {
        scrollX -= dx * gHop;
        scrollY -= dy * gHop;
        refresh();
    }
}

// ==========================================================

typedef struct {
    int count;
    int connectionCount;
    CircuitEntry circuit[MAX_CIRCUIT_ENTRY];
    ConnectionData connection[MAX_CONNECTIONS];
    
    void reset() { count = 0; connectionCount =0; }
} ClipboardData;

ClipboardData clip;

NSString *clipFilename = @"_clipData.dat";

void cutClipBoard()
{
    if(!highlightCount) return;
    
    clip.reset();
    
    // copy all selected components ---------
    for(int i=0;i<highlightCount;++i) {
        clip.circuit[clip.count] = q.circuit[highlightIndex[i]];
        highlightCloneIndex[i] = clip.count++;  // memorize where copy was made
    }
    
    // copy all connections whose both ends are in the selected original group
    for(int i=0;i<q.connectionCount;++i) {
        if(isHighlightedConnectionPoint(q.connection[i].node1) &&
           isHighlightedConnectionPoint(q.connection[i].node2)) {
            
            globalConnection = q.connection[i];
            globalConnection.node1 = clonedIndexOfComponent(q.connection[i].node1);
            globalConnection.node2 = clonedIndexOfComponent(q.connection[i].node2);
            
            clip.connection[clip.connectionCount++] = globalConnection;
        }
    }
    
    // save to file
    NSData *data = [NSData dataWithBytes:&clip length:sizeof(ClipboardData)];
    [data writeToFile:filePath(clipFilename) atomically:YES];
}

void pasteClipBoard()
{
    NSData *data = [NSData dataWithContentsOfFile:filePath(clipFilename)];
    if(data == nil) return;
    
    memcpy(&clip,data.bytes,sizeof(ClipboardData));
    
    resetSelectedItemsList();
    
    for(int i=0;i< clip.count; ++i) {
        addCircuitEntry(clip.circuit[i],false);
        toggleMultiSelectEntry(q.newIndex);  // highlight (and memorize where it was stored)
    }
    
    for(int i=0;i< clip.connectionCount; ++i) {
        globalConnection = clip.connection[i];
        globalConnection.node1 = highlightIndex[clip.connection[i].node1];
        globalConnection.node2 = highlightIndex[clip.connection[i].node2];
        globalConnection.type = CONNECTION_TYPE_CONNECT;
        addConnection(globalConnection);
    }
    
    refresh();
}

void emailTest()
{
    //    NSString *body = @"test body";
    //        NSArray *shareItems = @[body]; //@[body,imageA,imageB];
    //    NSSharingService *service = [NSSharingService sharingServiceNamed:NSSharingServiceNameComposeEmail];
    // //   service.delegate = quartzView;
    //    service.recipients=@[@"kosalos@cox.net"];
    //    service.subject = @"Test email from xcode"; //    [ NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"SLYRunner console",nil),currentDate];
    //    [service performWithItems:shareItems];
}

void changeZoom(int dir)
{
    if(!isZoom) return;
    
    gHop += dir * 2;
    if(gHop < GHOP) gHop = GHOP; else
        if(gHop > 100) gHop = 100;
}

void autoCurveWaypoint(int index)
{
    q.circuit[index].autoCurveWaypoint();
}

void setAllWaypointsSharp()
{
    for(int i=0;i<q.count;++i) {
        if(q.circuit[i].kind == KIND_WAYPOINT)
            autoCurveWaypoint(i);
    }
}

void copyPreviousName()
{
    strcpy(q.circuit[q.index].name,q.circuit[oldIndex].name);
    //            strcpy(recentName,q.circuit[q.index].name);
}


#pragma mark:::::::::::::::::::::::::::::::::::::::::::::::::
#pragma mark keyDown

bool shiftKeyDown = false;
bool ctrlKeyDown = false;

- (void)keyUp:(NSEvent *)event
{
    [super keyUp:event];
    eKeyDown = false;
}

- (void)keyDown:(NSEvent *)event
{
    [super keyDown:event];
    
    // printf("Keycode %d\n",[event keyCode]);
    
    shiftKeyDown = (event.modifierFlags & NSEventModifierFlagShift) != 0;
    ctrlKeyDown  = (event.modifierFlags & NSEventModifierFlagControl) != 0;
    
    switch([event keyCode]) {
        case 36 :  // Enter
            autoWiring();
            break;
        case 12 :  // Cmd Q
            if((event.modifierFlags & NSCommandKeyMask) != 0) exit(0);
            break;
        case 123 :  // Left arrow
            if(shiftKeyDown) scroll(-1,0); else move(-1,0);
            return;
        case 124 :  // Right arrow
            if(shiftKeyDown) scroll(+1,0); else move(+1,0);
            return;
        case 126 :  // Up arrow
            if(shiftKeyDown) scroll(0,-1); else move(0,-1);
            return;
        case 125 :  // Down arrow
            if(shiftKeyDown) scroll(0,+1); else move(0,+1);
            return;
    }
    
    int keyCode = (int)toupper([[event charactersIgnoringModifiers] UTF8String][0]);
    
    // multiple Add circuit sessions are offset down the screen, rather than stacking at initial position
    static IPoint addPosition;
    if(mouseWasMovedBetweenAddSessions) {
        addPosition.x = (int)pnt.x/gHop;
        addPosition.y = (int)pnt.y/gHop;
        mouseWasMovedBetweenAddSessions = false;
    }
    else {
        ++addPosition.x;
        ++addPosition.y;
    }
    
    // add when there is currently a single selected component
    if(q.index != NONE) {
        addPosition = q.circuit[q.index].pt;
        ++addPosition.x;
        ++addPosition.y;
    }
    
    CircuitEntry c;
    c.pt  = addPosition;
    
    switch(keyCode) {
        case '0' : // zero
            c.kind = KIND_POWER;
            addCircuitEntry(c,false);
            break;
        case '1' :
            c.kind = KIND_RES;
            addCircuitEntry(c);
            break;
        case '2' :
            c.kind = KIND_CAP;
            addCircuitEntry(c);
            break;
        case '@' :
            c.kind = KIND_ECAP;
            addCircuitEntry(c);
            break;
        case '3' :
            c.kind = KIND_NODE;
            addCircuitEntry(c);
            break;
        case '4' :
            c.kind = KIND_GROUND;
            addCircuitEntry(c,false);
            break;
        case '5' :
            c.kind = KIND_WAYPOINT;
            c.orient = SHARP;
            addCircuitEntry(c,false);
            break;
        case '6' :
            c.kind = KIND_TRANSISTOR;
            addCircuitEntry(c);
            break;
        case '7' :
            c.kind = KIND_C8;
            c.orient = VERT;
            addCircuitEntry(c);
            break;
        case '8' :
            c.kind = KIND_C14;
            c.orient = VERT;
            addCircuitEntry(c);
            break;
        case '9' :
            c.kind = KIND_C16;
            c.orient = VERT;
            addCircuitEntry(c);
            break;
        case '(' :
            c.kind = KIND_C40;
            c.orient = VERT;
            addCircuitEntry(c);
            break;
        case 'A' :
            if(highlightCount > 0)
                multiClone();
            else
                clone();
            autoWiring();
            break;
        case 'B' :
            if(++bomStyle > BOM_NONE) bomStyle= BOM_SHORT;
            break;
        case 'C' :
            if(shiftKeyDown)
                newState(STATE_VIA);
            else
                newState(STATE_CONNECT);
            connectState = CONNECTION_STATE_FIRST_PIN;
            break;
        case 'D' :
            c.kind = KIND_DIODE;
            addCircuitEntry(c,false);
            break;
        case 'E' :
            eKeyDown = true;
            break;
        case 'F' :
            if(q.index != NONE)
                q.circuit[q.index].flip();
            break;
        case 'G' :
			if(shiftKeyDown) {
				gridFlag = !gridFlag;
				break;
			}
            if(q.index != NONE)
                q.circuit[q.index].kind = KIND_GROUND;
            break;
        case 'H' :
            search();
            break;
        case 'I' :
            resetConnectionData();
            newState(STATE_INFO);
            break;
        case 'J' :
            flipXcoordinatesOfMultiSelect();
            break;
        case 'K' :
            break;
        case 'L' :
			resetSelectedItemsList();
			newState(state == STATE_LOOK ? STATE_MOVE : STATE_LOOK);
			if(state == STATE_LOOK && q.index != NONE)
				searchSelected();
            break;
        case 'M' :
            q.index = NONE;
            resetSelectedItemsList();
            newState(STATE_MOVE);
            break;
        case 'N' :
            if(ctrlKeyDown)
                copyPreviousName();
            else
                changeName();
            break;
        case 'O' :
            if(shiftKeyDown) {
                q.openDocument();
                break;
            }
            
            c.kind = KIND_OPAMP;
            addCircuitEntry(c,false);
            break;
        case 'P' :
            c.kind = KIND_POT;
            addCircuitEntry(c);
            break;
        case 'Q' :
            isMouseDown = false;
            resetSelectedItemsList();
            newState(STATE_MULTISELECT);
            break;
        case 'R' :
            q.index = NONE;
            resetSelectedItemsList();
            newState(STATE_CHECK);
            break;
        case 'S' :
            if(shiftKeyDown)
                q.fastSaveDocument();
            else
                q.saveDocument();
            break;
        case 'U' :
            popUndo();
            return;
        case 'V' :
            emailTest();
            cycleViewStyle();
            break;
        case 'W' :
            if(shiftKeyDown) {
                setAllWaypointsSharp();
                break;
            }
            
            becomeWaypoint();
            break;
        case 'X' :
            flipConnections();
            break;
        case 'Y' :
            if(shiftKeyDown)
                pasteClipBoard();
            else
                cutClipBoard();
            break;
        case 'Z' :
            newState(STATE_DELETE);
            break;
        case '=' :
        case '+' :
            isZoom = !isZoom;
            gHop = isZoom ? gHop*2 : GHOP;
            sX = isZoom ? 3 : 5; //2 : 3;
            gOffset = gHop/2;
            gZoom = isZoom ? 2 : 1;
            scrollX = 0; scrollY = 0;
            break;
            
        case '[' :
            c.kind = KIND_INVERTER;
            c.orient = VERT;
            addCircuitEntry(c);
            break;
        case ']' :
            c.kind = KIND_XOR;
            c.orient = VERT;
            addCircuitEntry(c);
            break;
        case '/' :
        case '?' :
            [viewController performSegueWithIdentifier:@"helpPopover" sender:viewController];
            break;
        case ' ' :
            if(shiftKeyDown) {
                multiDelete();
                break;
            }
            
            if(state == STATE_MOVE && q.index != NONE)
                deleteCircuitObject(q.index,false);
            break;
        case '.' :
            if(++boardSize > 2)
                boardSize = 0;
            newState(state);    // status string updated
            break;
            
        case '$' :
            rotateView = !rotateView;
            break;
        case '<' :
            changeZoom(-1);
            break;
        case '>' :
            changeZoom(+1);
            break;
            
        case '!' :
            c.kind = KIND_TRIMMER;
            addCircuitEntry(c);
            break;
        case '%' :
            c.kind = KIND_LEGEND;
            addCircuitEntry(c);
            break;
        case '^' :
            designStyle = !designStyle;
            break;
        case ';' :
            semiColonClip = !semiColonClip;
            break;
    }
    
    refresh();
}

@end
