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
#import "NCFittingSectionGenericHedaerView.h"

#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)
#define ActionButtonDelete NSLocalizedString(@"Delete", nil)
#define ActionButtonShowInfo NSLocalizedString(@"Show Info", nil)


@interface NCFittingShipImplantsDataSource()
@property (nonatomic, assign) std::vector<eufe::Implant*> implants;
@property (nonatomic, assign) std::vector<eufe::Booster*> boosters;

@end

@implementation NCFittingShipImplantsDataSource

- (void) reload {
	__block std::vector<eufe::Implant*> implants(10, nullptr);
	__block std::vector<eufe::Booster*> boosters(4, nullptr);
	
	[[self.controller taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
													title:NCTaskManagerDefaultTitle
													block:^(NCTask *task) {
														@synchronized(self.controller) {
															eufe::Character* character = self.controller.fit.pilot;
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
														}
													}
										completionHandler:^(NCTask *task) {
											if (![task isCancelled]) {
												self.implants = implants;
												self.boosters = boosters;
												
												if (self.tableView.dataSource == self)
													[self.tableView reloadData];
											}
										}];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return section == 0 ? self.implants.size() : self.boosters.size();
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	EVEDBInvType* type;
	if (indexPath.section == 0)
		type = [self.controller typeWithItem:self.implants[indexPath.row]];
	else
		type = [self.controller typeWithItem:self.boosters[indexPath.row]];
	
	NCTableViewCell *cell = (NCTableViewCell*) [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	
	if (!type) {
		cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Slot %d", nil), indexPath.row + 1];
		cell.imageView.image = [UIImage imageNamed:indexPath.section == 0 ? @"implant.png" : @"booster.png"];
	}
	else {
		cell.textLabel.text = type.typeName;
		cell.imageView.image = [UIImage imageNamed:[type typeSmallImageName]];
	}
	return cell;
	
}


#pragma mark -
#pragma mark Table view delegate

- (UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)sectionIndex {
	NCFittingSectionGenericHedaerView* header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NCFittingSectionGenericHedaerView"];
	if (sectionIndex == 0) {
		header.imageView.image = [UIImage imageNamed:@"implant.png"];
		header.titleLabel.text = NSLocalizedString(@"Implants", nil);
	}
	else {
		header.imageView.image = [UIImage imageNamed:@"booster.png"];
		header.titleLabel.text = NSLocalizedString(@"Boosters", nil);
	}
	return header;
}

/*- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 25;
}*/

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	
	EVEDBInvType* type;
	eufe::Item* item = nil;
	if (indexPath.section == 0)
		item = self.implants[indexPath.row];
	else
		item = self.boosters[indexPath.row];
	type = [self.controller typeWithItem:item];

	if (!type) {
		if (indexPath.section == 0) {
			NSArray* conditions = @[@"dgmTypeAttributes.typeID = invTypes.typeID",
									@"dgmTypeAttributes.attributeID = 331",
									[NSString stringWithFormat:@"dgmTypeAttributes.value = %d", indexPath.row + 1]];
			
			self.controller.typePickerViewController.title = NSLocalizedString(@"Implants", nil);
			[self.controller.typePickerViewController presentWithConditions:conditions
														   inViewController:self.controller
																   fromRect:cell.bounds
																	 inView:cell
																   animated:YES
														  completionHandler:^(EVEDBInvType *type) {
															  self.controller.fit.pilot->addImplant(type.typeID);
															  [self.controller reload];
															  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
																  [self.controller dismissAnimated];
														  }];
		}
		else {
			NSArray* conditions = @[@"dgmTypeAttributes.typeID = invTypes.typeID",
									@"dgmTypeAttributes.attributeID = 1087",
									[NSString stringWithFormat:@"dgmTypeAttributes.value = %d", indexPath.row + 1]];
			
			self.controller.typePickerViewController.title = NSLocalizedString(@"Boosters", nil);
			[self.controller.typePickerViewController presentWithConditions:conditions
														   inViewController:self.controller
																   fromRect:cell.bounds
																	 inView:cell
																   animated:YES
														  completionHandler:^(EVEDBInvType *type) {
															  self.controller.fit.pilot->addBooster(type.typeID);
															  [self.controller reload];
															  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
																  [self.controller dismissAnimated];
														  }];
		}
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
										 self.controller.fit.pilot->removeImplant(self.implants[indexPath.row]);
									 else
										 self.controller.fit.pilot->removeBooster(self.boosters[indexPath.row]);
									 [self.controller reload];
								 }
								 else if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
									 [self.controller performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController" sender:[NSValue valueWithPointer:item]];
								 }
							 } cancelBlock:nil] showFromRect:cell.bounds inView:cell animated:YES];
	}
}


@end
