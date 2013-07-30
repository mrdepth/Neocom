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
#import "EVEAccountsAPIKeyCellView.h"
#import "EVEAccountsCharacterCellView.h"
#import "UITableViewCell+Nib.h"
#import "EVEUniverseAppDelegate.h"
#import "NSString+TimeLeft.h"
#import "AccessMaskViewController.h"
#import "UIImageView+URL.h"
#import "EUStorage.h"
#import "EVEAccountsDataSource.h"
#import "UIColor+NSNumber.h"

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
	[self.view setBackgroundColor:[UIColor colorWithNumber:@(0x1f1e23ff)]];
	[self.navigationItem setRightBarButtonItem:self.editButtonItem];
	
	[self.navigationItem setRightBarButtonItems:@[self.editButtonItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onAddAccount:)]]];
	
	if ([EVEAccount currentAccount] == nil)
		[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onClose:)]];
	else
		[self.navigationItem setLeftBarButtonItems:@[
		 [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onClose:)],
		 [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Logoff", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onLogoff:)]
		 ]];
	
	[self.dataSource reload];
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

- (IBAction) onClose:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	[self.dataSource setEditing:editing animated:animated];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
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


#pragma mark - UICollectionViewDelegateFlowLayout

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
	NSInteger n = self.view.frame.size.width / collectionViewLayout.itemSize.width;
	if (n > 1) {
		float w = (self.view.frame.size.width - n * collectionViewLayout.itemSize.width) / (2 + n - 1);
		return UIEdgeInsetsMake(20, w, 0, w);
	}
	else
		return UIEdgeInsetsMake(20, 0, 0, 0);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0)
		return CGSizeMake(230, 160);
	else
		return CGSizeMake(230, 40);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
	return section == 0 ? 20 : 5;
}

#pragma mark - Private

- (void) didUpdateCloud:(NSNotification*) notification {
}

@end
