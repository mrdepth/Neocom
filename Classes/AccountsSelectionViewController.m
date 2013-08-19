//
//  AccountsSelectionViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 20.11.12.
//
//

#import "AccountsSelectionViewController.h"
#import "EVEAccountStorage.h"
#import "EUOperationQueue.h"
#import "EVEAccount.h"
#import "AccountsSelectionCellView.h"
#import "UITableViewCell+Nib.h"
#import "Globals.h"
#import "EVEOnlineAPI.h"
#import "UIImageView+URL.h"
#import "appearance.h"


@interface AccountsSelectionViewController ()
@property (nonatomic, strong) NSArray* accounts;
@end

@implementation AccountsSelectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.collectionView.allowsMultipleSelection = YES;
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	self.title = NSLocalizedString(@"Select Characters", nil);
	self.contentSizeForViewInPopover = CGSizeMake(320, 480);
	
	
	[self.dataSource reloadWithCompletionHandler:^{
		NSInteger itemIndex = 0;
		for (EVEAccount* account in self.dataSource.accounts) {
			if ([self.selectedAccounts containsObject:account])
				[self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:itemIndex inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionNone];
			itemIndex++;
		}
	}];
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	NSMutableArray* selected = [NSMutableArray array];
	for (NSIndexPath* indexPath in self.collectionView.indexPathsForSelectedItems) {
		[selected addObject:self.dataSource.accounts[indexPath.item]];
	}
	if (selected.count > 0)
		[self.delegate accountsSelectionViewController:self didSelectAccounts:selected];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

#pragma mark - UICollectionViewDelegate

- (BOOL) collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (BOOL) collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
	return collectionView.indexPathsForSelectedItems.count > 1;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
	return UIEdgeInsetsMake(20, 0, 0, 0);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	return CGSizeMake(230, 160);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
	return 20;
}

@end
