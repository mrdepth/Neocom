//
//  NCFittingShipImplantsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 12.06.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCFittingShipImplantsViewController.h"
#import "NCFittingShipViewController.h"
#import "NCTableViewCell.h"
#import "NCFittingSectionGenericHeaderView.h"

#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)
#define ActionButtonDelete NSLocalizedString(@"Delete", nil)
#define ActionButtonShowInfo NSLocalizedString(@"Show Info", nil)
#define ActionButtonAffectingSkills NSLocalizedString(@"Affecting Skills", nil)


@interface NCFittingShipImplantsViewController()
@property (nonatomic, assign) std::vector<std::shared_ptr<dgmpp::Implant>> implants;
@property (nonatomic, assign) std::vector<std::shared_ptr<dgmpp::Booster>> boosters;

@end

@implementation NCFittingShipImplantsViewController

- (void) reloadWithCompletionBlock:(void (^)())completionBlock {
	auto pilot = self.controller.fit.pilot;
	if (pilot) {
		[self.controller.engine performBlock:^{
			std::vector<std::shared_ptr<dgmpp::Implant>> implants(10, nullptr);
			std::vector<std::shared_ptr<dgmpp::Booster>> boosters(4, nullptr);
			
			for (const auto& implant: pilot->getImplants()) {
				int slot = implant->getSlot() - 1;
				if (slot >= 0 && slot < 10)
					implants[slot] = implant;
			}
			
			for (const auto& booster: pilot->getBoosters()) {
				int slot = booster->getSlot() - 1;
				if (slot >= 0 && slot < 4)
					boosters[slot] = booster;
			}
			
			dispatch_async(dispatch_get_main_queue(), ^{
				self.implants = implants;
				self.boosters = boosters;
				completionBlock();
			});
		}];
	}
	else
		completionBlock();
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.controller.engine ? 3 : 0;
	//return self.view.window ? 3 : 0;
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
	if (sectionIndex == 0) {
		UIView* view = [[UIView alloc] initWithFrame:CGRectZero];
		view.backgroundColor = [UIColor clearColor];
		return view;
	}
	else {
		NCFittingSectionGenericHeaderView* header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NCFittingSectionGenericHeaderView"];
		if (sectionIndex == 1) {
			header.imageView.image = [UIImage imageNamed:@"implant"];
			header.titleLabel.text = NSLocalizedString(@"Implants", nil);
		}
		else {
			header.imageView.image = [UIImage imageNamed:@"booster"];
			header.titleLabel.text = NSLocalizedString(@"Boosters", nil);
		}
		return header;
	}
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return 0;
	else
		return 44;
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
		std::shared_ptr<dgmpp::Item> item = nullptr;
		
		if (indexPath.section == 1)
			item = self.implants[indexPath.row];
		else
			item = self.boosters[indexPath.row];
		NCDBInvType* type = item ? [self.databaseManagedObjectContext invTypeWithTypeID:item->getTypeID()] : nil;
		
		if (!type) {
			if (indexPath.section == 1) {
				self.controller.typePickerViewController.title = NSLocalizedString(@"Implants", nil);
				[self.controller.typePickerViewController presentWithCategory:[self.databaseManagedObjectContext categoryWithSlot:NCDBDgmppItemSlotImplant size:(int32_t) indexPath.row + 1 race:nil]
															 inViewController:self.controller
																	 fromRect:cell.bounds
																	   inView:cell
																	 animated:YES
															completionHandler:^(NCDBInvType *type) {
																[self.controller.engine performBlockAndWait:^{
																	self.controller.fit.pilot->addImplant(type.typeID);
																}];
																[self.controller reload];
																if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
																	[self.controller dismissAnimated];
															}];
			}
			else {
				self.controller.typePickerViewController.title = NSLocalizedString(@"Boosters", nil);
				[self.controller.typePickerViewController presentWithCategory:[self.databaseManagedObjectContext categoryWithSlot:NCDBDgmppItemSlotBooster size:(int32_t) indexPath.row + 1 race:nil]
															 inViewController:self.controller
																	 fromRect:cell.bounds
																	   inView:cell
																	 animated:YES
															completionHandler:^(NCDBInvType *type) {
																[self.controller.engine performBlockAndWait:^{
																	self.controller.fit.pilot->addBooster(type.typeID);
																}];
																[self.controller reload];
																if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
																	[self.controller dismissAnimated];
															}];
			}
		}
		else {
			UIAlertController* controller = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
			[controller addAction:[UIAlertAction actionWithTitle:ActionButtonDelete style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
				[self.controller.engine performBlockAndWait:^{
					if (indexPath.section == 1) {
						self.controller.fit.pilot->removeImplant(self.implants[indexPath.row]);
						_implants[indexPath.row] = nullptr;
					}
					else if (indexPath.section == 2) {
						self.controller.fit.pilot->removeBooster(self.boosters[indexPath.row]);
						_boosters[indexPath.row] = nullptr;
					}
				}];
				[self.controller reload];
			}]];
			[controller addAction:[UIAlertAction actionWithTitle:ActionButtonShowInfo style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				[self.controller performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController"
													 sender:@{@"sender": cell, @"object": [NCFittingEngineItemPointer pointerWithItem:item]}];
			}]];
			[controller addAction:[UIAlertAction actionWithTitle:ActionButtonAffectingSkills style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				[self.controller performSegueWithIdentifier:@"NCFittingShipAffectingSkillsViewController"
													 sender:@{@"sender": cell, @"object": @[[NCFittingEngineItemPointer pointerWithItem:item]]}];
			}]];
			[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}]];
			
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
				controller.modalPresentationStyle = UIModalPresentationPopover;
				[self presentViewController:controller animated:YES completion:nil];
				UITableViewCell* sender = cell;
				controller.popoverPresentationController.sourceView = sender;
				controller.popoverPresentationController.sourceRect = [sender bounds];
			}
			else
				[self presentViewController:controller animated:YES completion:nil];

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
			cell.iconView.image = [UIImage imageNamed:@"augmentations"];
		}
		else {
			cell.titleLabel.text = NSLocalizedString(@"Save Implant Set", nil);
			cell.iconView.image = [UIImage imageNamed:@"augmentations"];
		}
	}
	else {
		std::shared_ptr<dgmpp::Item> item = nullptr;
		
		if (indexPath.section == 1)
			item = self.implants[indexPath.row];
		else
			item = self.boosters[indexPath.row];
		
		NCDBInvType* type = item ? [self.databaseManagedObjectContext invTypeWithTypeID:item->getTypeID()] : nil;
		
		
		if (!type) {
			cell.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Slot %d", nil), (int32_t)(indexPath.row + 1)];
			cell.iconView.image = [UIImage imageNamed:indexPath.section == 1 ? @"implant" : @"booster"];
		}
		else {
			cell.titleLabel.text = type.typeName;
			cell.iconView.image = type.icon ? type.icon.image.image : self.defaultTypeImage;
		}
	}
}

@end
