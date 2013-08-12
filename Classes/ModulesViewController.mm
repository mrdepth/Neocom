//
//  ModulesViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ModulesViewController.h"
#import "FittingViewController.h"
#import "ModuleCellView.h"
#import "UITableViewCell+Nib.h"
#import "FittingItemsViewController.h"
#import "NSString+Fitting.h"
#import "ItemViewController.h"
#import "EUOperationQueue.h"
#import "ShipFit.h"
#import "EVEDBAPI.h"
#import "NSString+TimeLeft.h"
#import "UIActionSheet+Block.h"

#import "ItemInfo.h"

#include <algorithm>

#define ActionButtonOffline NSLocalizedString(@"Put Offline", nil)
#define ActionButtonOnline NSLocalizedString(@"Put Online", nil)
#define ActionButtonOverheatOn NSLocalizedString(@"Enable Overheating", nil)
#define ActionButtonOverheatOff NSLocalizedString(@"Disable Overheating", nil)
#define ActionButtonActivate NSLocalizedString(@"Activate", nil)
#define ActionButtonDeactivate NSLocalizedString(@"Deactivate", nil)
#define ActionButtonAmmo NSLocalizedString(@"Ammo", nil)
#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)
#define ActionButtonDelete NSLocalizedString(@"Delete", nil)
#define ActionButtonChangeState NSLocalizedString(@"Change State", nil)
#define ActionButtonUnloadAmmo NSLocalizedString(@"Unload Ammo", nil)
#define ActionButtonShowModuleInfo NSLocalizedString(@"Show Module Info", nil)
#define ActionButtonShowAmmoInfo NSLocalizedString(@"Show Ammo Info", nil)
#define ActionButtonSetTarget NSLocalizedString(@"Set Target", nil)
#define ActionButtonClearTarget NSLocalizedString(@"Clear Target", nil)
#define ActionButtonVariations NSLocalizedString(@"Variations", nil)
#define ActionButtonAllSimilarModules NSLocalizedString(@"All Similar Modules", nil)

@interface ModulesViewController()
@property(nonatomic, strong) NSMutableArray *sections;
@property(nonatomic, strong) NSIndexPath *modifiedIndexPath;

- (void) presentAllSimilarModulesActionSheet;

@end

@implementation ModulesViewController
@synthesize popoverController;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
 if (self) {
 // Custom initialization.
 }
 return self;
 }
 */


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
//	[self update];
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
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.tableView = nil;
	self.powerGridLabel = nil;
	self.cpuLabel = nil;
	self.calibrationLabel = nil;
	self.turretsLabel = nil;
	self.launchersLabel = nil;
	self.highSlotsHeaderView = nil;
	self.medSlotsHeaderView = nil;
	self.lowSlotsHeaderView = nil;
	self.rigsSlotsHeaderView = nil;
	self.subsystemsSlotsHeaderView = nil;
	
