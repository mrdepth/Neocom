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
#import "Fit.h"
#import "EVEDBAPI.h"
#import "NSString+TimeLeft.h"

#import "ItemInfo.h"

#include <algorithm>

#define ActionButtonOffline NSLocalizedString(@"Put Offline", nil)
#define ActionButtonOnline NSLocalizedString(@"Put Online", nil)
#define ActionButtonOverheatOn NSLocalizedString(@"Enable Overheating", nil)
#define ActionButtonOverheatOff NSLocalizedString(@"Disable Overheating", nil)
#define ActionButtonActivate NSLocalizedString(@"Activate", nil)
#define ActionButtonDeactivate NSLocalizedString(@"Deactivate", nil)
#define ActionButtonAmmoCurrentModule NSLocalizedString(@"Ammo (Current Module)", nil)
#define ActionButtonAmmoAllModules NSLocalizedString(@"Ammo (All Modules)", nil)
#define ActionButtonAmmo NSLocalizedString(@"Ammo", nil)
#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)
#define ActionButtonDelete NSLocalizedString(@"Delete", nil)
#define ActionButtonChangeState NSLocalizedString(@"Change State", nil)
#define ActionButtonUnloadAmmo NSLocalizedString(@"Unload Ammo", nil)
#define ActionButtonShowModuleInfo NSLocalizedString(@"Show Module Info", nil)
#define ActionButtonShowAmmoInfo NSLocalizedString(@"Show Ammo Info", nil)
#define ActionButtonSetTarget NSLocalizedString(@"Set Target", nil)
#define ActionButtonClearTarget NSLocalizedString(@"Clear Target", nil)

@implementation ModulesViewController
@synthesize fittingViewController;
@synthesize popoverController;
@synthesize tableView;
@synthesize powerGridLabel;
@synthesize cpuLabel;
@synthesize calibrationLabel;
@synthesize turretsLabel;
@synthesize launchersLabel;
@synthesize highSlotsHeaderView;
@synthesize medSlotsHeaderView;
@synthesize lowSlotsHeaderView;
@synthesize rigsSlotsHeaderView;
@synthesize subsystemsSlotsHeaderView;
@synthesize fittingItemsViewController;
@synthesize targetsViewController;

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


