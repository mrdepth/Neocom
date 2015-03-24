//
//  NCFittingShipImplantsDataSource.m
//  Neocom
//
//  Created by Артем Шиманский on 29.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingShipImplantsDataSource.h"
#import "NCFittingShipViewController.h"
#import "NCTableViewCell.h"
#import "UIActionSheet+Block.h"
#import "NCFittingSectionGenericHeaderView.h"

#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)
#define ActionButtonDelete NSLocalizedString(@"Delete", nil)
#define ActionButtonShowInfo NSLocalizedString(@"Show Info", nil)
#define ActionButtonAffectingSkills NSLocalizedString(@"Affecting Skills", nil)


@interface NCFittingShipImplantsDataSource()
@property (nonatomic, assign) std::vector<eufe::Implant*> implants;
@property (nonatomic, assign) std::vector<eufe::Booster*> boosters;
@property (nonatomic, strong) NCTableViewCell* offscreenCell;

- (void) tableView:(UITableView *)tableView configureCell:(NCTableViewCell*) cell forRowAtIndexPath:(NSIndexPath*) indexPath;

@end

@implementation NCFittingShipImplantsDataSource

- (void) reload {
	__block std::vector<eufe::Implant*> implants(10, nullptr);
	__block std::vector<eufe::Booster*> boosters(4, nullptr);
	
	eufe::Character* character = self.controller.fit.pilot;
	if (!character)
		return;
	
	for (auto implant: character->getImplants()) {
		int slot = implant->getSlot() - 1;
		if (slot >= 0 && slot < 10)
			implants[slot] = implant;
	}
	
	for (auto booster: character->getBoosters()) {
		int slot = booster->getSlot() - 1;
		if (slot >= 0 && slot < 4)
			boosters[slot] = booster;
	}

	self.implants = implants;
	self.boosters = boosters;
	
	if (self.tableView.dataSource == self)
		[self.tableView reloadData];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	if (section == 0)
		return 2;
	else if (section == 1)
		return self.implants.size();
	else
		return self.boosters.size();
}


#pragma mark -
#pragma mark Table view delegate

- (UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)sectionIndex {
	if (sectionIndex == 0)
		return nil;
	else {
		NCFittingSectionGenericHeaderView* header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NCFittingSectionGenericHeaderView"];
		if (sectionIndex == 1) {
			header.imageView.image = [UIImage imageNamed:@"implant.png"];
			header.titleLabel.text = NSLocalizedString(@"Implants", nil);
		}
		else {
			header.imageView.image = [UIImage imageNamed:@"booster.png"];
			header.titleLabel.text = NSLocalizedString(@"Boosters", nil);
		}
		return header;
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	
	if (indexPath.section == 0) {
		if (indexPath.row == 0)
			[self.controller performSegueWithIdentifier:@"NCFittingImplantSetsViewControllerImport" sender:cell];
		else
			[self.controller performSegueWithIdentifier:@"NCFittingImplantSetsViewControllerSave" sender:cell];
	}
	else {
		NCDBInvType* type;
		eufe::Item* item = nil;
		
		if (indexPath.section == 1)
			item = self.implants[indexPath.row];
		else
			item = self.boosters[indexPath.row];
		type = [self.controller typeWithItem:item];
		
		if (!type) {
			if (indexPath.section == 1) {
				self.controller.typePickerViewController.title = NSLocalizedString(@"Implants", nil);
				[self.controller.typePickerViewController presentWithCategory:[NCDBEufeItemCategory categoryWithSlot:NCDBEufeItemSlotImplant size:(int32_t) indexPath.row + 1 race:nil]
															 inViewController:self.controller
																	 fromRect:cell.bounds
																	   inView:cell
																	 animated:YES
															completionHandler:^(NCDBInvType *type) {
																self.controller.fit.pilot->addImplant(type.typeID);
																[self.controller reload];
																if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
																	[self.controller dismissAnimated];
															}];
			}
			else {
				self.controller.typePickerViewController.title = NSLocalizedString(@"Boosters", nil);
				[self.controller.typePickerViewController presentWithCategory:[NCDBEufeItemCategory categoryWithSlot:NCDBEufeItemSlotBooster size:(int32_t) indexPath.row + 1 race:nil]
															 inViewController:self.controller
																	 fromRect:cell.bounds
																	   inView:cell
																	 animated:YES
															completionHandler:^(NCDBInvType *type) {
																self.controller.fit.pilot->addBooster(type.typeID);
																[self.controller reload];
																if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
																	[self.controller dismissAnimated];
															}];
			}
		}
		else {
			[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackTranslucent
										   title:nil
							   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
						  destructiveButtonTitle:ActionButtonDelete
							   otherButtonTitles:@[ActionButtonShowInfo, ActionButtonAffectingSkills]
								 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
									 if (selectedButtonIndex == actionSheet.destructiveButtonIndex) {
										 if (indexPath.section == 1) {
											 self.controller.fit.pilot->removeImplant(self.implants[indexPath.row]);
											 _implants[indexPath.row] = nullptr;
										 }
										 else if (indexPath.section == 2) {
											 self.controller.fit.pilot->removeBooster(self.boosters[indexPath.row]);
											 _boosters[indexPath.row] = nullptr;
										 }
										 [self.controller reload];
									 }
									 else if (selectedButtonIndex == 1) {
										 [self.controller performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController"
																			  sender:@{@"sender": cell, @"object": [NSValue valueWithPointer:item]}];
									 }
									 else if (selectedButtonIndex == 2) {
										 [self.controller performSegueWithIdentifier:@"NCFittingShipAffectingSkillsViewController"
																			  sender:@{@"sender": cell, @"object": [NSValue valueWithPointer:item]}];
									 }
								 } cancelBlock:nil] showFromRect:cell.bounds inView:cell animated:YES];
		}
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(NCDefaultTableViewCell*) cell forRowAtIndexPath:(NSIndexPath*) indexPath {
	cell.subtitleLabel.text = nil;
	cell.accessoryView = nil;
	
	if (indexPath.section == 0) {
		if (indexPath.row == 0) {
			cell.titleLabel.text = NSLocalizedString(@"Import Implant Set", nil);
			cell.iconView.image = [UIImage imageNamed:@"implant.png"];
		}
		else {
			cell.titleLabel.text = NSLocalizedString(@"Save Implant Set", nil);
			cell.iconView.image = [UIImage imageNamed:@"implant.png"];
		}
	}
	else {
		NCDBInvType* type;
		if (indexPath.section == 1)
			type = [self.controller typeWithItem:self.implants[indexPath.row]];
		else
			type = [self.controller typeWithItem:self.boosters[indexPath.row]];
		
		
		if (!type) {
			cell.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Slot %d", nil), (int32_t)(indexPath.row + 1)];
			cell.iconView.image = [UIImage imageNamed:indexPath.section == 1 ? @"implant.png" : @"booster.png"];
		}
		else {
			cell.titleLabel.text = type.typeName;
			cell.iconView.image = type.icon ? type.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
		}
	}
}

@end
