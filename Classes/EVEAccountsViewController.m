//
//  EVEAccountsViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "EVEAccountsViewController.h"
#import "Globals.h"
#import "AddEVEAccountViewController.h"
#import "EVEAccount.h"
#import "EVEOnlineAPI.h"
#import "EVEUniverseAppDelegate.h"
#import "NSString+TimeLeft.h"
#import "AccessMaskViewController.h"
#import "UIImageView+URL.h"
#import "EUStorage.h"
#import "EVEAccountsDataSource.h"
#import "UIColor+NSNumber.h"
#import "EVEAccountsManager.h"
#import "appearance.h"

@interface EVEAccountsViewController()

- (void) didUpdateCloud:(NSNotification*) notification;
@end


@implementation EVEAccountsViewController

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
 // Custom initialization
 }
 return self;
 }
 */

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		self.title = NSLocalizedString(@"Accounts", nil);
	
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	[self.navigationItem setRightBarButtonItem:self.editButtonItem];
	
	[self.navigationItem setRightBarButtonItems:@[self.editButtonItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onAddAccount:)]]];
	
	if ([EVEAccount currentAccount] == nil)
		[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)]];
	else {
		[self.navigationItem setLeftBarButtonItems:@[
		 [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)],
		 [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Logoff", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onLogoff:)]
		 ]];
		self.dataSource.selectedAccounts = @[[EVEAccount currentAccount]];
	}
	
	[self.dataSource reloadWithCompletionHandler:^{
	}];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (IBAction) onAddAccount: (id) sender {
	AddEVEAccountViewController *controller = [[AddEVEAccountViewController alloc] initWithNibName:@"AddEVEAccountViewController" bundle:nil];
	[self.navigationController pushViewController:controller animated:YES];
}

- (IBAction) onLogoff: (id) sender {
	[EVEAccount setCurrentAccount:nil];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	[self.dataSource setEditing:editing animated:animated];
}

#pragma mark - ASCollectionViewDelegate

- (void)collectionView:(ASCollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	[collectionView deselectItemAtIndexPath:indexPath animated:YES];
	if (indexPath.section == 0 && !self.editing) {
		EVEAccount* account = [self.dataSource.accounts objectAtIndex:indexPath.row];
		[EVEAccount setCurrentAccount:account];
		[self dismissViewControllerAnimated:YES completion:nil];
	}
	else if (indexPath.section == 1){
		APIKey* apiKey = self.dataSource.apiKeys[indexPath.item];
		if (apiKey.apiKeyInfo) {
			AccessMaskViewController* controller = [[AccessMaskViewController alloc] initWithNibName:@"AccessMaskViewController" bundle:nil];
			controller.accessMask = apiKey.apiKeyInfo.key.accessMask;
			controller.apiKeyType = apiKey.apiKeyInfo.key.type;
			[self.navigationController pushViewController:controller animated:YES];
		}
	}
}

- (void)collectionView:(ASCollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0 && !self.editing) {
		EVEAccount* account = [self.dataSource.accounts objectAtIndex:indexPath.row];
		[EVEAccount setCurrentAccount:account];
		[self dismissViewControllerAnimated:YES completion:nil];
	}
}


#pragma mark - UICollectionViewDelegateFlowLayout

- (UIEdgeInsets)collectionView:(ASCollectionView *)collectionView layout:(UICollectionViewFlowLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
	return UIEdgeInsetsMake(10, 10, 10, 10);
}

- (CGSize)collectionView:(ASCollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0)
		return CGSizeMake(240, 160);
	else
		return CGSizeMake(240, 40);
}

- (CGFloat)collectionView:(ASCollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
	return section == 0 ? 10 : 5;
}

#pragma mark - ASCollectionViewDelegatePanLayout

- (BOOL)collectionView:(ASCollectionView *)collectionView canPanItemsAtIndexPaths:(NSArray*) indexPaths {
	return [indexPaths[0] section] == 0;
}

- (BOOL)collectionView:(ASCollectionView *)collectionView canMoveItemsAtIndexPaths:(NSArray*) indexPaths toIndexPaths:(NSArray*) destination {
	return [destination[0] section] == 0;
}


- (void)collectionView:(ASCollectionView *)collectionView didMoveItemsAtIndexPaths:(NSArray*) indexPaths toIndexPaths:(NSArray*) destination {
	NSMutableIndexSet* from = [NSMutableIndexSet new];
	for (NSIndexPath* indexPath in indexPaths)
		[from addIndex:indexPath.item];
	
	NSMutableIndexSet* to = [NSMutableIndexSet new];
	for (NSIndexPath* indexPath in destination)
		[to addIndex:indexPath.item];

	if (!self.editing) {
		NSArray* objects = [self.dataSource.accounts objectsAtIndexes:from];
		[self.dataSource.accounts removeObjectsAtIndexes:from];
		[self.dataSource.accounts insertObjects:objects atIndexes:to];

		NSInteger order = 0;
		for (EVEAccount* account in self.dataSource.accounts)
			account.order = order++;
		[self.dataSource.allAccounts sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"character.characterName" ascending:YES]]];
		[[EVEAccountsManager sharedManager] saveOrder];
	}
	else {
		NSArray* objects = [self.dataSource.allAccounts objectsAtIndexes:from];
		[self.dataSource.allAccounts removeObjectsAtIndexes:from];
		[self.dataSource.allAccounts insertObjects:objects atIndexes:to];
		
		NSInteger order = 0;
		for (EVEAccount* account in self.dataSource.allAccounts)
			account.order = order++;
		[self.dataSource.accounts sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"character.characterName" ascending:YES]]];
		[[EVEAccountsManager sharedManager] saveOrder];
	}
}

#pragma mark - Private

- (void) didUpdateCloud:(NSNotification*) notification {
}

@end