/*	[sections release];
	[modifiedIndexPath release];
	sections = nil;
	modifiedIndexPath = nil;*/
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self update];
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return self.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [[[self.sections objectAtIndex:section] valueForKey:@"count"] integerValue];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	NSArray *modules = [[self.sections objectAtIndex:indexPath.section] valueForKey:@"modules"];
	if (indexPath.row >= modules.count) {
		NSString *cellIdentifier = @"ModuleCellView";
		ModuleCellView *cell = (ModuleCellView*) [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [ModuleCellView cellWithNibName:@"ModuleCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		cell.stateView.image = nil;
		cell.targetView.image = nil;
		eufe::Module::Slot slot = static_cast<eufe::Module::Slot>([[[self.sections objectAtIndex:indexPath.section] valueForKey:@"slot"] integerValue]);
		switch (slot) {
			case eufe::Module::SLOT_HI:
				cell.iconView.image = [UIImage imageNamed:@"slotHigh.png"];
				cell.titleLabel.text = NSLocalizedString(@"High slot", nil);
				break;
			case eufe::Module::SLOT_MED:
				cell.iconView.image = [UIImage imageNamed:@"slotMed.png"];
				cell.titleLabel.text = NSLocalizedString(@"Med slot", nil);
				break;
			case eufe::Module::SLOT_LOW:
				cell.iconView.image = [UIImage imageNamed:@"slotLow.png"];
				cell.titleLabel.text = NSLocalizedString(@"Low slot", nil);
				break;
			case eufe::Module::SLOT_RIG:
				cell.iconView.image = [UIImage imageNamed:@"slotRig.png"];
				cell.titleLabel.text = NSLocalizedString(@"Rig slot", nil);
				break;
			case eufe::Module::SLOT_SUBSYSTEM:
				cell.iconView.image = [UIImage imageNamed:@"slotSubsystem.png"];
				cell.titleLabel.text = NSLocalizedString(@"Subsystem slot", nil);
				break;
			default:
				cell.iconView.image = nil;
				cell.titleLabel.text = nil;
		}
		return cell;
	}
	else {
		ItemInfo* itemInfo = [modules objectAtIndex:indexPath.row];
		eufe::Module* module = dynamic_cast<eufe::Module*>(itemInfo.item);
		eufe::Charge* charge = module->getCharge();
		
		
		bool useCharge = charge != NULL;
		int optimal = (int) module->getMaxRange();
		int falloff = (int) module->getFalloff();
		float trackingSpeed = module->getTrackingSpeed();
		float lifeTime = module->getLifeTime();
		
		NSString *cellIdentifier;
		int additionalRows = 0;
		if (useCharge) {
			if (optimal > 0)
				additionalRows = 2;
			else
				additionalRows = 1;
		}
		else {
			if (optimal > 0)
				additionalRows = 1;
			else
				additionalRows = 0;
		}
		
		if (lifeTime > 0)
			additionalRows++;
		
		if (additionalRows > 0)
			cellIdentifier = [NSString stringWithFormat:@"ModuleCellView%d", additionalRows];
		else
			cellIdentifier = @"ModuleCellView";
	
		ModuleCellView *cell = (ModuleCellView*) [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [ModuleCellView cellWithNibName:@"ModuleCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		
		cell.titleLabel.text = itemInfo.typeName;
		if (charge != NULL)
		{
			ItemInfo* chargeInfo = [ItemInfo itemInfoWithItem: charge error:nil];
			cell.row1Label.text = chargeInfo.typeName;
		}
		
		if (optimal > 0) {
			NSString *s = [NSString stringWithFormat:@"%@m", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:optimal] numberStyle:NSNumberFormatterDecimalStyle]];
			if (falloff > 0)
				s = [s stringByAppendingFormat:@" + %@m", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:falloff] numberStyle:NSNumberFormatterDecimalStyle]];
			if (trackingSpeed > 0)
				s = [s stringByAppendingFormat:@" (%@ rad/sec)", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:trackingSpeed] numberStyle:NSNumberFormatterDecimalStyle]];
			if (charge != NULL)
				cell.row2Label.text = s;
			else
				cell.row1Label.text = s;
		}
		
		cell.iconView.image = [UIImage imageNamed:[itemInfo typeSmallImageName]];
		eufe::Module::Slot slot = module->getSlot();
		if (slot == eufe::Module::SLOT_HI || slot == eufe::Module::SLOT_MED || slot == eufe::Module::SLOT_LOW) {
			switch (module->getState()) {
				case eufe::Module::STATE_ACTIVE:
					cell.stateView.image = [UIImage imageNamed:@"active.png"];
					break;
				case eufe::Module::STATE_ONLINE:
					cell.stateView.image = [UIImage imageNamed:@"online.png"];
					break;
				case eufe::Module::STATE_OVERLOADED:
					cell.stateView.image = [UIImage imageNamed:@"overheated.png"];
					break;
				default:
					cell.stateView.image = [UIImage imageNamed:@"offline.png"];
					break;
			}
		}
		else
			cell.stateView.image = nil;
		
		if (lifeTime > 0) {
			NSString* s = [NSString stringWithFormat:NSLocalizedString(@"Lifetime: %@", nil), [NSString stringWithTimeLeft:lifeTime]];
			if (additionalRows == 1)
				cell.row1Label.text = s;
			else if (additionalRows == 2)
				cell.row2Label.text = s;
			else if (additionalRows == 3)
				cell.row3Label.text = s;
		}
		
		cell.targetView.image = module->getTarget() != NULL ? [UIImage imageNamed:@"Icons/icon04_12.png"] : nil;
		
		return cell;
	}
}


#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return [[self tableView:aTableView cellForRowAtIndexPath:indexPath] frame].size.height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	switch ((eufe::Module::Slot)[[[self.sections objectAtIndex:section] valueForKey:@"slot"] integerValue]) {
		case eufe::Module::SLOT_HI:
			return self.highSlotsHeaderView;
		case eufe::Module::SLOT_MED:
			return self.medSlotsHeaderView;
		case eufe::Module::SLOT_LOW:
			return self.lowSlotsHeaderView;
		case eufe::Module::SLOT_RIG:
			return self.rigsSlotsHeaderView;
		case eufe::Module::SLOT_SUBSYSTEM:
			return self.subsystemsSlotsHeaderView;
		default:
			break;
	}
	return nil;

}


- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
	NSArray *modules = [[self.sections objectAtIndex:indexPath.section] valueForKey:@"modules"];
	eufe::Character* character = self.fittingViewController.fit.character;
	eufe::Ship* ship = character->getShip();
	if (indexPath.row >= modules.count) {
		switch ((eufe::Module::Slot)[[[self.sections objectAtIndex:indexPath.section] valueForKey:@"slot"] integerValue]) {
			case eufe::Module::SLOT_HI:
			case eufe::Module::SLOT_MED:
			case eufe::Module::SLOT_LOW:
				self.fittingItemsViewController.marketGroupID = 9;
				self.fittingItemsViewController.title = NSLocalizedString(@"Ship Equipment", nil);
				self.fittingItemsViewController.except = @[@(404)];
				break;
			case eufe::Module::SLOT_RIG:
				self.fittingItemsViewController.marketGroupID = 1111;
				self.fittingItemsViewController.title = NSLocalizedString(@"Rigs", nil);
				break;
			case eufe::Module::SLOT_SUBSYSTEM: {
				switch(static_cast<int>(ship->getAttribute(eufe::RACE_ID_ATTRIBUTE_ID)->getValue())) {
					case 1: //Caldari
						self.fittingItemsViewController.marketGroupID = 1625;
						self.fittingItemsViewController.title = NSLocalizedString(@"Caldari Subsystems", nil);
						break;
					case 2: //Minmatar
						self.fittingItemsViewController.marketGroupID = 1626;
						self.fittingItemsViewController.title = NSLocalizedString(@"Minmatar Subsystems", nil);
						break;
					case 4: //Amarr
						self.fittingItemsViewController.marketGroupID = 1610;
						self.fittingItemsViewController.title = NSLocalizedString(@"Amarr Subsystems", nil);
						break;
					case 8: //Gallente
						self.fittingItemsViewController.marketGroupID = 1627;
						self.fittingItemsViewController.title = NSLocalizedString(@"Gallente Subsystems", nil);
						break;
				}
				break;
			}
			default:
				return;
		}
				
		
		//fittingItemsViewController.group = nil;
		self.fittingItemsViewController.modifiedItem = nil;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[popoverController presentPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] inView:self.tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else
			[self.fittingViewController presentModalViewController:self.fittingItemsViewController.navigationController animated:YES];
	}
	else {
		self.modifiedIndexPath = indexPath;

		ItemInfo* itemInfo = [modules objectAtIndex:indexPath.row];
		eufe::Module* module = dynamic_cast<eufe::Module*>(itemInfo.item);
		/*const std::vector<eufe::TypeID>& chargeGroups = module->getChargeGroups();
		bool multiple = false;
		int chargeSize = module->getChargeSize();
		if (chargeGroups.size() > 0)
		{
			const eufe::ModulesList& modulesList = ship->getModules();
			eufe::ModulesList::const_iterator i, end = modulesList.end();
			for (i = modulesList.begin(); i != end; i++)
			{
				if (*i != module)
				{
					int chargeSize2 = (*i)->getChargeSize();
					if (chargeSize == chargeSize2)
					{
						const std::vector<eufe::TypeID>& chargeGroups2 = (*i)->getChargeGroups();
						std::vector<eufe::TypeID> intersection;
						std::set_intersection(chargeGroups.begin(), chargeGroups.end(), chargeGroups2.begin(), chargeGroups2.end(), std::inserter(intersection, intersection.end()));
						if (intersection.size() > 0)
						{
							multiple = true;
							break;
						}
					}
				}
			}
		}*/
		
		bool multiple = false;
		for (ItemInfo* item in modules) {
			if (item == itemInfo)
				continue;
			if (item.marketGroupID == itemInfo.marketGroupID) {
				multiple = true;
				break;
			}
		}
		
		UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
																 delegate:self
														cancelButtonTitle:nil
												   destructiveButtonTitle:nil
														otherButtonTitles:nil];
		[actionSheet addButtonWithTitle:ActionButtonDelete];
		actionSheet.destructiveButtonIndex = actionSheet.numberOfButtons - 1;

		[actionSheet addButtonWithTitle:ActionButtonShowModuleInfo];
		if (module->getCharge() != nil)
			[actionSheet addButtonWithTitle:ActionButtonShowAmmoInfo];

		eufe::Module::State state = module->getState();
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			if (state >= eufe::Module::STATE_ACTIVE) {
				[actionSheet addButtonWithTitle:ActionButtonOffline];
				[actionSheet addButtonWithTitle:ActionButtonDeactivate];
				if (module->canHaveState(eufe::Module::STATE_OVERLOADED)) {
					if (state == eufe::Module::STATE_OVERLOADED)
						[actionSheet addButtonWithTitle:ActionButtonOverheatOff];
					else
						[actionSheet addButtonWithTitle:ActionButtonOverheatOn];
				}
			}
			else if (state == eufe::Module::STATE_ONLINE) {
				[actionSheet addButtonWithTitle:ActionButtonOffline];
				if (module->canHaveState(eufe::Module::STATE_ACTIVE))
					[actionSheet addButtonWithTitle:ActionButtonActivate];
			}
			else
				[actionSheet addButtonWithTitle:ActionButtonOnline];
		}
		else
			[actionSheet addButtonWithTitle:ActionButtonChangeState];

		//if (chargeGroups.size() > 0) {
		if (module->getChargeGroups().size() > 0) {
			[actionSheet addButtonWithTitle:ActionButtonAmmo];
			if (module->getCharge() != nil)
				[actionSheet addButtonWithTitle:ActionButtonUnloadAmmo];
		}
		if (module->requireTarget() && self.fittingViewController.fits.count > 1) {
			[actionSheet addButtonWithTitle:ActionButtonSetTarget];
			if (module->getTarget() != NULL)
				[actionSheet addButtonWithTitle:ActionButtonClearTarget];
		}
		[actionSheet addButtonWithTitle:ActionButtonVariations];
		
		if (multiple) {
			[actionSheet addButtonWithTitle:ActionButtonAllSimilarModules];
		}
		
		[actionSheet addButtonWithTitle:ActionButtonCancel];
		actionSheet.cancelButtonIndex = actionSheet.numberOfButtons - 1;
		
		[actionSheet showFromRect:[aTableView rectForRowAtIndexPath:indexPath] inView:aTableView animated:YES];
	}
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSArray* modules = [[self.sections objectAtIndex:self.modifiedIndexPath.section] valueForKey:@"modules"];
	ItemInfo* itemInfo = [modules objectAtIndex:self.modifiedIndexPath.row];
	eufe::Module* module = dynamic_cast<eufe::Module*>(itemInfo.item);
	int chargeSize = module->getChargeSize();
	NSString *button = [actionSheet buttonTitleAtIndex:buttonIndex];

	if ([button isEqualToString:ActionButtonDelete]) {
		self.fittingViewController.fit.character->getShip()->removeModule(module);
		[self.fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonAmmo]) {

		const std::vector<eufe::TypeID>& chargeGroups = module->getChargeGroups();
		std::vector<eufe::TypeID>::const_iterator i, end = chargeGroups.end();

		NSMutableString *groups = [NSMutableString string];
		bool isFirst = true;
		for (i = chargeGroups.begin(); i != end; i++)
		{
			if (!isFirst)
				[groups appendFormat:@",%d", *i];
			else
			{
				[groups appendFormat:@"%d", *i];
				isFirst = false;
			}
		}
			
		self.fittingItemsViewController.marketGroupID = 0;
		if (chargeSize) {
			self.fittingItemsViewController.typesRequest = [NSString stringWithFormat:@"SELECT invMetaGroups.*, invTypes.* FROM invTypes, dgmTypeAttributes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND invTypes.typeID=dgmTypeAttributes.typeID AND dgmTypeAttributes.attributeID=128 AND dgmTypeAttributes.value=%d AND groupID IN (%@) ORDER BY invTypes.typeName;",
													   chargeSize, groups];
			self.fittingItemsViewController.searchRequest = [NSString stringWithFormat:@"SELECT invMetaGroups.*, invTypes.* FROM invTypes, dgmTypeAttributes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND invTypes.typeID=dgmTypeAttributes.typeID AND dgmTypeAttributes.attributeID=128 AND dgmTypeAttributes.value=%d AND groupID IN (%@) AND typeName LIKE \"%%%%%%@%%%%\" ORDER BY invTypes.typeName;",
														chargeSize, groups];
		}
		else {
			self.fittingItemsViewController.typesRequest = [NSString stringWithFormat:@"SELECT invMetaGroups.*, invTypes.* FROM invTypes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND groupID IN (%@) AND invTypes.volume <= %f ORDER BY invTypes.typeName;",
													   groups, module->getAttribute(eufe::CAPACITY_ATTRIBUTE_ID)->getValue()];
			self.fittingItemsViewController.searchRequest = [NSString stringWithFormat:@"SELECT invMetaGroups.*, invTypes.* FROM invTypes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND groupID IN (%@) AND invTypes.volume <= %f AND typeName LIKE \"%%%%%%@%%%%\" ORDER BY invTypes.typeName;",
													   groups, module->getAttribute(eufe::CAPACITY_ATTRIBUTE_ID)->getValue()];
		}

		self.fittingItemsViewController.title = NSLocalizedString(@"Ammo", nil);
		self.fittingItemsViewController.modifiedItem = itemInfo;
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[self.popoverController presentPopoverFromRect:[self.tableView rectForRowAtIndexPath:self.modifiedIndexPath] inView:self.tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else
			[self.fittingViewController presentModalViewController:self.fittingItemsViewController.navigationController animated:YES];
		
		[self.fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonOffline]) {
		module->setState(eufe::Module::STATE_OFFLINE);
		[self.fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonOnline]) {
		if (module->canHaveState(eufe::Module::STATE_ACTIVE))
			module->setState(eufe::Module::STATE_ACTIVE);
		else
			module->setState(eufe::Module::STATE_ONLINE);
		[self.fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonActivate]) {
		module->setState(eufe::Module::STATE_ACTIVE);
		[self.fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonDeactivate]) {
		module->setState(eufe::Module::STATE_ONLINE);
		[self.fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonOverheatOn]) {
		module->setState(eufe::Module::STATE_OVERLOADED);
		[self.fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonOverheatOff]) {
		module->setState(eufe::Module::STATE_ACTIVE);
		[self.fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonUnloadAmmo]) {
		module->clearCharge();
		[self.fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonSetTarget]) {
		//self.targetsViewController.modifiedItem = itemInfo;
		self.targetsViewController.currentTarget = module->getTarget();
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[self.fittingViewController.targetsPopoverController presentPopoverFromRect:[self.tableView rectForRowAtIndexPath:self.modifiedIndexPath] inView:self.tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else
			[self.fittingViewController presentModalViewController:self.targetsViewController.navigationController animated:YES];
	}
	else if ([button isEqualToString:ActionButtonClearTarget]) {
		module->clearTarget();
		[self.fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonChangeState]) {
		UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
																 delegate:self
														cancelButtonTitle:nil
												   destructiveButtonTitle:nil
														otherButtonTitles:nil];
		eufe::Module::State state = module->getState();
		if (state >= eufe::Module::STATE_ACTIVE) {
			[actionSheet addButtonWithTitle:ActionButtonOffline];
			[actionSheet addButtonWithTitle:ActionButtonDeactivate];
			if (module->canHaveState(eufe::Module::STATE_OVERLOADED)) {
				if (state == eufe::Module::STATE_OVERLOADED)
					[actionSheet addButtonWithTitle:ActionButtonOverheatOff];
				else
					[actionSheet addButtonWithTitle:ActionButtonOverheatOn];
			}
		}
		else if (state == eufe::Module::STATE_ONLINE) {
			[actionSheet addButtonWithTitle:ActionButtonOffline];
			if (module->canHaveState(eufe::Module::STATE_ACTIVE))
				[actionSheet addButtonWithTitle:ActionButtonActivate];
		}
		else
			[actionSheet addButtonWithTitle:ActionButtonOnline];
		[actionSheet addButtonWithTitle:ActionButtonCancel];
		actionSheet.cancelButtonIndex = actionSheet.numberOfButtons - 1;
		
		[actionSheet showFromRect:[self.tableView rectForRowAtIndexPath:self.modifiedIndexPath] inView:self.tableView animated:YES];
	}
	else if ([button isEqualToString:ActionButtonShowModuleInfo]) {
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
	else if ([button isEqualToString:ActionButtonShowAmmoInfo]) {
		ItemViewController *itemViewController = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		ItemInfo* ammo = [ItemInfo itemInfoWithItem:module->getCharge() error:nil];
		[ammo updateAttributes];
		itemViewController.type = ammo;
		[itemViewController setActivePage:ItemViewControllerActivePageInfo];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:itemViewController];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self.fittingViewController presentModalViewController:navController animated:YES];
		}
		else
			[self.fittingViewController.navigationController pushViewController:itemViewController animated:YES];
	}
	else if ([button isEqualToString:ActionButtonVariations]) {
		FittingVariationsViewController* controller = [[FittingVariationsViewController alloc] initWithNibName:@"VariationsViewController" bundle:nil];
		controller.type = itemInfo;
		controller.modifiedItem = itemInfo;
		controller.delegate = self.fittingViewController;
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
		navController.navigationBar.barStyle = self.fittingViewController.navigationController.navigationBar.barStyle;

		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			self.fittingViewController.variationsPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
			[self.fittingViewController.variationsPopoverController presentPopoverFromRect:[self.tableView rectForRowAtIndexPath:self.modifiedIndexPath] inView:self.tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		}
		else
			[self.fittingViewController presentModalViewController:navController animated:YES];

	}
	else if ([button isEqualToString:ActionButtonAllSimilarModules]) {
		[self presentAllSimilarModulesActionSheet];
	}
}

