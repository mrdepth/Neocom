//
//  FittingVariationsViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 11.02.13.
//
//

#import "FittingVariationsViewController.h"

@interface FittingVariationsViewController ()
- (IBAction)onClose:(id)sender;
@end

@implementation FittingVariationsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) dealloc {
	[_modifiedItem release];
	[super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onClose:)] autorelease];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) didSelectType:(EVEDBInvType *)type {
	[self.delegate fittingVariationsViewController:self didSelectType:type];
}

#pragma mark - Private

- (IBAction)onClose:(id)sender {
	[self.navigationController dismissModalViewControllerAnimated:YES];
}
@end
