//
//  ImplantsDataSource.m
//  EVEUniverse
//
//  Created by mr_depth on 06.08.13.
//
//

#import "ImplantsDataSource.h"
#import "FittingViewController.h"
#import "ModuleCellView.h"
#import "UITableViewCell+Nib.h"
#import "EUOperationQueue.h"
#import "UIActionSheet+Block.h"
#import "UIActionSheet+Neocom.h"
#import "ItemViewController.h"
#import "UIViewController+Neocom.h"

#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)
#define ActionButtonDelete NSLocalizedString(@"Delete", nil)
#define ActionButtonShowInfo NSLocalizedString(@"Show Info", nil)

@interface ImplantsDataSource()
@property (nonatomic, strong) NSMutableDictionary *implants;
@property (nonatomic, strong) NSMutableDictionary *boosters;

@end

@implementation ImplantsDataSource

- (void) reload {
	NSMutableDictionary *implantsTmp = [NSMutableDictionary dictionary];
	NSMutableDictionary *boostersTmp = [NSMutableDictionary dictionary];
	
	EUOperation *operation = [EUOperation operationWithIdentifier:@"ImplantsDataSource+reload" name:NSLocalizedString(@"Updating Implants", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		@synchronized(self.fittingViewController) {
			eufe::Character* character = self.fittingViewController.fit.character;
			const eufe::ImplantsList& implantsList = character->getImplants();
			eufe::ImplantsList::const_iterator i, end = implantsList.end();
			for (i = implantsList.begin(); i != end; i++)
				[implantsTmp setValue:[ItemInfo itemInfoWithItem:*i error:nil] forKey:[NSString stringWithFormat:@"%d", (*i)->getSlot()]];
			
			const eufe::BoostersList& boostersList = character->getBoosters();
			eufe::BoostersList::const_iterator j, endj = boostersList.end();
			for (j = boostersList.begin(); j != endj; j++)
				[boostersTmp setValue:[ItemInfo itemInfoWithItem:*j error:nil] forKey:[NSString stringWithFormat:@"%d", (*j)->getSlot()]];
		}
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.implants = implantsTmp;
			self.boosters = boostersTmp;
			if (self.tableView.dataSource == self)
				[self.tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return section == 0 ? 10 : 4;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	ItemInfo* itemInfo = nil;
	if (indexPath.section == 0)
		itemInfo = [self.implants valueForKey:[NSString stringWithFormat:@"%d", indexPath.row + 1]];
	else
		itemInfo = [self.boosters valueForKey:[NSString stringWithFormat:@"%d", indexPath.row + 1]];
	static NSString *cellIdentifier = @"ModuleCellView";
	ModuleCellView *cell = (ModuleCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [ModuleCellView cellWithNibName:@"ModuleCellView" bundle:nil reuseIdentifier:cellIdentifier];
	}

	if (!itemInfo) {
		cell.iconView.image = [UIImage imageNamed:indexPath.section == 0 ? @"implant.png" : @"booster.png"];
		cell.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Slot %d", nil), indexPath.row + 1];
		cell.stateView.image = nil;
	}
	else {
		cell.stateView.image = [UIImage imageNamed:@"active.png"];
		
		cell.titleLabel.text = itemInfo.typeName;
		cell.iconView.image = [UIImage imageNamed:[itemInfo typeSmallImageName]];
	}
	
	int groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = static_cast<GroupedCellGroupStyle>(groupStyle);
	return cell;

}


#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return self.implantsHeaderView;
	else
		return self.boostersHeaderView;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 25;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 40;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
	
	ItemInfo* itemInfo = nil;
	if (indexPath.section == 0)
		itemInfo = [self.implants valueForKey:[NSString stringWithFormat:@"%d", indexPath.row + 1]];
	else
		itemInfo = [self.boosters valueForKey:[NSString stringWithFormat:@"%d", indexPath.row + 1]];
	
	
	if (!itemInfo) {
		if (indexPath.section == 0) {
			self.fittingViewController.itemsViewController.conditions = @[@"dgmTypeAttributes.typeID = invTypes.typeID",
																 @"dgmTypeAttributes.attributeID = 331",
																 [NSString stringWithFormat:@"dgmTypeAttributes.value = %d", indexPath.row + 1]];
			self.fittingViewController.itemsViewController.title = NSLocalizedString(@"Implants", nil);
			self.fittingViewController.itemsViewController.completionHandler = ^(EVEDBInvType* type) {
				self.fittingViewController.fit.character->addImplant(type.typeID);
				[self.fittingViewController update];
				if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
					[self.fittingViewController dismiss];
			};
		}
		else {
			self.fittingViewController.itemsViewController.conditions = @[@"dgmTypeAttributes.typeID = invTypes.typeID",
																 @"dgmTypeAttributes.attributeID = 1087",
																 [NSString stringWithFormat:@"dgmTypeAttributes.value = %d", indexPath.row + 1]];
			self.fittingViewController.itemsViewController.title = NSLocalizedString(@"Boosters", nil);
			self.fittingViewController.itemsViewController.completionHandler = ^(EVEDBInvType* type) {
				self.fittingViewController.fit.character->addBooster(type.typeID);
				[self.fittingViewController update];
				if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
					[self.fittingViewController dismiss];
			};

		}
		[self.fittingViewController presentViewController:self.fittingViewController.itemsViewController animated:YES completion:nil];
	}
	else {
		[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackOpaque
									   title:nil
						   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
					  destructiveButtonTitle:ActionButtonDelete
						   otherButtonTitles:@[ActionButtonShowInfo]
							 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
								 if (selectedButtonIndex == actionSheet.destructiveButtonIndex) {
									 if (indexPath.section == 0)
										 self.fittingViewController.fit.character->removeImplant(dynamic_cast<eufe::Implant*>(itemInfo.item));
									 else
										 self.fittingViewController.fit.character->removeBooster(dynamic_cast<eufe::Booster*>(itemInfo.item));
									 [self.fittingViewController update];
								 }
								 else if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
									 ItemViewController *itemViewController = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
									 [itemInfo updateAttributes];
									 itemViewController.type = itemInfo;
									 [itemViewController setActivePage:ItemViewControllerActivePageInfo];
									 if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
										 UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:itemViewController];
										 navController.modalPresentationStyle = UIModalPresentationFormSheet;
										 [self.fittingViewController presentModalViewController:navController animated:YES];
									 }
									 else
										 [self.fittingViewController.navigationController pushViewController:itemViewController animated:YES];
								 }
							 } cancelBlock:nil] showInWindowFromRect:[self.tableView rectForRowAtIndexPath:indexPath] inView:self.tableView animated:YES];
	}
}

@end
