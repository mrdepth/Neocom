//
//  SelectCharacterBarButtonItem.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/3/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SelectCharacterBarButtonItem.h"
#import "Globals.h"
#import "EVEAccount.h"
#import "EVEAccountsViewController.h"

@interface SelectCharacterBarButtonItem(Private)

- (void) didSelectAccount:(NSNotification*) notification;

@end



@implementation SelectCharacterBarButtonItem
@synthesize parentViewController;
@synthesize modalViewController;

+ (id) barButtonItemWithParentViewController: (UIViewController*) controller {
	return [[[SelectCharacterBarButtonItem alloc] initWithParentViewController:controller] autorelease];
}

- (id) initWithParentViewController: (UIViewController*) controller {
	if (self = [super initWithTitle:@"Select Character" style:UIBarButtonItemStyleBordered target:self action:@selector(onSelect:)]) {
		EVEAccount *account = [EVEAccount currentAccount];
		[self setCharacterName:account.characterName];
		parentViewController = controller;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:NotificationSelectAccount object:nil];
	}
	return self;
}

- (IBAction) onSelect: (id) sender {
//	EVEAccountsViewController *controller = [[EVEAccountsViewController alloc] initWithNibName:@"EVEAccountsViewController" bundle:nil];
	EVEAccountsViewController *controller = [[EVEAccountsViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"EVEAccountsViewController-iPad" : @"EVEAccountsViewController")
																				bundle:nil];

	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
	navigationController.navigationBar.barStyle = UIBarStyleBlack;
	[controller.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:@"Close"
																					  style:UIBarButtonItemStyleBordered
																					 target:self
																					 action:@selector(onBack:)] autorelease]];
	self.modalViewController = navigationController;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		navigationController.modalPresentationStyle = UIModalPresentationFormSheet;

	[parentViewController presentModalViewController:navigationController animated:YES];
	[controller release];
	[navigationController release];
}

- (IBAction) onBack: (id) sender {
	[modalViewController dismissModalViewControllerAnimated:YES];
	self.modalViewController = nil;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSelectAccount object:nil];
	[modalViewController release];
	[super dealloc];
}

- (void) setCharacterName:(NSString*) name {
	if (name) {
		if (name.length > 13)
			self.title = [[name substringToIndex:10] stringByAppendingString:@"..."];
		else
			self.title = name;
	}
	else
		self.title = @"Select character";
}

@end

@implementation SelectCharacterBarButtonItem(Private)

- (void) didSelectAccount:(NSNotification*) notification {
	EVEAccount *account = [EVEAccount currentAccount];
	[self setCharacterName:account.characterName];
}

@end
