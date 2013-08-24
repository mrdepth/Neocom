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

@interface SelectCharacterBarButtonItem()

@end



@implementation SelectCharacterBarButtonItem

+ (id) barButtonItemWithParentViewController: (UIViewController*) controller {
	return [[SelectCharacterBarButtonItem alloc] initWithParentViewController:controller];
}

- (id) initWithParentViewController: (UIViewController*) controller {
	//if (self = [super initWithTitle:NSLocalizedString(@"Select Character", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onSelect:)]) {
	if (self = [super initWithImage:[UIImage imageNamed:@"account.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(onSelect:)]) {
		EVEAccount *account = [EVEAccount currentAccount];
		self.parentViewController = controller;
	}
	return self;
}

- (IBAction) onSelect: (id) sender {
	EVEAccountsViewController *controller = [[EVEAccountsViewController alloc] initWithNibName:@"EVEAccountsViewController" bundle:nil];

	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
	self.modalViewController = navigationController;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		navigationController.modalPresentationStyle = UIModalPresentationFormSheet;

	[self.parentViewController presentModalViewController:navigationController animated:YES];
}

@end
