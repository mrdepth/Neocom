//
//  EVEAccountsDataSource.m
//  EVEUniverse
//
//  Created by mr_depth on 19.07.13.
//
//

#import "EVEAccountsDataSource.h"
#import "EVEAccountCell.h"
#import "EUOperationQueue.h"
#import "EVEAccountsManager.h"
#import "UIView+Nib.h"
#import "UIImageView+URL.h"
#import "EVEAPIKeyCell.h"
#import "EVEAPIKeysViewController.h"
#import "AccessMaskViewController.h"
#import "AddEVEAccountViewController.h"
#import "UIActionSheet+Block.h"

@interface EVEAccountsDataSource()<EVEAccountCellDelegate, EVEAPIKeyCellDelegate>
@property (nonatomic, strong) NSMutableArray* allAccounts;

- (void) didChangeAccountsManager:(NSNotification*) notification;
@end

@implementation EVEAccountsDataSource

- (void) awakeFromNib {
	[self.collectionView registerNib:[UINib nibWithNibName:self.nibName bundle:nil] forCellWithReuseIdentifier:self.reuseIdentifier];
	[self.collectionView registerNib:[UINib nibWithNibName:@"EVEAPIKeyCell" bundle:nil] forCellWithReuseIdentifier:@"EVEAPIKeyCell"];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeAccountsManager:) name:EVEAccountsManagerDidChangeNotification object:nil];
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) reload {
	EUOperation* operation = [EUOperation operationWithIdentifier:@"EVEAccountsDataSource+reload" name:@"Loading Accounts..."];
	__weak EUOperation* weakOperation = operation;
	NSMutableArray* accounts = [NSMutableArray array];
	NSMutableArray* allAccounts = [NSMutableArray array];

	[operation addExecutionBlock:^{
		EVEAccountsManager* manager = [EVEAccountsManager sharedManager];
		[manager reload];
		for (EVEAccount* account in manager.allAccounts) {
			[account reload];
			[allAccounts addObject:account];
			if (!account.ignored)
				[accounts addObject:account];
		}
		[allAccounts sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"character.characterName" ascending:YES]]];
	}];
	
	[operation setCompletionBlockInMainThread:^{
		if (![weakOperation isCancelled]) {
			[self.collectionView reloadData];
			self.accounts = accounts;
			self.allAccounts = allAccounts;
			self.apiKeys = [[APIKey allAPIKeys] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"keyID" ascending:YES]]];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) setEditing:(BOOL)editing {
	[self setEditing:editing animated:NO];
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
	_editing = editing;
	for (EVEAccountCell* cell in self.collectionView.visibleCells) {
		if ([cell isKindOfClass:[EVEAccountCell class]])
			[cell setEditing:editing animated:animated];
	}
	
	NSMutableArray* indexes = [[NSMutableArray alloc] init];
	int i = 0;
	for (EVEAccount* account in self.allAccounts) {
		if (account.ignored)
			[indexes addObject:[NSIndexPath indexPathForItem:i inSection:0]];
		i++;
	}
	
	[self.collectionView performBatchUpdates:^{
		if (editing) {
			[self.collectionView insertItemsAtIndexPaths:indexes];
			[self.collectionView insertSections:[NSIndexSet indexSetWithIndex:1]];
		}
		else {
			[self.collectionView deleteItemsAtIndexPaths:indexes];
			[self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:1]];
		}
	} completion:nil];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return section == 0 ? (self.editing ? self.allAccounts.count : self.accounts.count) : self.apiKeys.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		EVEAccountCell* cell = (EVEAccountCell*) [collectionView dequeueReusableCellWithReuseIdentifier:self.reuseIdentifier forIndexPath:indexPath];
		cell.delegate = self;
		EVEAccount* account = [(self.editing ? self.allAccounts : self.accounts) objectAtIndex:indexPath.item];
		
		cell.account = account;
		cell.editing = self.editing;
		return cell;
	}
	else {
		EVEAPIKeyCell* cell = (EVEAPIKeyCell*) [collectionView dequeueReusableCellWithReuseIdentifier:@"EVEAPIKeyCell" forIndexPath:indexPath];
		cell.delegate = self;
		APIKey* apiKey = [self.apiKeys objectAtIndex:indexPath.row];
		if (apiKey.apiKeyInfo) {
			NSString* keyType = nil;
			if (apiKey.apiKeyInfo.key.type == EVEAPIKeyTypeAccount)
				keyType = @"Account";
			else if (apiKey.apiKeyInfo.key.type == EVEAPIKeyTypeCharacter)
				keyType = @"Char";
			else if (apiKey.apiKeyInfo.key.type == EVEAPIKeyTypeCorporation)
				keyType = @"Corp";
			else
				keyType = @"Unknown";
			
			cell.textLabel.text = [NSString stringWithFormat:@"%@ key %d (%d characters)\nAccess mask %d", keyType, apiKey.keyID, apiKey.apiKeyInfo.characters.count, apiKey.apiKeyInfo.key.accessMask];
		}
		else {
			cell.textLabel.text = [NSString stringWithFormat:@"Key %d\n%@", apiKey.keyID, [apiKey.error localizedDescription]];
		}
		return cell;
	}
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return self.editing ? 2 : 1;
}

