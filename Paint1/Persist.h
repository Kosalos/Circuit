#pragma once
#import "CircuitEntry.h"

#define SIGNATURE 0xaa55

typedef struct {
    int version;
    int count;
    int newIndex;
    int index;
    int connectionCount;
    CircuitEntry circuit[MAX_CIRCUIT_ENTRY];
    ConnectionData connection[MAX_CONNECTIONS];
    
    void reset();
    void openDocument();
    void saveDocument();
    void fastSaveDocument();

} Persist;

extern Persist q;

extern NSURL *lastFilename;
NSString *filePath(NSString *filename);

