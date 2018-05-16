#import "CircuitEntry.h"
#import "Persist.h"

void flipConnections();

void CircuitEntry::logicalCoord(NSPoint pnt) { pt.x = (pnt.x-sX)/gHop; pt.y = pnt.y/gHop; }
bool CircuitEntry::isHorz() { return orient == HORZ || orient == HORZ2; }

void CircuitEntry::flip()
{
    if(kind == KIND_WAYPOINT) {
        if(orient != SHARP) orient = SHARP; else {
            autoCurveWaypoint();
        }
        
        //if(++orient > SHARP) orient = HORZ;
    }
    else {
        if(++orient > VERT2) orient = HORZ;
        if((kind == KIND_DIODE || kind == KIND_ECAP) && (orient == HORZ || orient == HORZ2)) flipConnections();
    }
}

char *CircuitEntry::summaryName()
{
    static char temp[NAME_WIDTH+1];
    
    strcpy(temp,name);
    
    char *ch = strchr(temp,';');  // trim off transistor pin legends
    if(ch != NULL) *ch = 0;
    
    if(kind == KIND_DIODE && !temp[0])
        strcpy(temp,"D");
    
    return temp;
}

NSPoint CircuitEntry::graphicsCoordinate(int xOffset,int yOffset)
{
    return NSMakePoint(scrollX + (pt.x + sX + xOffset) * gHop, scrollY + (pt.y + yOffset) * gHop);
}

void CircuitEntry::changeSize(int dir)
{
    switch(kind) {
        case KIND_RES :
        case KIND_CAP :
        case KIND_DIODE :
        case KIND_ECAP :
            size = clamp(size + dir,1,24);
            break;
    }
}

NSPoint CircuitEntry::simpleNodePosition(int pin)
{
    NSPoint pnt = graphicsCoordinate();
    
    if(pin == 0) return pnt;
    if(pin == 1) {
        if(orient == HORZ || orient == HORZ2) {
            pnt.x += size * gHop;
            return pnt;
        } else {
            pnt.y += size * gHop;
            return pnt;
        }
    }
    
    pnt.x = FAR_AWAY;
    return pnt;
}

NSPoint CircuitEntry::transistorNodePosition(int pin)
{
    NSPoint pnt = graphicsCoordinate();
    
    if(pin < 0 || pin > 2) {
        pnt.x = FAR_AWAY;
        return pnt;
    }
    
    if(pin == 0) {
        switch(orient) {
            default :
            case HORZ : // flat up
                return pnt;
            case HORZ2 : // flat down
                pnt.x += gHop*2;
                return pnt;
            case VERT : // flat right
                return pnt;
            case VERT2 : // flat left
                pnt.y += gHop*2;
                return pnt;
        }
    }
    
    if(pin == 1) {
        switch(orient) {
            default :
            case HORZ : // flat up
                pnt.x += gHop*1;
                return pnt;
            case HORZ2 : // flat down
                pnt.x += gHop*1;
                return pnt;
            case VERT : // flat right
                pnt.y += gHop*1;
                return pnt;
            case VERT2 : // flat left
                pnt.y += gHop*1;
                return pnt;
        }
    }
    
    // pin == 2
    switch(orient) {
        default :
        case HORZ : // flat up
            pnt.x += gHop*2;
            return pnt;
        case HORZ2 : // flat down
            return pnt;
        case VERT : // flat right
            pnt.y += gHop*2;
            return pnt;
        case VERT2 : // flat left
            return pnt;
    }
}

NSPoint CircuitEntry::trimmerNodePosition(int pin)
{
    NSPoint pnt = graphicsCoordinate();
    
    if(pin < 0 || pin > 2) {
        pnt.x = FAR_AWAY;
        return pnt;
    }
    
    if(pin == 0) {
        switch(orient) {
            default :
            case HORZ : // flat up
                return pnt;
            case HORZ2 : // flat down
                pnt.x += gHop*2;
                return pnt;
            case VERT : // flat right
                return pnt;
            case VERT2 : // flat left
                pnt.y += gHop*2;
                return pnt;
        }
    }
    
    if(pin == 1) {
        switch(orient) {
            default :
            case HORZ : // flat up
                pnt.x += gHop*1;
                pnt.y += gHop*2;
                return pnt;
            case HORZ2 : // flat down
                pnt.x += gHop*1;
                pnt.y -= gHop*2;
                return pnt;
            case VERT : // flat right
                pnt.x -= gHop*2;
                pnt.y += gHop*1;
                return pnt;
            case VERT2 : // flat left
                pnt.x += gHop*2;
                pnt.y += gHop*1;
                return pnt;
        }
    }
    
    // pin == 2
    switch(orient) {
        default :
        case HORZ : // flat up
            pnt.x += gHop*2;
            return pnt;
        case HORZ2 : // flat down
            return pnt;
        case VERT : // flat right
            pnt.y += gHop*2;
            return pnt;
        case VERT2 : // flat left
            return pnt;
    }
}

