#import <Cocoa/Cocoa.h>

extern char *renameString;

@interface RenameController : NSViewController

@property (strong) IBOutlet NSTextField *text;

- (IBAction)okayButtonPressed:(id)sender;
- (IBAction)cancelButtonPressed:(id)sender;

@end
