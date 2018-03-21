#import "CircuitEntry.h"
#import "Persist.h"
#import "QuartzView.h"

const int chipHeight[] = { 4-1,7-1,8-1 };

int state = STATE_MOVE;
int connectState = CONNECTION_STATE_FIRST_PIN;

int gHop = GHOP;
int gOffset = gHop/2;
int gZoom = 1;
int scrollX = 0;
int scrollY = 0;
int sX = 6;//3;

int highlightCount;
int highlightIndex[MAX_CIRCUIT_ENTRY];
int highlightCloneIndex[MAX_CIRCUIT_ENTRY];

HighlightConnectionData connectionData[MAX_CONNECTIONS];
HighlightConnectionData componentData[MAX_CIRCUIT_ENTRY];

void resetSelectedItemsList() { highlightCount = 0; }

bool isHighlighted(int index)
{
    if(viewStyle == VIEWSTYLE_JUMPER) return false;    
    
    for(int i=0;i<highlightCount;++i)
        if(highlightIndex[i] == index) return true;
    
    return false;
}

int clamp(int value,int min,int max)
{
    if(value < min) value = min; else if(value > max) value = max;
    return value;
}

NSPoint ConnectionData::connectionLerp(float ratio)
{
    NSPoint pt1 = q.circuit[node1].nodePosition(pin1);
    NSPoint pt2 = q.circuit[node2].nodePosition(pin2);

    pt1.x += (pt2.x - pt1.x) * ratio;
    pt1.y += (pt2.y - pt1.y) * ratio;
    return pt1;
}

NSPoint ConnectionData::connectionCenter()
{
    return connectionLerp(0.5);
}

ILine ConnectionData::line()
{
    NSPoint pt1 = q.circuit[node1].nodePosition(pin1);
    NSPoint pt2 = q.circuit[node2].nodePosition(pin2);
    
    ILine q1;
    q1.p1.set(pt1);
    q1.p2.set(pt2);
    return q1;
}

//===========================================================================================
// Returns a position of the point c relative to the line going through a and b
// Points a, b are expected to be different

bool samePoint(IPoint p1,IPoint p2)
{
    return p1.x == p2.x && p1.y == p2.y;
}

int side(IPoint a,IPoint b,IPoint c)
{
    int d = (c.y - a.y) * (b.x - a.x) - (b.y - a.y) * (c.x - a.x);
    if(d > 0) return +1;
    if(d < 0) return -1;
    return 0;
}

//===========================================================================================
// Returns True if c is inside closed segment.
// a, b, c are expected to be collinear

bool isPointInClosedSegment(IPoint a,IPoint b,IPoint c)
{
    if(a.x < b.x) return a.x <= c.x && c.x <= b.x;
    if(b.x < a.x) return b.x <= c.x && c.x <= a.x;
    if(a.y < b.y) return a.y <= c.y && c.y <= b.y;
    if(b.y < a.y) return b.y <= c.y && c.y <= a.y;
    
    return a.x == c.x && a.y == c.y;
}

bool doLinesIntersect(ILine q1,ILine q2)
{
    if(samePoint(q1.p1,q2.p1)) return false;
    if(samePoint(q1.p1,q2.p2)) return false;
    if(samePoint(q1.p2,q2.p1)) return false;
    if(samePoint(q1.p2,q2.p2)) return false;
    if(samePoint(q1.p1,q1.p2)) return false;
    if(samePoint(q2.p1,q2.p2)) return false;
    
    int s1 = side(q1.p1,q1.p2,q2.p1);
    int s2 = side(q1.p1,q1.p2,q2.p2);
    
    if(s1 == 0 && s2 == 0)
        return
        isPointInClosedSegment(q1.p1,q1.p2,q2.p1) ||
        isPointInClosedSegment(q1.p1,q1.p2,q2.p2) ||
        isPointInClosedSegment(q2.p1,q2.p2,q1.p1) ||
        isPointInClosedSegment(q2.p1,q2.p2,q1.p2);
    
    if(s1 && (s1 == s2))
        return false;
    
    s1 = side(q2.p1,q2.p2,q1.p1);
    s2 = side(q2.p1,q2.p2,q1.p2);
    
    if(s1 && (s1 == s2))
        return false;
    
    return true;
}

