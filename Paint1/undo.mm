#import "undo.h"
#import "Persist.h"
#import "QuartzView.h"

#define MAX_UNDO 50

static int uHead = 0;
static int uCount = 0;
static Persist undoM[MAX_UNDO];

void pushUndo()
{
    if(++uCount >= MAX_UNDO) uCount = MAX_UNDO;
    
    memcpy(&undoM[uHead],&q,sizeof(q));
    if(++uHead >= MAX_UNDO) uHead = 0;

    //printf("  Push H %d, C %d\n",uHead,uCount);
}

void popUndo()
{
    if(!uCount) return;
    --uCount;

    if(--uHead < 0) uHead = MAX_UNDO-1;
    memcpy(&q,&undoM[uHead],sizeof(q));
    
    //printf("* Pop  H %d, C %d\n",uHead,uCount);

    q.index = NONE;
    resetSelectedItemsList();
    refresh();
}
