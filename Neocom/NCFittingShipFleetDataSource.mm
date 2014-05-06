//
//  NCFittingShipFleetDataSource.m
//  Neocom
//
//  Created by Артем Шиманский on 31.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingShipFleetDataSource.h"
#import "NCFittingShipViewController.h"
#import "NCTableViewCell.h"
#import "UIActionSheet+Block.h"
#import "NCFittingCharacterPickerViewController.h"

#define ActionButtonCharacter NSLocalizedString(@"Switch Character", nil)
#define ActionButtonDelete NSLocalizedString(@"Delete", nil)
#define ActionButtonSelect NSLocalizedString(@"Set Active Ship", nil)
#define ActionButtonShowShipInfo NSLocalizedString(@"Ship Info", nil)
#define ActionButtonAddShip NSLocalizedString(@"Add Ship", nil)
#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)
#define ActionButtonBooster NSLocalizedString(@"Booster", nil)
#define ActionButtonSetFleetBooster NSLocalizedString(@"Set Fleet Booster", nil)
#define ActionButtonSetWingBooster NSLocalizedString(@"Set Wing Booster", nil)
#define ActionButtonSetSquadBooster NSLocalizedString(@"Set Squad Booster", nil)
#define ActionButtonRemoveBooster NSLocalizedString(@"Remove Booster", nil)

@interface NCFittingShipFleetDataSource()
@property (nonatomic, strong) NCTableViewCell* offscreenCell;

- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath;
- (void) tableView:(UITableView *)tableView configureCell:(NCTableViewCell*) cell forRowAtIndexPath:(NSIndexPath*) indexPath;
@end

@implementation NCFittingShipFleetDataSource

- (void) reload {
	if (self.tableView.dataSource == self)
		[self.tableView reloadData];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.controller.fits.count + 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCTableViewCell *cell = (NCTableViewCell*) [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 41;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	if (!self.offscreenCell)
		self.offscreenCell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	[self tableView:tableView configureCell:self.offscreenCell forRowAtIndexPath:indexPath];
	self.offscreenCell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(self.offscreenCell.bounds));
	[self.offscreenCell layoutIfNeeded];
	return [self.offscreenCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.5;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == self.controller.fits.count) {
		[self.controller performSegueWithIdentifier:@"NCFittingFitPickerViewController" sender:[tableView cellForRowAtIndexPath:indexPath]];
	}
	else {
		[self performActionForRowAtIndexPath:indexPath];
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark FitsViewControllerDelegate

/*- (void) fitsViewController:(FitsViewController*) aController didSelectFit:(ShipFit*) fit {
	if (![self.fittingViewController.fits containsObject:fit]) {
		eufe::Character* character = fit.character;
		self.fittingViewController.fittingEngine->getGang()->addPilot(character);
		[self.fittingViewController.fits addObject:fit];
		
		eufe::DamagePattern eufeDamagePattern;
		eufeDamagePattern.emAmount = self.fittingViewController.damagePattern.emAmount;
		eufeDamagePattern.thermalAmount = self.fittingViewController.damagePattern.thermalAmount;
		eufeDamagePattern.kineticAmount = self.fittingViewController.damagePattern.kineticAmount;
		eufeDamagePattern.explosiveAmount = self.fittingViewController.damagePattern.explosiveAmount;
		character->getShip()->setDamagePattern(eufeDamagePattern);
		[self.fittingViewController update];
	}
	[self.fittingViewController dismiss];
}*/

#pragma mark - Private

- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath {
	UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
	NCShipFit* fit = self.controller.fits[indexPath.row];
	eufe::Character* character = fit.pilot;
	eufe::Gang* gang = self.controller.engine->getGang();
	
	void (^setFleetBooster)() = ^(){
		gang->setFleetBooster(character);
		[self.controller reload];
	};
	
	void (^setWingBooster)() = ^(){
		gang->setWingBooster(character);
		[self.controller reload];
	};
	
	void (^setSquadBooster)() = ^(){
		gang->setFleetBooster(character);
		[self.controller reload];
	};
	
	void (^removeBooster)() = ^(){
		if (gang->getFleetBooster() == character)
			gang->removeFleetBooster();
		else if (gang->getWingBooster() == character)
			gang->removeWingBooster();
		else if (gang->getSquadBooster() == character)
			gang->removeSquadBooster();
		[self.controller reload];
	};
	
	NSMutableArray* boosterButtons = [NSMutableArray new];
	NSMutableArray* boosterActions = [NSMutableArray new];
	
	bool isBooster = false;
	if (gang->getFleetBooster() != character) {
		[boosterButtons addObject:ActionButtonSetFleetBooster];
		[boosterActions addObject:setFleetBooster];
	}
	else
		isBooster = true;
	
	if (gang->getWingBooster() != character) {
		[boosterButtons addObject:ActionButtonSetWingBooster];
		[boosterActions addObject:setWingBooster];
	}
	else
		isBooster = true;
	
	if (gang->getSquadBooster() != character) {
		[boosterButtons addObject:ActionButtonSetSquadBooster];
		[boosterActions addObject:setSquadBooster];
	}
	else
		isBooster = true;
	
	if (isBooster && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
		[boosterActions insertObject:removeBooster atIndex:0];
	
	void (^remove)() = ^(){
		[self.controller.fits removeObject:fit];
		gang->removePilot(character);
		[self.controller reload];
	};
	
	void (^setCharacter)() = ^(){
		[self.controller performSegueWithIdentifier:@"NCFittingCharacterPickerViewController"
											 sender:@{@"sender": cell, @"object": fit}];
	};
	
	
	void (^select)() = ^(){
		self.controller.fit = fit;
		[self.controller reload];
	};
	
	void (^booster)() = ^(){
		[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackTranslucent
									   title:nil
						   cancelButtonTitle:NSLocalizedString(@"Cancel", )
					  destructiveButtonTitle:isBooster && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? ActionButtonRemoveBooster : nil
						   otherButtonTitles:boosterButtons
							 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
								 if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
									 void (^block)() = boosterActions[selectedButtonIndex];
									 block();
								 }
							 } cancelBlock:nil] showFromRect:cell.bounds inView:cell animated:YES];
	};
	
	
	
	void (^showInfo)(NSArray*) = ^(NSArray* modules){
/*		ItemInfo* itemInfo = self.pilots[indexPath.row][@"ship"];
		ItemViewController *itemViewController = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		[itemInfo updateAttributes];
		itemViewController.type = itemInfo;
		[itemViewController setActivePage:ItemViewControllerActivePageInfo];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:itemViewController];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self.fittingViewController presentViewController:navController animated:YES completion:nil];
		}
		else
			[self.fittingViewController.navigationController pushViewController:itemViewController animated:YES];*/
	};
	
	NSMutableArray* buttons = [NSMutableArray new];
	NSMutableArray* actions = [NSMutableArray new];
	
	[actions addObject:remove];
	
	[buttons addObject:ActionButtonShowShipInfo];
	[actions addObject:showInfo];
	
	[buttons addObject:ActionButtonCharacter];
	[actions addObject:setCharacter];
	
	if (fit != self.controller.fit) {
		[buttons addObject:ActionButtonSelect];
		[actions addObject:select];
	}
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[buttons addObjectsFromArray:boosterButtons];
		[actions addObjectsFromArray:boosterActions];
	}
	else {
		[buttons addObject:ActionButtonBooster];
		[actions addObject:booster];
	}
	
	[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackTranslucent
								   title:nil
					   cancelButtonTitle:NSLocalizedString(@"Cancel", )
				  destructiveButtonTitle:ActionButtonDelete
					   otherButtonTitles:buttons
						 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
							 if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
								 void (^block)() = actions[selectedButtonIndex];
								 block();
							 }
						 } cancelBlock:nil] showFromRect:cell.bounds inView:cell animated:YES];
	
}

