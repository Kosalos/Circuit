#import "RenameController.h"
#import "QuartzView.h"
#import "CircuitEntry.h"

char *renameString = NULL;

@implementation RenameController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	if(renameString != NULL) {
		_text.stringValue = [NSString stringWithFormat:@"%s", renameString];
	}
}

- (IBAction)okayButtonPressed:(id)sender
{
	if(renameString != NULL) {
		strncpy(renameString,_text.stringValue.UTF8String,NAME_WIDTH);
		renameString[NAME_WIDTH] = 0;
		
		autoResistorSuffix();
		autoWiring();
		refresh();
	}
	
	
	[self cancelButtonPressed:0];
}

- (IBAction)cancelButtonPressed:(id)sender
{
	[self dismissViewController:self];
	renameString = NULL;
}

@end
