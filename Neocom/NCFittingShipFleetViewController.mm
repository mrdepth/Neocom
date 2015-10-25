//
//  NCFittingShipFleetViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 12.06.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCFittingShipFleetViewController.h"
#import "NCFittingShipViewController.h"
#import "NCTableViewCell.h"
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

@interface NCFittingShipFleetViewController()
@property (nonatomic, strong) NSArray* fits;

- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath;
@end

@implementation NCFittingShipFleetViewController

- (void) reloadWithCompletionBlock:(void (^)())completionBlock {
	self.fits = self.controller.fits;
	completionBlock();
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.controller.engine ? 1 : 0;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.fits.count + 1;
}



#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == self.controller.fits.count)
		[self.controller performSegueWithIdentifier:@"NCFittingFitPickerViewController" sender:[tableView cellForRowAtIndexPath:indexPath]];
	else
		[self performActionForRowAtIndexPath:indexPath];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(NCDefaultTableViewCell*) cell forRowAtIndexPath:(NSIndexPath*) indexPath {
	if (indexPath.row >= self.controller.fits.count) {
		cell.iconView.image = [[[self.databaseManagedObjectContext eveIconWithIconFile:@"17_04"] image] image];
		cell.titleLabel.text = NSLocalizedString(@"Add Fleet Member", nil);
		cell.subtitleLabel.text = nil;
		cell.accessoryView = nil;
	}
	else {
		NCShipFit* fit = self.controller.fits[indexPath.row];
		__block NSString *booster = nil;
		__block NSString* characterName = nil;
		[self.controller.engine performBlockAndWait:^{
			auto gang = self.controller.engine.engine->getGang();
			if (!fit || !fit.pilot || !gang)
				return;
			
			auto fleetBooster = gang->getFleetBooster();
			auto wingBooster = gang->getWingBooster();
			auto squadBooster = gang->getSquadBooster();
			
			if (fit.pilot == fleetBooster)
				booster = NSLocalizedString(@" (Fleet Booster)", nil);
			else if (fit.pilot == wingBooster)
				booster = NSLocalizedString(@" (Wing Booster)", nil);
			else if (fit.pilot == squadBooster)
				booster = NSLocalizedString(@" (Squad Booster)", nil);
			else
				booster = @"";
			characterName = [NSString stringWithCString:fit.pilot->getCharacterName() encoding:NSUTF8StringEncoding];
		}];
		
		NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:fit.typeID];
		cell.titleLabel.text = [NSString stringWithFormat:@"%@ - %@%@", type.typeName, characterName, booster];
		cell.subtitleLabel.text = fit.loadoutName;
		cell.iconView.image = type.icon ? type.icon.image.image : self.defaultTypeImage;
		if (self.controller.fit == fit)
			cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark"]];
		else
			cell.accessoryView = nil;
	}
}

#pragma mark - Private

- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath {
	UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
	NCShipFit* fit = self.controller.fits[indexPath.row];
	
	NSMutableArray* actions = [NSMutableArray new];
	[self.controller.engine performBlockAndWait:^{
		auto character = fit.pilot;
		auto gang = self.controller.engine.engine->getGang();
		auto ship = character->getShip();
		
		if (self.fits.count > 1) {
			[actions addObject:[UIAlertAction actionWithTitle:ActionButtonDelete style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
				if (self.controller.fit == fit) {
					NSInteger i = [self.controller.fits indexOfObject:fit];
					if (i > 0)
						self.controller.fit = self.controller.fits[i - 1];
					else
						self.controller.fit = self.controller.fits[i + 1];
				}
				//[self.controller.fits removeObject:fit];
				[self.controller removeFit:fit];
				[self.controller.engine performBlockAndWait:^{
					gang->removePilot(character);
				}];
				[self.controller reload];
			}]];
		}
		
		[actions addObject:[UIAlertAction actionWithTitle:ActionButtonShowShipInfo style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[self.controller performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController"
												 sender:@{@"sender": cell, @"object": [NCFittingEngineItemPointer pointerWithItem:ship]}];
		}]];
		
		[actions addObject:[UIAlertAction actionWithTitle:ActionButtonCharacter style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[self.controller performSegueWithIdentifier:@"NCFittingCharacterPickerViewController"
												 sender:@{@"sender": cell, @"object": fit}];
		}]];
		
		if (fit != self.controller.fit) {
			[actions addObject:[UIAlertAction actionWithTitle:ActionButtonSelect style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				self.controller.fit = fit;
				[self.controller reload];
			}]];
		}
		
		NSMutableArray* boosterActions = [NSMutableArray new];
		bool isBooster = false;
		
		if (gang->getFleetBooster() != character)
			[boosterActions addObject:[UIAlertAction actionWithTitle:ActionButtonSetFleetBooster style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				[self.controller.engine performBlockAndWait:^{
					gang->setFleetBooster(character);
				}];
				[self.controller reload];
			}]];
		else
			isBooster = true;
		
		if (gang->getWingBooster() != character)
			[boosterActions addObject:[UIAlertAction actionWithTitle:ActionButtonSetWingBooster style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				[self.controller.engine performBlockAndWait:^{
					gang->setWingBooster(character);
				}];
				[self.controller reload];
			}]];
		else
			isBooster = true;
		
		if (gang->getSquadBooster() != character)
			[boosterActions addObject:[UIAlertAction actionWithTitle:ActionButtonSetSquadBooster style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				[self.controller.engine performBlockAndWait:^{
					gang->setSquadBooster(character);
				}];
				[self.controller reload];
			}]];
		else
			isBooster = true;
		
		//void (^removeBoosterHandler)(UIAlertAction* _Nonnull) = ^(UIAlertAction * _Nonnull action) {
		auto removeBoosterHandler = ^(UIAlertAction * _Nonnull action) {
			[self.controller.engine performBlockAndWait:^{
				if (gang->getFleetBooster() == character)
					gang->removeFleetBooster();
				else if (gang->getWingBooster() == character)
					gang->removeWingBooster();
				else if (gang->getSquadBooster() == character)
					gang->removeSquadBooster();
			}];
			[self.controller reload];
		};
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			if (isBooster)
				[boosterActions addObject:[UIAlertAction actionWithTitle:ActionButtonRemoveBooster style:UIAlertActionStyleDefault handler:removeBoosterHandler]];
			[actions addObjectsFromArray:boosterActions];
		}
		else {
			[actions addObject:[UIAlertAction actionWithTitle:ActionButtonBooster style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				UIAlertController* controller = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
				if (isBooster)
					[controller addAction:[UIAlertAction actionWithTitle:ActionButtonRemoveBooster style:UIAlertActionStyleDestructive handler:removeBoosterHandler]];
				for (UIAlertAction* action in boosterActions)
					[controller addAction:action];
				[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}]];
				[self.controller presentViewController:controller animated:YES completion:nil];
			}]];
		}
	}];
	
	UIAlertController* controller = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	for (UIAlertAction* action in actions)
		[controller addAction:action];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}]];
	[self.controller presentViewController:controller animated:YES completion:nil];
}



@end
