#pragma once
#import <Cocoa/Cocoa.h>
#import "Common.h"

enum {
    KIND_C8,
    KIND_C14,
    KIND_C16,
    KIND_RES,
    KIND_CAP,
    KIND_NODE,
    KIND_GROUND,
    KIND_WAYPOINT,
    KIND_TRANSISTOR,
    KIND_POWER,
    KIND_DELETED,
    KIND_OPAMP,
    KIND_POT,
    KIND_INVERTER,
    KIND_XOR,
    KIND_DIODE,
    KIND_ECAP,
    KIND_TRIMMER,
    KIND_LEGEND,
    KIND_C40,
    KIND_COUNT,
    
    HORZ = 0,
    VERT,
    HORZ2,
    VERT2,
    SHARP,
    
    NAME_WIDTH = 29
};

class CircuitEntry
{
public:
    CircuitEntry() {
        memset(this,0,sizeof(CircuitEntry));
        kind = KIND_WAYPOINT;
        size = 1;
        orient = HORZ;
        pt.x = 100;
        pt.y = 100;
    }

    char kind;
    char size;
    IPoint pt;
    int orient;
    char name[NAME_WIDTH+1];
    short index;
    
    void flip();
    void logicalCoord(NSPoint pnt);
    float distanceToPin(NSPoint p1,int pin);
    bool isHorz();
    int numberPins();
    
    char *summaryName();
    
    NSPoint nodePosition(int pin);
    void changeSize(int dir);
    void autoCurveWaypoint();
    
private:
    NSPoint simpleNodePosition(int pin);
    NSPoint transistorNodePosition(int pin);
    NSPoint trimmerNodePosition(int pin);
    NSPoint powerNodePosition(int pin);
    NSPoint chipNodePosition(int pin);
    NSPoint opAmpNodePosition(int pin);
    NSPoint inverterNodePosition(int pin);
    NSPoint xorNodePosition(int pin);
    NSPoint potNodePosition(int pin);
    NSPoint graphicsCoordinate(int xOffset = 0,int yOffset =  0);
};



