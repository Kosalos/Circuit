#import <Cocoa/Cocoa.h>

@interface QuartzView : NSView

@property (strong) IBOutlet NSTextField *statusLabel;

-(void)reset;
-(void)drawRect2:(NSRect)dirtyRect;

@end

extern QuartzView *quartzView;

enum {
    VIEWSTYLE_DESIGN = 0,
    VIEWSTYLE_CLEAR,
    VIEWSTYLE_JUMPER,
    VIEWSTYLE_TRACE,
};

extern char viewStyle;
extern bool justLabels;
extern bool isZoom;
extern bool designStyle;
extern bool semiColonClip;

extern NSColor *resColor,*resColor2,*capColor,*capColor2,*chipColor,*chipColor2,*tranColor,*tranColor2,*seeThroughGrayColor;
extern NSColor *ecapColor,*diodeColor;

void newState(int s);
void refresh();
void autoResistorSuffix();
void autoWiring();

NSColor *highlightColor(bool highlightStatus);
NSColor *highlightColor(int index);
void setHighlightStrokeColor(bool highlightStatus);
void setHighlightStrokeColor(int index);
void setHighlightFillColor(NSColor *color,bool highlightStatus);