- (void) dealloc {
	[tableView release];
	[powerGridLabel release];
	[cpuLabel release];
	[calibrationLabel release];
	[turretsLabel release];
	[launchersLabel release];
	[highSlotsHeaderView release];
	[medSlotsHeaderView release];
	[lowSlotsHeaderView release];
	[rigsSlotsHeaderView release];
	[subsystemsSlotsHeaderView release];
	[fittingItemsViewController release];
	[targetsViewController release];
	[popoverController release];
	
	[sections release];
	[modifiedIndexPath release];
	[super dealloc];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [[[sections objectAtIndex:section] valueForKey:@"count"] integerValue];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	NSArray *modules = [[sections objectAtIndex:indexPath.section] valueForKey:@"modules"];
	if (indexPath.row >= modules.count) {
		NSString *cellIdentifier = @"ModuleCellView";
		ModuleCellView *cell = (ModuleCellView*) [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [ModuleCellView cellWithNibName:@"ModuleCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		cell.stateView.image = nil;
		cell.targetView.image = nil;
		eufe::Module::Slot slot = static_cast<eufe::Module::Slot>([[[sections objectAtIndex:indexPath.section] valueForKey:@"slot"] integerValue]);
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
	switch ((eufe::Module::Slot)[[[sections objectAtIndex:section] valueForKey:@"slot"] integerValue]) {
		case eufe::Module::SLOT_HI:
			return highSlotsHeaderView;
		case eufe::Module::SLOT_MED:
			return medSlotsHeaderView;
		case eufe::Module::SLOT_LOW:
			return lowSlotsHeaderView;
		case eufe::Module::SLOT_RIG:
			return rigsSlotsHeaderView;
		case eufe::Module::SLOT_SUBSYSTEM:
			return subsystemsSlotsHeaderView;
		default:
			break;
	}
	return nil;

}


- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
	NSArray *modules = [[sections objectAtIndex:indexPath.section] valueForKey:@"modules"];
	eufe::Character* character = fittingViewController.fit.character;
	eufe::Ship* ship = character->getShip();
	if (indexPath.row >= modules.count) {
		switch ((eufe::Module::Slot)[[[sections objectAtIndex:indexPath.section] valueForKey:@"slot"] integerValue]) {
			case eufe::Module::SLOT_HI:
			case eufe::Module::SLOT_MED:
			case eufe::Module::SLOT_LOW:
				fittingItemsViewController.marketGroupID = 9;
				fittingItemsViewController.title = NSLocalizedString(@"Ship Equipment", nil);
				fittingItemsViewController.except = @[@(404)];
				break;
			case eufe::Module::SLOT_RIG:
				fittingItemsViewController.marketGroupID = 1111;
				fittingItemsViewController.title = NSLocalizedString(@"Rigs", nil);
				break;
			case eufe::Module::SLOT_SUBSYSTEM: {
				switch(static_cast<int>(ship->getAttribute(eufe::RACE_ID_ATTRIBUTE_ID)->getValue())) {
					case 1: //Caldari
						fittingItemsViewController.marketGroupID = 1625;
						fittingItemsViewController.title = NSLocalizedString(@"Caldari Subsystems", nil);
						break;
					case 2: //Minmatar
						fittingItemsViewController.marketGroupID = 1626;
						fittingItemsViewController.title = NSLocalizedString(@"Minmatar Subsystems", nil);
						break;
					case 4: //Amarr
						fittingItemsViewController.marketGroupID = 1610;
						fittingItemsViewController.title = NSLocalizedString(@"Amarr Subsystems", nil);
						break;
					case 8: //Gallente
						fittingItemsViewController.marketGroupID = 1627;
						fittingItemsViewController.title = NSLocalizedString(@"Gallente Subsystems", nil);
						break;
				}
				break;
			}
			default:
				return;
		}
				
		
		//fittingItemsViewController.group = nil;
		fittingItemsViewController.modifiedItem = nil;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[popoverController presentPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] inView:tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else
			[self.fittingViewController presentModalViewController:fittingItemsViewController.navigationController animated:YES];
	}
	else {
		[modifiedIndexPath release];
		modifiedIndexPath = [indexPath retain];

		ItemInfo* itemInfo = [modules objectAtIndex:indexPath.row];
		eufe::Module* module = dynamic_cast<eufe::Module*>(itemInfo.item);
		const std::vector<eufe::TypeID>& chargeGroups = module->getChargeGroups();
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

		if (chargeGroups.size() > 0) {
			[actionSheet addButtonWithTitle:ActionButtonAmmoCurrentModule];
			if (multiple)
				[actionSheet addButtonWithTitle:ActionButtonAmmoAllModules];
			if (module->getCharge() != nil)
				[actionSheet addButtonWithTitle:ActionButtonUnloadAmmo];
		}
		if (module->requireTarget() && fittingViewController.fits.count > 1) {
			[actionSheet addButtonWithTitle:ActionButtonSetTarget];
			if (module->getTarget() != NULL)
				[actionSheet addButtonWithTitle:ActionButtonClearTarget];
		}
		[actionSheet addButtonWithTitle:ActionButtonCancel];
		actionSheet.cancelButtonIndex = actionSheet.numberOfButtons - 1;
		
		[actionSheet showFromRect:[aTableView rectForRowAtIndexPath:indexPath] inView:aTableView animated:YES];
		[actionSheet autorelease];
	}
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSArray* modules = [[sections objectAtIndex:modifiedIndexPath.section] valueForKey:@"modules"];
	ItemInfo* itemInfo = [modules objectAtIndex:modifiedIndexPath.row];
	eufe::Module* module = dynamic_cast<eufe::Module*>(itemInfo.item);
	int chargeSize = module->getChargeSize();
	NSString *button = [actionSheet buttonTitleAtIndex:buttonIndex];

	eufe::Character* character = fittingViewController.fit.character;
	eufe::Ship* ship = character->getShip();

	if ([button isEqualToString:ActionButtonDelete]) {
		fittingViewController.fit.character->getShip()->removeModule(module);
		[self.fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonAmmo]) {
		const std::vector<eufe::TypeID>& chargeGroups = module->getChargeGroups();
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
		}
		
		UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
																 delegate:self
														cancelButtonTitle:nil
												   destructiveButtonTitle:nil
														otherButtonTitles:nil];
		[actionSheet addButtonWithTitle:ActionButtonAmmoCurrentModule];
		if (multiple)
			[actionSheet addButtonWithTitle:ActionButtonAmmoAllModules];
		if (module->getCharge() != NULL)
			[actionSheet addButtonWithTitle:ActionButtonUnloadAmmo];
		
		[actionSheet addButtonWithTitle:ActionButtonCancel];
		actionSheet.cancelButtonIndex = actionSheet.numberOfButtons - 1;
		
		[actionSheet showFromRect:[tableView rectForRowAtIndexPath:modifiedIndexPath] inView:tableView animated:YES];
		[actionSheet autorelease];
	}
	else if ([button isEqualToString:ActionButtonAmmoCurrentModule] || [button isEqualToString:ActionButtonAmmoAllModules]) {
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
			
		fittingItemsViewController.marketGroupID = 0;
		if (chargeSize) {
			fittingItemsViewController.typesRequest = [NSString stringWithFormat:@"SELECT invMetaGroups.metaGroupID, invMetaGroups.metaGroupName, invTypes.* FROM invTypes, dgmTypeAttributes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND invTypes.typeID=dgmTypeAttributes.typeID AND dgmTypeAttributes.attributeID=128 AND dgmTypeAttributes.value=%d AND groupID IN (%@) ORDER BY invTypes.typeName;",
													   chargeSize, groups];
			fittingItemsViewController.searchRequest = [NSString stringWithFormat:@"SELECT invMetaGroups.metaGroupID, invMetaGroups.metaGroupName, invTypes.* FROM invTypes, dgmTypeAttributes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND invTypes.typeID=dgmTypeAttributes.typeID AND dgmTypeAttributes.attributeID=128 AND dgmTypeAttributes.value=%d AND groupID IN (%@) AND typeName LIKE \"%%%%%%@%%%%\" ORDER BY invTypes.typeName;",
														chargeSize, groups];
		}
		else {
			fittingItemsViewController.typesRequest = [NSString stringWithFormat:@"SELECT invMetaGroups.metaGroupID, invMetaGroups.metaGroupName, invTypes.* FROM invTypes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND groupID IN (%@) AND invTypes.volume <= %f ORDER BY invTypes.typeName;",
													   groups, module->getAttribute(eufe::CAPACITY_ATTRIBUTE_ID)->getValue()];
			fittingItemsViewController.searchRequest = [NSString stringWithFormat:@"SELECT invMetaGroups.metaGroupID, invMetaGroups.metaGroupName, invTypes.* FROM invTypes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND groupID IN (%@) AND invTypes.volume <= %f AND typeName LIKE \"%%%%%%@%%%%\" ORDER BY invTypes.typeName;",
													   groups, module->getAttribute(eufe::CAPACITY_ATTRIBUTE_ID)->getValue()];
		}

		fittingItemsViewController.title = NSLocalizedString(@"Ammo", nil);
		if ([button isEqualToString:ActionButtonAmmoAllModules])
			fittingItemsViewController.modifiedItem = nil;
		else
			fittingItemsViewController.modifiedItem = itemInfo;
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[popoverController presentPopoverFromRect:[tableView rectForRowAtIndexPath:modifiedIndexPath] inView:tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else
			[self.fittingViewController presentModalViewController:fittingItemsViewController.navigationController animated:YES];
		
		
		if ([button isEqualToString:ActionButtonAmmoAllModules]) {
			[modifiedIndexPath release];
			modifiedIndexPath = nil;
		}
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
		targetsViewController.modifiedItem = itemInfo;
		targetsViewController.currentTarget = module->getTarget();
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[fittingViewController.targetsPopoverController presentPopoverFromRect:[tableView rectForRowAtIndexPath:modifiedIndexPath] inView:tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else
			[self.fittingViewController presentModalViewController:targetsViewController.navigationController animated:YES];
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
		
		[actionSheet showFromRect:[tableView rectForRowAtIndexPath:modifiedIndexPath] inView:tableView animated:YES];
		[actionSheet autorelease];
	}
	else if ([button isEqualToString:ActionButtonShowModuleInfo]) {
		ItemViewController *itemViewController = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		[itemInfo updateAttributes];
		itemViewController.type = itemInfo;
		[itemViewController setActivePage:ItemViewControllerActivePageInfo];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:itemViewController];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[fittingViewController presentModalViewController:navController animated:YES];
			[navController release];
		}
		else
			[fittingViewController.navigationController pushViewController:itemViewController animated:YES];
		[itemViewController release];
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
			[fittingViewController presentModalViewController:navController animated:YES];
			[navController release];
		}
		else
			[fittingViewController.navigationController pushViewController:itemViewController animated:YES];
		[itemViewController release];
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
	FittingViewController* aFittingViewController = fittingViewController;

	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"ModulesViewController+Update" name:NSLocalizedString(@"Updating Modules", nil)];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		@synchronized(fittingViewController) {
			eufe::Ship* ship = aFittingViewController.fit.character->getShip();
			
			eufe::Module::Slot slots[] = {eufe::Module::SLOT_HI, eufe::Module::SLOT_MED, eufe::Module::SLOT_LOW, eufe::Module::SLOT_RIG, eufe::Module::SLOT_SUBSYSTEM};
			int n = sizeof(slots) / sizeof(eufe::Module::Slot);
			
			for (int i = 0; i < n; i++)
			{
				operation.progress = (float) i / (float) n;
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

		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			if (sections)
				[sections release];
			sections = [sectionsTmp retain];
			
			powerGridLabel.text = [NSString stringWithTotalResources:totalPG usedResources:usedPG unit:@"MW"];
			powerGridLabel.progress = totalPG > 0 ? usedPG / totalPG : 0;
			cpuLabel.text = [NSString stringWithTotalResources:totalCPU usedResources:usedCPU unit:@"tf"];
			cpuLabel.progress = usedCPU > 0 ? usedCPU / totalCPU : 0;
			calibrationLabel.text = [NSString stringWithFormat:@"%d/%d", (int) usedCalibration, (int) totalCalibration];
			calibrationLabel.progress = totalCalibration > 0 ? usedCalibration / totalCalibration : 0;
			turretsLabel.text = [NSString stringWithFormat:@"%d/%d", usedTurretHardpoints, totalTurretHardpoints];
			launchersLabel.text = [NSString stringWithFormat:@"%d/%d", usedMissileHardpoints, totalMissileHardpoints];
			[tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end