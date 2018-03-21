#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface HelpController : NSViewController

@property (strong) IBOutlet WebView *webView;

- (IBAction)OpenButtonPressed:(id)sender;
- (IBAction)saveButtonPressed:(id)sender;
- (IBAction)resetButtonPressed:(id)sender;

@end