#pragma mark - EVEAccountCellDelegate

- (void) accountCell:(EVEAccountCell*) cell deleteButtonTapped:(UIButton*) button {
	[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackTranslucent
								   title:nil
					   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
				  destructiveButtonTitle:NSLocalizedString(@"Delete", nil)
					   otherButtonTitles:nil
						 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
							 if (selectedButtonIndex == actionSheet.destructiveButtonIndex) {
								 for (APIKey* key in cell.account.apiKeys)
									 [[EVEAccountsManager sharedManager] removeAPIKeyWithKeyID:key.keyID];
							 }
						 }
							 cancelBlock:nil] showFromRect:button.bounds inView:button animated:YES];
}

- (void) accountCell:(EVEAccountCell*) cell favoritesButtonTapped:(UIButton*) button {
	cell.account.ignored = !cell.account.ignored;
	button.selected = !cell.account.ignored;
	
	if (cell.account.ignored)
		[(NSMutableArray*) self.accounts removeObject:cell.account];
	else {
		[(NSMutableArray*) self.accounts addObject:cell.account];
		[(NSMutableArray*) self.accounts sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"character.characterName" ascending:YES]]];
	}
}

- (void) accountCell:(EVEAccountCell*) cell charKeyButtonTapped:(UIButton*) button {
	NSArray* apiKeys = [cell.account.apiKeys filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"apiKeyInfo.key.type != %d", EVEAPIKeyTypeCorporation]];
	if (apiKeys.count == 0) {
		AddEVEAccountViewController *controller = [[AddEVEAccountViewController alloc] initWithNibName:@"AddEVEAccountViewController" bundle:nil];
		[self.viewController.navigationController pushViewController:controller animated:YES];
	}
	else if (apiKeys.count == 1) {
		AccessMaskViewController* controller = [[AccessMaskViewController alloc] initWithNibName:@"AccessMaskViewController" bundle:nil];
		APIKey* apiKey = apiKeys[0];
		controller.accessMask = apiKey.apiKeyInfo.key.accessMask;
		controller.apiKeyType = apiKey.apiKeyInfo.key.type;
		[self.viewController.navigationController pushViewController:controller animated:YES];
	}
	else {
		EVEAPIKeysViewController* controller = [[EVEAPIKeysViewController alloc] initWithNibName:@"EVEAPIKeysViewController" bundle:nil];
		controller.apiKeys = apiKeys;
		controller.editing = self.editing;
		[self.viewController.navigationController pushViewController:controller animated:YES];
	}
}

- (void) accountCell:(EVEAccountCell*) cell corpKeyButtonTapped:(UIButton*) button {
	NSArray* apiKeys = [cell.account.apiKeys filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"apiKeyInfo.key.type == %d", EVEAPIKeyTypeCorporation]];
	if (apiKeys.count == 0) {
		AddEVEAccountViewController *controller = [[AddEVEAccountViewController alloc] initWithNibName:@"AddEVEAccountViewController" bundle:nil];
		[self.viewController.navigationController pushViewController:controller animated:YES];
	}
	else if (apiKeys.count == 1) {
		AccessMaskViewController* controller = [[AccessMaskViewController alloc] initWithNibName:@"AccessMaskViewController" bundle:nil];
		APIKey* apiKey = apiKeys[0];
		controller.accessMask = apiKey.apiKeyInfo.key.accessMask;
		controller.apiKeyType = apiKey.apiKeyInfo.key.type;
		[self.viewController.navigationController pushViewController:controller animated:YES];
	}
	else {
		EVEAPIKeysViewController* controller = [[EVEAPIKeysViewController alloc] initWithNibName:@"EVEAPIKeysViewController" bundle:nil];
		controller.apiKeys = apiKeys;
		controller.editing = self.editing;
		[self.viewController.navigationController pushViewController:controller animated:YES];
	}
}

