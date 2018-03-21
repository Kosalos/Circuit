#import "ViewController.h"

ViewController *viewController = nil;

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    viewController = self;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

//- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender
//{
//    if ([segue.identifier isEqualToString:@"renamePopover"]) {
//        NSViewController *p = segue.destinationController;
//        
//        p.view.frame = CGRectMake(100,600,400,200);
//    }
//}
//


@end