#pragma mark FittingSection

- (void) update {
	__block float totalPG;
	__block float usedPG;
	__block float totalCPU;
	__block float usedCPU;
	__block float totalCalibration;
	__block float usedCalibration;
	__block int usedTurretHardpoints;
	__block int totalTurretHardpoints;
	__block int usedMissileHardpoints;
	__block int totalMissileHardpoints;
	
	NSMutableArray *sectionsTmp = [NSMutableArray array];

	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"ModulesViewController+Update" name:NSLocalizedString(@"Updating Modules", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		@synchronized(self.fittingViewController) {
			eufe::Ship* ship = self.fittingViewController.fit.character->getShip();
			
			eufe::Module::Slot slots[] = {eufe::Module::SLOT_HI, eufe::Module::SLOT_MED, eufe::Module::SLOT_LOW, eufe::Module::SLOT_RIG, eufe::Module::SLOT_SUBSYSTEM};
			int n = sizeof(slots) / sizeof(eufe::Module::Slot);
			
			for (int i = 0; i < n; i++)
			{
				weakOperation.progress = (float) i / (float) n;
				int numberOfSlots = ship->getNumberOfSlots(slots[i]);
				if (numberOfSlots > 0)
				{
					eufe::ModulesList modules;
					ship->getModules(slots[i], std::inserter(modules, modules.end()));
					eufe::ModulesList::iterator j, endj = modules.end();
					NSMutableArray* array = [NSMutableArray array];
					for (j = modules.begin(); j != endj; j++)
						[array addObject:[ItemInfo itemInfoWithItem:*j error:nil]];
					[sectionsTmp addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:(int) slots[i]], @"slot",
											[NSNumber numberWithInt:numberOfSlots], @"count",
											array, @"modules", nil]];
				}
			}
			
			totalPG = ship->getTotalPowerGrid();
			usedPG = ship->getPowerGridUsed();
			
			totalCPU = ship->getTotalCpu();
			usedCPU = ship->getCpuUsed();
			
			totalCalibration = ship->getTotalCalibration();
			usedCalibration = ship->getCalibrationUsed();
			
			usedTurretHardpoints = ship->getUsedHardpoints(eufe::Module::HARDPOINT_TURRET);
			totalTurretHardpoints = ship->getNumberOfHardpoints(eufe::Module::HARDPOINT_TURRET);
			usedMissileHardpoints = ship->getUsedHardpoints(eufe::Module::HARDPOINT_LAUNCHER);
			totalMissileHardpoints = ship->getNumberOfHardpoints(eufe::Module::HARDPOINT_LAUNCHER);
		}
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.sections = sectionsTmp;
			
			self.powerGridLabel.text = [NSString stringWithTotalResources:totalPG usedResources:usedPG unit:@"MW"];
			self.powerGridLabel.progress = totalPG > 0 ? usedPG / totalPG : 0;
			self.cpuLabel.text = [NSString stringWithTotalResources:totalCPU usedResources:usedCPU unit:@"tf"];
			self.cpuLabel.progress = usedCPU > 0 ? usedCPU / totalCPU : 0;
			self.calibrationLabel.text = [NSString stringWithFormat:@"%d/%d", (int) usedCalibration, (int) totalCalibration];
			self.calibrationLabel.progress = totalCalibration > 0 ? usedCalibration / totalCalibration : 0;
			self.turretsLabel.text = [NSString stringWithFormat:@"%d/%d", usedTurretHardpoints, totalTurretHardpoints];
			self.launchersLabel.text = [NSString stringWithFormat:@"%d/%d", usedMissileHardpoints, totalMissileHardpoints];
			[self.tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

#pragma mark - Private

- (void) presentAllSimilarModulesActionSheet {
	NSArray *modules = [[self.sections objectAtIndex:self.modifiedIndexPath.section] valueForKey:@"modules"];
	ItemInfo* itemInfo = [modules objectAtIndex:self.modifiedIndexPath.row];
	eufe::Module* module = dynamic_cast<eufe::Module*>(itemInfo.item);
	
	NSMutableArray *buttons = [NSMutableArray array];

	eufe::Module::State state = module->getState();
	if (state >= eufe::Module::STATE_ACTIVE) {
		[buttons addObject:ActionButtonOffline];
		[buttons addObject:ActionButtonDeactivate];
		if (module->canHaveState(eufe::Module::STATE_OVERLOADED)) {
			if (state == eufe::Module::STATE_OVERLOADED)
				[buttons addObject:ActionButtonOverheatOff];
			else
				[buttons addObject:ActionButtonOverheatOn];
		}
	}
	else if (state == eufe::Module::STATE_ONLINE) {
		[buttons addObject:ActionButtonOffline];
		if (module->canHaveState(eufe::Module::STATE_ACTIVE))
			[buttons addObject:ActionButtonActivate];
	}
	else
		[buttons addObject:ActionButtonOnline];
	
	if (module->getChargeGroups().size() > 0) {
		[buttons addObject:ActionButtonAmmo];
		if (module->getCharge() != nil)
			[buttons addObject:ActionButtonUnloadAmmo];
	}
	[buttons addObject:ActionButtonVariations];
	
	UIActionSheet *actionSheet = [UIActionSheet actionSheetWithTitle:nil
												   cancelButtonTitle:ActionButtonCancel
											  destructiveButtonTitle:ActionButtonDelete
												   otherButtonTitles:buttons
													 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
														 NSString *button = [actionSheet buttonTitleAtIndex:selectedButtonIndex];
														 NSInteger marketGroupID = itemInfo.marketGroupID;
														 eufe::Ship* ship = self.fittingViewController.fit.character->getShip();
														 
														 if ([button isEqualToString:ActionButtonDelete]) {
															 for (ItemInfo* itemInfo in modules) {
																 if (itemInfo.marketGroupID == marketGroupID)
																	 ship->removeModule(dynamic_cast<eufe::Module*>(itemInfo.item));
															 }
															 [self.fittingViewController update];
														 }
														 else if ([button isEqualToString:ActionButtonOffline]) {
															 for (ItemInfo* itemInfo in modules) {
																 if (itemInfo.marketGroupID == marketGroupID) {
																	 eufe::Module* module = dynamic_cast<eufe::Module*>(itemInfo.item);
																	 module->setState(eufe::Module::STATE_OFFLINE);
																 }
															 }
															 [self.fittingViewController update];
														 }
														 else if ([button isEqualToString:ActionButtonOnline]) {
															 for (ItemInfo* itemInfo in modules) {
																 if (itemInfo.marketGroupID == marketGroupID) {
																	 eufe::Module* module = dynamic_cast<eufe::Module*>(itemInfo.item);
																	 if (module->canHaveState(eufe::Module::STATE_ACTIVE))
																		 module->setState(eufe::Module::STATE_ACTIVE);
																	 else
																		 module->setState(eufe::Module::STATE_ONLINE);
																 }
															 }
															 [self.fittingViewController update];
														 }
														 else if ([button isEqualToString:ActionButtonActivate]) {
															 for (ItemInfo* itemInfo in modules) {
																 if (itemInfo.marketGroupID == marketGroupID) {
																	 eufe::Module* module = dynamic_cast<eufe::Module*>(itemInfo.item);
																	 if (module->canHaveState(eufe::Module::STATE_ACTIVE))
																		 module->setState(eufe::Module::STATE_ACTIVE);
																 }
															 }
															 [self.fittingViewController update];
														 }
														 else if ([button isEqualToString:ActionButtonDeactivate]) {
															 for (ItemInfo* itemInfo in modules) {
																 if (itemInfo.marketGroupID == marketGroupID) {
																	 eufe::Module* module = dynamic_cast<eufe::Module*>(itemInfo.item);
																	 if (module->canHaveState(eufe::Module::STATE_ONLINE))
																		 module->setState(eufe::Module::STATE_ONLINE);
																 }
															 }
															 [self.fittingViewController update];
														 }
														 else if ([button isEqualToString:ActionButtonOverheatOn]) {
															 for (ItemInfo* itemInfo in modules) {
																 if (itemInfo.marketGroupID == marketGroupID) {
																	 eufe::Module* module = dynamic_cast<eufe::Module*>(itemInfo.item);
																	 if (module->canHaveState(eufe::Module::STATE_OVERLOADED))
																		 module->setState(eufe::Module::STATE_OVERLOADED);
																 }
															 }
															 [self.fittingViewController update];
														 }
														 else if ([button isEqualToString:ActionButtonOverheatOff]) {
															 for (ItemInfo* itemInfo in modules) {
																 if (itemInfo.marketGroupID == marketGroupID) {
																	 eufe::Module* module = dynamic_cast<eufe::Module*>(itemInfo.item);
																	 if (module->canHaveState(eufe::Module::STATE_ACTIVE))
																		 module->setState(eufe::Module::STATE_ACTIVE);
																 }
															 }
															 [self.fittingViewController update];
														 }
														 else if ([button isEqualToString:ActionButtonAmmo]) {
															 const std::vector<eufe::TypeID>& chargeGroups = module->getChargeGroups();
															 std::vector<eufe::TypeID>::const_iterator i, end = chargeGroups.end();
															 int chargeSize = module->getChargeSize();
															 
															 NSMutableString *groups = [NSMutableString string];
															 bool isFirst = true;
															 for (i = chargeGroups.begin(); i != end; i++)
															 {
																 if (!isFirst)
																	 [groups appendFormat:@",%d", *i];
																 else
																 {
																	 [groups appendFormat:@"%d", *i];
																	 isFirst = false;
																 }
															 }
															 
															 self.fittingItemsViewController.marketGroupID = 0;
															 if (chargeSize) {
																 self.fittingItemsViewController.typesRequest = [NSString stringWithFormat:@"SELECT invMetaGroups.*, invTypes.* FROM invTypes, dgmTypeAttributes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND invTypes.typeID=dgmTypeAttributes.typeID AND dgmTypeAttributes.attributeID=128 AND dgmTypeAttributes.value=%d AND groupID IN (%@) ORDER BY invTypes.typeName;",
																											chargeSize, groups];
																 self.fittingItemsViewController.searchRequest = [NSString stringWithFormat:@"SELECT invMetaGroups.*, invTypes.* FROM invTypes, dgmTypeAttributes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND invTypes.typeID=dgmTypeAttributes.typeID AND dgmTypeAttributes.attributeID=128 AND dgmTypeAttributes.value=%d AND groupID IN (%@) AND typeName LIKE \"%%%%%%@%%%%\" ORDER BY invTypes.typeName;",
																											 chargeSize, groups];
															 }
															 else {
																 self.fittingItemsViewController.typesRequest = [NSString stringWithFormat:@"SELECT invMetaGroups.*, invTypes.* FROM invTypes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND groupID IN (%@) AND invTypes.volume <= %f ORDER BY invTypes.typeName;",
																											groups, module->getAttribute(eufe::CAPACITY_ATTRIBUTE_ID)->getValue()];
																 self.fittingItemsViewController.searchRequest = [NSString stringWithFormat:@"SELECT invMetaGroups.*, invTypes.* FROM invTypes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND groupID IN (%@) AND invTypes.volume <= %f AND typeName LIKE \"%%%%%%@%%%%\" ORDER BY invTypes.typeName;",
																											 groups, module->getAttribute(eufe::CAPACITY_ATTRIBUTE_ID)->getValue()];
															 }
															 
															 self.fittingItemsViewController.title = NSLocalizedString(@"Ammo", nil);
															 self.fittingItemsViewController.modifiedItem = nil;
															 
															 if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
																 [self.popoverController presentPopoverFromRect:[self.tableView rectForRowAtIndexPath:self.modifiedIndexPath] inView:self.tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
															 else
																 [self.fittingViewController presentModalViewController:self.fittingItemsViewController.navigationController animated:YES];
														 }
														 else if ([button isEqualToString:ActionButtonUnloadAmmo]) {
															 for (ItemInfo* itemInfo in modules) {
																 if (itemInfo.marketGroupID == marketGroupID) {
																	 eufe::Module* module = dynamic_cast<eufe::Module*>(itemInfo.item);
																	 module->clearCharge();
																 }
															 }
															 [self.fittingViewController update];
														 }
														 else if ([button isEqualToString:ActionButtonVariations]) {
															 FittingVariationsViewController* controller = [[FittingVariationsViewController alloc] initWithNibName:@"FittingVariationsViewController" bundle:nil];
															 controller.type = itemInfo;
															 controller.delegate = self.fittingViewController;
															 UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
															 navController.navigationBar.barStyle = self.fittingViewController.navigationController.navigationBar.barStyle;
															 
															 if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
																 self.fittingViewController.variationsPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
																 [self.fittingViewController.variationsPopoverController presentPopoverFromRect:[self.tableView rectForRowAtIndexPath:self.modifiedIndexPath] inView:self.tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
															 }
															 else
																 [self.fittingViewController presentModalViewController:navController animated:YES];
														 }
													 } cancelBlock:nil];

	[actionSheet showFromRect:[self.tableView rectForRowAtIndexPath:self.modifiedIndexPath] inView:self.tableView animated:YES];
}

@end