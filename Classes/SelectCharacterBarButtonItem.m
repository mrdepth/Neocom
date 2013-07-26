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

- (void) didSelectAccount:(NSNotification*) notification;

@end



@implementation SelectCharacterBarButtonItem

+ (id) barButtonItemWithParentViewController: (UIViewController*) controller {
	return [[SelectCharacterBarButtonItem alloc] initWithParentViewController:controller];
}

- (id) initWithParentViewController: (UIViewController*) controller {
	if (self = [super initWithTitle:NSLocalizedString(@"Select Character", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onSelect:)]) {
		EVEAccount *account = [EVEAccount currentAccount];
		[self setCharacterName:account.characterName];
		self.parentViewController = controller;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:EVEAccountDidSelectNotification object:nil];
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

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) setCharacterName:(NSString*) name {
	if (name) {
		if (name.length > 13)
			self.title = [[name substringToIndex:10] stringByAppendingString:@"..."];
		else
			self.title = name;
	}
	else
		self.title = NSLocalizedString(@"Select Character", nil);
}

#pragma mark - Private

- (void) didSelectAccount:(NSNotification*) notification {
	EVEAccount *account = [EVEAccount currentAccount];
	[self setCharacterName:account.characterName];
}

@end
