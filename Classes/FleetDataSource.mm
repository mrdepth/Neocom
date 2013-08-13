//
//  FleetDataSource.m
//  EVEUniverse
//
//  Created by mr_depth on 06.08.13.
//
//

#import "FleetDataSource.h"
#import "FittingViewController.h"
#import "ModuleCellView.h"
#import "UITableViewCell+Nib.h"
#import "EUOperationQueue.h"
#import "UIActionSheet+Block.h"
#import "UIActionSheet+Neocom.h"
#import "ItemViewController.h"
#import "CharactersViewController.h"
#import "UIViewController+Neocom.h"

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

@interface FleetDataSource()
@property (nonatomic, strong) NSMutableArray* pilots;
- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath;
@end

@implementation FleetDataSource

- (void) reload {
	NSMutableArray* pilotsTmp = [NSMutableArray array];
	EUOperation *operation = [EUOperation operationWithIdentifier:@"FleetDataSource+reload" name:NSLocalizedString(@"Updating Fleet", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		@synchronized(self.fittingViewController) {
			eufe::Gang* gang = self.fittingViewController.fittingEngine->getGang();
			
			eufe::Character* fleetBooster = gang->getFleetBooster();
			eufe::Character* wingBooster = gang->getWingBooster();
			eufe::Character* squadBooster = gang->getSquadBooster();
			
			//for (i = characters.begin(); i != end; i++) {
			float n = self.fittingViewController.fits.count;
			float i = 0;
			for (ShipFit* fit in self.fittingViewController.fits) {
				weakOperation.progress = i++ / n;
				eufe::Character* character = fit.character;
				ItemInfo* ship = [ItemInfo itemInfoWithItem:character->getShip() error:NULL];
				NSString *booster = nil;
				
				if (character == fleetBooster)
					booster = NSLocalizedString(@" (Fleet Booster)", nil);
				else if (character == wingBooster)
					booster = NSLocalizedString(@" (Wing Booster)", nil);
				else if (character == squadBooster)
					booster = NSLocalizedString(@" (Squad Booster)", nil);
				else
					booster = @"";
				
				NSMutableDictionary* row = [NSMutableDictionary dictionaryWithObjectsAndKeys:ship, @"ship",
											fit, @"fit",
											[NSString stringWithFormat:@"%@ - %s%@", ship.typeName, character->getCharacterName(), booster], @"title",
											fit.fitName ? fit.fitName : ship.typeName, @"fitName", nil];
				[pilotsTmp addObject:row];
			}
		}
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.pilots = pilotsTmp;
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
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.pilots.count + 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"Cell";
	GroupedCell *cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
	}

	if (indexPath.row >= self.pilots.count) {
		cell.imageView.image = [UIImage imageNamed:@"Icons/icon17_04.png"];
		cell.textLabel.text = NSLocalizedString(@"Add Fleet Member", nil);
		cell.detailTextLabel.text = nil;
		cell.accessoryView = nil;
	}
	else {
		
		NSDictionary* row = self.pilots[indexPath.row];
		ItemInfo* ship = row[@"ship"];
		cell.textLabel.text = row[@"title"];
		cell.detailTextLabel.text = row[@"fitName"];
		cell.imageView.image = [UIImage imageNamed:[ship typeSmallImageName]];
		if (self.fittingViewController.fit == row[@"fit"])
			cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]];
		else
			cell.accessoryView = nil;
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

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 40;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (indexPath.row == self.pilots.count) {
		FitsViewController* controller = [[FitsViewController alloc] initWithNibName:@"FitsViewController" bundle:nil];
		controller.engine = self.fittingViewController.fittingEngine;
		controller.delegate = self;
		UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
		navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
		[self.fittingViewController presentViewController:navigationController animated:YES completion:nil];
	}
	else {
		[self performActionForRowAtIndexPath:indexPath];
	}
}

#pragma mark FitsViewControllerDelegate

- (void) fitsViewController:(FitsViewController*) aController didSelectFit:(ShipFit*) fit {
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
}

#pragma mark - Private

- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath {
	ShipFit* fit = self.pilots[indexPath.row][@"fit"];
	eufe::Character* character = fit.character;
	eufe::Gang* gang = self.fittingViewController.fittingEngine->getGang();
	
	void (^setFleetBooster)() = ^(){
		gang->setFleetBooster(character);
		[self.fittingViewController update];
	};
	
	void (^setWingBooster)() = ^(){
		gang->setWingBooster(character);
		[self.fittingViewController update];
	};
	
	void (^setSquadBooster)() = ^(){
		gang->setFleetBooster(character);
		[self.fittingViewController update];
	};
	
	void (^removeBooster)() = ^(){
		if (gang->getFleetBooster() == character)
			gang->removeFleetBooster();
		else if (gang->getWingBooster() == character)
			gang->removeWingBooster();
		else if (gang->getSquadBooster() == character)
			gang->removeSquadBooster();
		[self.fittingViewController update];
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
		[self.fittingViewController.fits removeObject:fit];
		gang->removePilot(character);
		[self.fittingViewController update];
	};
	
	void (^setCharacter)() = ^(){
		CharactersViewController *controller = [[CharactersViewController alloc] initWithNibName:@"CharactersViewController" bundle:nil];
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];

		controller.completionHandler = ^(id<Character> character) {
			eufe::Character* eufeCharacter = fit.character;
			eufeCharacter->setSkillLevels(*[character skillsMap]);
			eufeCharacter->setCharacterName([character.name cStringUsingEncoding:NSUTF8StringEncoding]);
			[self.fittingViewController update];
		};

		navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
		[self.fittingViewController presentViewController:navigationController animated:YES completion:nil];
	};

	
	void (^select)() = ^(){
		self.fittingViewController.fit = fit;
		[self.fittingViewController update];
	};
	
	void (^booster)() = ^(){
		[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackOpaque
									   title:nil
						   cancelButtonTitle:NSLocalizedString(@"Cancel", )
					  destructiveButtonTitle:isBooster && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? ActionButtonRemoveBooster : nil
						   otherButtonTitles:boosterButtons
							 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
								 if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
									 void (^block)() = boosterActions[selectedButtonIndex];
									 block();
								 }
							 } cancelBlock:nil] showInWindowFromRect:[self.tableView rectForRowAtIndexPath:indexPath] inView:self.tableView animated:YES];
	};
	


	void (^showInfo)(NSArray*) = ^(NSArray* modules){
		ItemInfo* itemInfo = self.pilots[indexPath.row][@"ship"];
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
			[self.fittingViewController.navigationController pushViewController:itemViewController animated:YES];
	};
	
	NSMutableArray* buttons = [NSMutableArray new];
	NSMutableArray* actions = [NSMutableArray new];
	
	[actions addObject:remove];
	
	[buttons addObject:ActionButtonShowShipInfo];
	[actions addObject:showInfo];
	
	[buttons addObject:ActionButtonCharacter];
	[actions addObject:setCharacter];
	
	if (fit != self.fittingViewController.fit) {
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
	
	[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackOpaque
								   title:nil
					   cancelButtonTitle:NSLocalizedString(@"Cancel", )
				  destructiveButtonTitle:ActionButtonDelete
					   otherButtonTitles:buttons
						 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
							 if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
								 void (^block)() = actions[selectedButtonIndex];
								 block();
							 }
						 } cancelBlock:nil] showInWindowFromRect:[self.tableView rectForRowAtIndexPath:indexPath] inView:self.tableView animated:YES];
	
}

@end
