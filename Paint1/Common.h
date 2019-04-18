#pragma once

#import <Cocoa/Cocoa.h>

enum {
    WINDOW_XS = 2000,
    WINDOW_YS = 2800,
    MAX_CIRCUIT_ENTRY = 1000,
    MAX_CONNECTIONS = 1000,
    MAX_PINS = 16,
    MAX_INFOLIST = 100,
    MAX_VIAS = 100,
    
    STATE_MOVE = 0,
    STATE_CONNECT,
    STATE_DELETE,
    STATE_MULTISELECT,
    STATE_MULTIMOVE,
    STATE_INFO,
    STATE_LOOK,
    STATE_CHECK,
    STATE_VIA,
    
    GHOP = 16,  // grid cell size

    NODE_RADIUS = 7,
    NODE_SIZE_PCB = 13,  //15,
    NODE_HOLE_SIZE = 7,
    CONNECTION_WIDTH_PCB = 9, //12,
    CONNECTION_WIDTH_DESIGN = 2,
    
    CONNECTION_STATE_FIRST_PIN = 0,
    
    CONNECTION_TYPE_CONNECT = 0,
    CONNECTION_TYPE_VIA,
    
    NONE = -1,
    VERSION = 1,
    FAR_AWAY = 9999
};

typedef struct {
    int x,y;
    
    void set(NSPoint pt) { x = (int)pt.x; y = (int)pt.y; }
} IPoint;

typedef struct {
    IPoint p1,p2;
} ILine;

typedef struct {
    int node1,pin1,node2;
    char pin2,type,unused1,unused2;
    
    NSPoint connectionLerp(float ratio);
    NSPoint connectionCenter();
    void reset() { node1 = 0; node2 = 0; pin1 =  0; pin2 = 0; }
    ILine line();
} ConnectionData;

typedef struct {
    bool selected;
    bool tested;
    
    void toggleSelected() { selected = !selected; }
} HighlightConnectionData;

extern HighlightConnectionData connectionData[MAX_CONNECTIONS];
extern HighlightConnectionData componentData[MAX_CIRCUIT_ENTRY];

extern int gHop,gOffset,gZoom,sX,scrollX,scrollY;

extern const int chipHeight[];
extern int state;
extern int connectState;

extern int highlightCount;
extern int highlightIndex[MAX_CIRCUIT_ENTRY];
extern int highlightCloneIndex[MAX_CIRCUIT_ENTRY];

bool doLinesIntersect(ILine q1,ILine q2);
void resetSelectedItemsList();
bool isHighlighted(int index);

int clamp(int value,int min,int max);

// this needs a re-design..
//// ===========================================
//#pragma mark autoLayout
//
//int intersectCount()
//{
//    int total = 0;
//    ILine q1,q2;
//
//    for(int i=0;i<q.connectionCount-1;++i) {
//        q1 = q.connection[i].line();
//
//        for(int j=i+1;j<q.connectionCount;++j) {
//            q2 = q.connection[j].line();
//
//            if(doLinesIntersect(q1,q2)) ++total;
//        }
//    }
//
//    //printf("Lines intersect = %d\n",total);
//
//    return total;
//}
//
//void autoLayout()
//{
//    int total,origC = q.index;
//    IPoint pOrig;
//
//    for(int i=0;i<q.connectionCount-1;++i) {
//        // 'F','X'  resistors and caps
//        if(q.circuit[i].kind == KIND_RES || q.circuit[i].kind == KIND_CAP) {
//
//            // F
//            total = intersectCount();
//            if(total > 0) {
//                int orig = q.circuit[i].orient;
//                q.circuit[i].orient = orig == HORZ ? VERT : HORZ;
//
//                if(intersectCount() >= total) q.circuit[i].orient = orig;
//            }
//
//            // X
//            total = intersectCount();
//            if(total > 0) {
//                q.index = i;
//                flipConnections();
//                if(intersectCount() >= total) flipConnections();
//            }
//        }
//
//        // move Xcoord
//        for(int gOffset = 1;gOffset < 10;++gOffset) {
//            total = intersectCount();
//            if(total > 0) {
//                pOrig = q.circuit[i].pt;
//                q.circuit[i].pt.x += gOffset;
//
//                if(intersectCount() >= total) q.circuit[i].pt = pOrig;
//            }
//        }
//        for(int gOffset = 1;gOffset < 10;++gOffset) {
//            total = intersectCount();
//            if(total > 0) {
//                pOrig = q.circuit[i].pt;
//                q.circuit[i].pt.x -= gOffset;
//
//                if(intersectCount() >= total) q.circuit[i].pt = pOrig;
//            }
//        }
//
//        // move Ycoord
//        for(int gOffset = 1;gOffset < 10;++gOffset) {
//            total = intersectCount();
//            if(total > 0) {
//                pOrig = q.circuit[i].pt;
//                q.circuit[i].pt.y += gOffset;
//
//                if(intersectCount() >= total) q.circuit[i].pt = pOrig;
//            }
//        }
//        for(int gOffset = 1;gOffset < 10;++gOffset) {
//            total = intersectCount();
//            if(total > 0) {
//                pOrig = q.circuit[i].pt;
//                q.circuit[i].pt.y -= gOffset;
//
//                if(intersectCount() >= total) q.circuit[i].pt = pOrig;
//            }
//        }
//    }
//
//    q.index = origC;
//
//    refresh();
//}