NSPoint CircuitEntry::powerNodePosition(int pin)
{
    NSPoint pnt = graphicsCoordinate();
    
    switch(orient) {
        default :
        case HORZ :
        case HORZ2 :
            pnt.x += gHop * pin;
            return pnt;
        case VERT :
        case VERT2 :
            pnt.y += gHop * (4-pin);
            return pnt;
    }
}

NSPoint CircuitEntry::opAmpNodePosition(int pin)
{
    NSPoint pnt = graphicsCoordinate();
    
    switch(pin) {
        case 0 :
            break;
        case 1 :
            pnt.x += gHop*2;
            pnt.y += gHop;
            break;
        case 2 :
            pnt.y += gHop*2;
            break;
        default :
            pnt.x = FAR_AWAY;
            break;
    }
    
    return pnt;
}

NSPoint CircuitEntry::inverterNodePosition(int pin)
{
    NSPoint pnt = graphicsCoordinate();
    pnt.y += gHop;
    
    switch(pin) {
        case 0 :
            break;
        case 1 :
            pnt.x += gHop*3;
            break;
        default :
            pnt.x = FAR_AWAY;
            break;
    }
    
    return pnt;
}

NSPoint CircuitEntry::xorNodePosition(int pin)
{
    NSPoint pnt = graphicsCoordinate();
    
    switch(pin) {
        case 0 :
            break;
        case 1 :
            pnt.x += gHop*2;
            pnt.y += gHop;
            break;
        case 2 :
            pnt.y += gHop*2;
            break;
        default :
            pnt.x = FAR_AWAY;
            break;
    }
    
    return pnt;
}

NSPoint CircuitEntry::potNodePosition(int pin)
{
    NSPoint pnt = graphicsCoordinate();
 
    pnt.y += pin * gHop * 2;
    
    return pnt;
}

NSPoint CircuitEntry::chipNodePosition(int pin)
{
    NSPoint pnt;
    int chipWidth = 3;
    int height = 0;
    
    if(kind == KIND_C40) {
        height = 19;
        chipWidth = 6;
    }
    else
        height = chipHeight[kind];

	if(kind == KIND_C18)
		height = 8;
	
    if(pin < 0 || pin >= height*2+2) {
        pnt.x = FAR_AWAY;
        return pnt;
    }
    
    switch(orient) {
        default :
        case VERT :
            pnt = graphicsCoordinate();
            
            if(pin <= height) {
                pnt.y += pin*gHop;
                return pnt;
            }
            
            pnt.x += gHop*chipWidth;
            pnt.y += (height*2+1-pin)*gHop;
            return pnt;
        case VERT2 :
            pnt = graphicsCoordinate(chipWidth,height);
            
            if(pin <= height) {
                pnt.y -= pin*gHop;
                return pnt;
            }
            
            pnt.x -= gHop*chipWidth;
            pnt.y -= (height*2+1-pin)*gHop;
            return pnt;
        case HORZ :
            pnt = graphicsCoordinate(0,chipWidth);
            
            if(pin <= height) {
                pnt.x += pin*gHop;
                return pnt;
            }
            
            pnt.y -= gHop*chipWidth;
            pnt.x += (height*2+1-pin)*gHop;
            return pnt;
        case HORZ2 :
            pnt = graphicsCoordinate(height,0);
            
            if(pin <= height) {
                pnt.x -= pin*gHop;
                return pnt;
            }
            
            pnt.y += gHop*chipWidth;
            pnt.x -= (height*2+1-pin)*gHop;
            return pnt;
    }
}

NSPoint CircuitEntry::nodePosition(int pin)
{
    switch(kind) {
        case KIND_RES :
        case KIND_CAP :
        case KIND_DIODE :
        case KIND_ECAP :
            return simpleNodePosition(pin);
        case KIND_TRANSISTOR :
            return transistorNodePosition(pin);
        case KIND_OPAMP :
            return opAmpNodePosition(pin);
        case KIND_POT :
            return potNodePosition(pin);
        case KIND_C8 :
        case KIND_C14 :
        case KIND_C16:
		case KIND_C18:
        case KIND_C40 :
            return chipNodePosition(pin);
        case KIND_NODE :
        case KIND_GROUND :
        case KIND_WAYPOINT :
        case KIND_LEGEND :
            return simpleNodePosition(0);
            break;
        case KIND_POWER :
            return powerNodePosition(pin);
        case KIND_INVERTER :
            return inverterNodePosition(pin);
        case KIND_XOR :
            return xorNodePosition(pin);
        case KIND_TRIMMER :
            return trimmerNodePosition(pin);
        default :
            return graphicsCoordinate();
    }
}

