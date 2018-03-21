#import "Persist.h"
#import "QuartzView.h"

Persist q;

// all files stored to Documents/Circuit folder

NSString *previousName = @"name.circuit";

void Persist::reset() {
    connectionCount = 0;
    count = 0;
    newIndex = NONE;
    index = NONE;
}

NSString *filePath(NSString *filename)
{
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *circuitFolder = [documentsPath stringByAppendingString:@"/Circuit"];
    
    // create Circuit folder under Documents if necessary
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    [fileManager createDirectoryAtPath:circuitFolder withIntermediateDirectories:YES attributes:nil error:&error];
    
    return [NSString stringWithFormat:@"%@/%@",circuitFolder,filename];
}

void saveToFile(NSURL *url)
{
    q.version = VERSION;
    
    NSData *data = [NSData dataWithBytes:&q length:sizeof(Persist)];
    
    previousName = [url lastPathComponent];
    [data writeToFile:filePath(previousName) atomically:YES];
}

void readFromFile(NSURL *url)
{
    previousName = [url lastPathComponent];
    NSData *data = [NSData dataWithContentsOfFile:filePath(previousName)];
    
    memcpy(&q,data.bytes,sizeof(Persist));
    
    if(q.version != VERSION)
        q.reset();
    else {
        // ensure index vars are set
        for(int i=0;i<MAX_CIRCUIT_ENTRY;++i)
            q.circuit[i].index = i;
    }

    for(int i=q.connectionCount;i<MAX_CONNECTIONS;++i) 
        q.connection[i].reset();
    
    refresh();
}

//==================================================

NSURL *lastFilename = nil;

void Persist::openDocument()
{
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    
    [panel beginWithCompletionHandler:^(NSInteger result){
        if(result == NSFileHandlingPanelOKButton) {
            lastFilename = [[panel URLs] objectAtIndex:0];
            readFromFile(lastFilename);
        }
        newState(STATE_MOVE);
        refresh();
    }];
}

void Persist::saveDocument()
{
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setNameFieldStringValue:previousName];
    
    [panel beginSheetModalForWindow:quartzView.window completionHandler:^(NSInteger result) {
        if(result == NSFileHandlingPanelOKButton) {
            lastFilename = [panel URL];
            saveToFile(lastFilename);
        }
    }];
}

void Persist::fastSaveDocument()
{
    if(lastFilename != nil)
        saveToFile(lastFilename);
}