- (void) tableView:(UITableView *)tableView configureCell:(NCTableViewCell*) cell forRowAtIndexPath:(NSIndexPath*) indexPath {
	if (indexPath.row >= self.controller.fits.count) {
		cell.iconView.image = [UIImage imageNamed:@"Icons/icon17_04.png"];
		cell.titleLabel.text = NSLocalizedString(@"Add Fleet Member", nil);
		cell.subtitleLabel.text = nil;
		cell.accessoryView = nil;
	}
	else {
		@synchronized(self.controller) {
			NCShipFit* fit = self.controller.fits[indexPath.row];
			eufe::Gang* gang = self.controller.engine->getGang();
			
			eufe::Character* fleetBooster = gang->getFleetBooster();
			eufe::Character* wingBooster = gang->getWingBooster();
			eufe::Character* squadBooster = gang->getSquadBooster();
			
			NSString *booster = nil;
			
			if (fit.pilot == fleetBooster)
				booster = NSLocalizedString(@" (Fleet Booster)", nil);
			else if (fit.pilot == wingBooster)
				booster = NSLocalizedString(@" (Wing Booster)", nil);
			else if (fit.pilot == squadBooster)
				booster = NSLocalizedString(@" (Squad Booster)", nil);
			else
				booster = @"";
			
			
			cell.titleLabel.text = [NSString stringWithFormat:@"%@ - %s%@", fit.type.typeName, fit.pilot->getCharacterName(), booster];
			cell.subtitleLabel.text = fit.loadoutName;
			cell.iconView.image = [UIImage imageNamed:[fit.type typeSmallImageName]];
			if (self.controller.fit == fit)
				cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]];
			else
				cell.accessoryView = nil;
		}
	}
}

@end