int CircuitEntry::numberPins()
{
    switch(kind) {
        case KIND_NODE :
        case KIND_GROUND :
        case KIND_WAYPOINT :
        case KIND_LEGEND :
            return 1;
        case KIND_RES :
        case KIND_CAP :
        case KIND_DIODE :
        case KIND_ECAP :
        case KIND_INVERTER :
        case KIND_XOR :
            return 2;
        case KIND_TRANSISTOR :
        case KIND_OPAMP :
        case KIND_POT :
        case KIND_TRIMMER :
            return 3;
        case KIND_POWER :
            return 5;
        case KIND_C8 :
            return 8;
        case KIND_C14 :
            return 14;
        case KIND_C16:
            return 16;
		case KIND_C18:
			return 18;
        case KIND_C40 :
            return 40;
        default :
            return 0;
    }
}


float CircuitEntry::distanceToPin(NSPoint p1,int pin)
{
    NSPoint pnt;
    
    switch(kind) {
        case KIND_RES :
        case KIND_CAP :
        case KIND_DIODE :
        case KIND_ECAP :
            pnt = simpleNodePosition(pin);
            break;
        case KIND_TRANSISTOR :
            pnt = transistorNodePosition(pin);
            break;
        case KIND_TRIMMER :
            pnt = trimmerNodePosition(pin);
            break;
        case KIND_OPAMP :
            pnt = opAmpNodePosition(pin);
            break;
        case KIND_POT :
            pnt = potNodePosition(pin);
            break;
        case KIND_C8 :
        case KIND_C14 :
        case KIND_C16:
		case KIND_C18:
        case KIND_C40 :
            pnt = chipNodePosition(pin);
            break;
        case KIND_NODE :
        case KIND_GROUND :
        case KIND_WAYPOINT :
        case KIND_LEGEND :
            pnt = simpleNodePosition(0);
            break;
        case KIND_POWER :
            pnt = powerNodePosition(pin);
            break;
        case KIND_INVERTER :
            pnt = inverterNodePosition(pin);
            break;
        case KIND_XOR :
            pnt = xorNodePosition(pin);
            break;
        default :
            pnt.x = scrollX + pt.x * gHop;
            pnt.y = scrollY + pt.y * gHop;
            break;
    }
    
    if(pnt.x == NONE) return FAR_AWAY;
    return hypotf(p1.x - pnt.x, p1.y - pnt.y);
}

//==========================================================

void CircuitEntry::autoCurveWaypoint()
{
    int n1=0,p1=0,n2=0,p2=0,cCount = 0;
    NSPoint cp[20];
    
    orient = SHARP;

    for(int i=0;i< q.connectionCount; ++i) {
        bool found = false;
        
        if(q.connection[i].node1 == index) {
            n1 = index;
            p1 = q.connection[i].pin1;
            n2 = q.connection[i].node2;
            p2 = q.connection[i].pin2;
            found = true;
        }
        if(q.connection[i].node2 == index) {
            n1 = index;
            p1 = q.connection[i].pin2;
            n2 = q.connection[i].node1;
            p2 = q.connection[i].pin1;
            found = true;
        }
        
        if(found) {
            NSPoint t1 = q.circuit[n1].nodePosition(p1);
            NSPoint t2 = q.circuit[n2].nodePosition(p2);
            
            cp[cCount].x = t2.x - t1.x;
            cp[cCount].y = t2.y - t1.y;
            if(cp[cCount].x < 0) cp[cCount].x = -1; else if(cp[cCount].x > 0) cp[cCount].x = 1;
            if(cp[cCount].y < 0) cp[cCount].y = -1; else if(cp[cCount].y > 0) cp[cCount].y = 1;
            
            //                printf("cnt %2d N1: %d,%d  N2 %d,%d   dx,dy %3.0f,%3.0f\n",cCount,n1,p1,n2,p2,cp[cCount].x,cp[cCount].y);
            ++cCount;
        }
    }
    
    if(cCount != 2) return;
    
    if(cp[0].x ==  1 && cp[0].y ==  0 && cp[1].x ==  0 && cp[1].y == -1)  orient = 0;
    if(cp[0].x == -1 && cp[0].y ==  0 && cp[1].x ==  0 && cp[1].y ==  1)  orient = 1;
    if(cp[0].x ==  0 && cp[0].y ==  1 && cp[1].x ==  1 && cp[1].y ==  0)  orient = 2;
    if(cp[0].x ==  0 && cp[0].y == -1 && cp[1].x == -1 && cp[1].y ==  0)  orient = 3;
    if(cp[1].x ==  1 && cp[1].y ==  0 && cp[0].x ==  0 && cp[0].y == -1)  orient = 0;
    if(cp[1].x == -1 && cp[1].y ==  0 && cp[0].x ==  0 && cp[0].y ==  1)  orient = 1;
    if(cp[1].x ==  0 && cp[1].y ==  1 && cp[0].x ==  1 && cp[0].y ==  0)  orient = 2;
    if(cp[1].x ==  0 && cp[1].y == -1 && cp[0].x == -1 && cp[0].y ==  0)  orient = 3;
}