#pragma mark - EVEAPIKeyCellDelegate

- (void) apiKeyCell:(EVEAPIKeyCell*) cell deleteButtonTapped:(UIButton*) button {
	[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackTranslucent
								   title:nil
					   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
				  destructiveButtonTitle:NSLocalizedString(@"Delete", nil)
					   otherButtonTitles:nil
						 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
							 if (selectedButtonIndex == actionSheet.destructiveButtonIndex) {
								 NSIndexPath* indexPath = [self.collectionView indexPathForCell:cell];
								 [[EVEAccountsManager sharedManager] removeAPIKeyWithKeyID:[self.apiKeys[indexPath.item] keyID]];
							 }
						 }
							 cancelBlock:nil] showFromRect:button.bounds inView:button animated:YES];
}

#pragma mark - Private

- (void) didChangeAccountsManager:(NSNotification*) notification {
	NSMutableArray* allAccounts = [NSMutableArray arrayWithArray:[notification.object allAccounts]];
	[allAccounts sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"character.characterName" ascending:YES]]];
	
	NSMutableArray* accounts = [[NSMutableArray alloc] init];
	
	for (EVEAccount* account in allAccounts) {
		if (!account.ignored)
			[accounts addObject:account];
	}

	NSArray* apiKeys = [[APIKey allAPIKeys] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"keyID" ascending:YES]]];
	
	[self.collectionView performBatchUpdates:^{
		NSMutableArray* deleteIndexes = [[NSMutableArray alloc] init];
		NSMutableArray* insertIndexes = [[NSMutableArray alloc] init];
		NSMutableArray* reloadIndexes = [[NSMutableArray alloc] init];
		
		for (id object in notification.userInfo[EVEAccountsManagerDeletedObjectsKey]) {
			if ([object isKindOfClass:[EVEAccount class]]) {
				NSInteger i = [(self.editing ? self.allAccounts : self.accounts) indexOfObject:object];
				if (i != NSNotFound)
					[deleteIndexes addObject:[NSIndexPath indexPathForItem:i inSection:0]];
			}
			else if ([object isKindOfClass:[APIKey class]] && self.editing) {
				NSInteger i = [self.apiKeys indexOfObject:object];
				if (i != NSNotFound)
					[deleteIndexes addObject:[NSIndexPath indexPathForItem:i inSection:1]];
			}
		}
		[self.collectionView deleteItemsAtIndexPaths:deleteIndexes];
		
		for (id object in notification.userInfo[EVEAccountsManagerInsertedObjectsKey]) {
			if ([object isKindOfClass:[EVEAccount class]]) {
				NSInteger i = [(self.editing ? allAccounts : accounts) indexOfObject:object];
				if (i != NSNotFound)
					[insertIndexes addObject:[NSIndexPath indexPathForItem:i inSection:0]];
			}
			else if ([object isKindOfClass:[APIKey class]] && self.editing) {
				NSInteger i = [apiKeys indexOfObject:object];
				if (i != NSNotFound)
					[insertIndexes addObject:[NSIndexPath indexPathForItem:i inSection:1]];
			}
		}
		[self.collectionView insertItemsAtIndexPaths:insertIndexes];
		
		for (id object in notification.userInfo[EVEAccountsManagerUpdatedObjectsKey]) {
			if ([object isKindOfClass:[EVEAccount class]]) {
				NSInteger i = [(self.editing ? self.allAccounts : self.accounts) indexOfObject:object];
				if (i != NSNotFound)
					[reloadIndexes addObject:[NSIndexPath indexPathForItem:i inSection:0]];
			}
			else if ([object isKindOfClass:[APIKey class]] && self.editing) {
				NSInteger i = [self.apiKeys indexOfObject:object];
				if (i != NSNotFound)
					[reloadIndexes addObject:[NSIndexPath indexPathForItem:i inSection:1]];
			}
		}
		[self.collectionView reloadItemsAtIndexPaths:reloadIndexes];

		
		self.allAccounts = allAccounts;
		self.accounts = accounts;
		self.apiKeys = apiKeys;
	} completion:nil];
}

@end
