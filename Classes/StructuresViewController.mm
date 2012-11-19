//
//  StructuresViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "StructuresViewController.h"
#import "POSFittingViewController.h"
#import "ModuleCellView.h"
#import "UITableViewCell+Nib.h"
#import "FittingItemsViewController.h"
#import "NSString+Fitting.h"
#import "ItemViewController.h"
#import "EUOperationQueue.h"
#import "POSFit.h"
#import "EVEDBAPI.h"
#import "NSString+TimeLeft.h"

#import "ItemInfo.h"

#include <algorithm>

#define ActionButtonOffline @"Put Offline"
#define ActionButtonOnline @"Put Online"
#define ActionButtonActivate @"Activate"
#define ActionButtonDeactivate @"Deactivate"
#define ActionButtonAmmoCurrentModule @"Ammo (Current Module)"
#define ActionButtonAmmoAllModules @"Ammo (All Modules)"
#define ActionButtonAmmo @"Ammo"
#define ActionButtonCancel @"Cancel"
#define ActionButtonDelete @"Delete"
#define ActionButtonChangeState @"Change State"
#define ActionButtonUnloadAmmo @"Unload Ammo"
#define ActionButtonShowModuleInfo @"Show Module Info"
#define ActionButtonShowAmmoInfo @"Show Ammo Info"
#define ActionButtonAmount @"Set Amount"

@implementation StructuresViewController
@synthesize posFittingViewController;
@synthesize tableView;
@synthesize powerGridLabel;
@synthesize cpuLabel;
@synthesize fittingItemsViewController;
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

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self update];
}


- (void) dealloc {
	[tableView release];
	[powerGridLabel release];
	[cpuLabel release];
	[fittingItemsViewController release];
	[popoverController release];
	
	[structures release];
	[modifiedIndexPath release];
	[super dealloc];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return structures.count + 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	if (indexPath.row >= structures.count) {
		NSString *cellIdentifier = @"ModuleCellView";
		ModuleCellView *cell = (ModuleCellView*) [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [ModuleCellView cellWithNibName:@"ModuleCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		cell.stateView.image = nil;
		cell.targetView.image = nil;
		cell.iconView.image = [UIImage imageNamed:@"slotRig.png"];
		cell.titleLabel.text = @"Add Structure";
		return cell;
	}
	else {
		NSArray* array = [structures objectAtIndex:indexPath.row];
		ItemInfo* itemInfo = [array objectAtIndex:0];
		eufe::Structure* structure = dynamic_cast<eufe::Structure*>(itemInfo.item);
		eufe::Charge* charge = structure->getCharge();
		
		
		bool useCharge = charge != NULL;
		int optimal = (int) structure->getMaxRange();
		int falloff = (int) structure->getFalloff();
		float trackingSpeed = structure->getTrackingSpeed();
		
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
		
		if (additionalRows > 0)
			cellIdentifier = [NSString stringWithFormat:@"ModuleCellView%d", additionalRows];
		else
			cellIdentifier = @"ModuleCellView";
		
		ModuleCellView *cell = (ModuleCellView*) [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [ModuleCellView cellWithNibName:@"ModuleCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		
		cell.titleLabel.text = [NSString stringWithFormat:@"%@ (x%d)", itemInfo.typeName, array.count];
		if (charge != NULL)
		{
			ItemInfo* chargeInfo = [ItemInfo itemInfoWithItem:charge error:nil];
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
		switch (structure->getState()) {
			case eufe::Module::STATE_ACTIVE:
				cell.stateView.image = [UIImage imageNamed:@"active.png"];
				break;
			case eufe::Module::STATE_ONLINE:
				cell.stateView.image = [UIImage imageNamed:@"active.png"];
				break;
			default:
				cell.stateView.image = [UIImage imageNamed:@"offline.png"];
				break;
		}
		
		return cell;
	}
}


#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return [[self tableView:aTableView cellForRowAtIndexPath:indexPath] frame].size.height;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
	eufe::ControlTower* controlTower = posFittingViewController.fit.controlTower;
	if (indexPath.row >= structures.count) {
		fittingItemsViewController.groupsRequest = @"SELECT * FROM invGroups WHERE groupID IN (311,363,397,404,413,416,417,426,430,438,439,440,441,443,444,449,471,473,707,709,837,838,839) ORDER BY groupName;";
		fittingItemsViewController.typesRequest = @"SELECT invMetaGroups.metaGroupID, invMetaGroups.metaGroupName, invTypes.* FROM invTypes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND groupID IN (311,363,397,404,413,416,417,426,430,438,439,440,441,443,444,449,471,473,707,709,837,838,839) %@ %@ ORDER BY invTypes.typeName;";
		fittingItemsViewController.title = @"Structures";
		fittingItemsViewController.group = nil;
		fittingItemsViewController.modifiedItem = nil;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[popoverController presentPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] inView:tableView permittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
		else
			[self.posFittingViewController presentModalViewController:fittingItemsViewController.navigationController animated:YES];
	}
	else {
		[modifiedIndexPath release];
		modifiedIndexPath = [indexPath retain];
		
		NSArray* array = [structures objectAtIndex:indexPath.row];
		ItemInfo* itemInfo = [array objectAtIndex:0];
		eufe::Structure* structure = dynamic_cast<eufe::Structure*>(itemInfo.item);
		const std::vector<eufe::TypeID>& chargeGroups = structure->getChargeGroups();
		bool multiple = false;
		int chargeSize = structure->getChargeSize();
		eufe::TypeID typeID = structure->getTypeID();
		if (chargeGroups.size() > 0)
		{
			const eufe::StructuresList& structuresList = controlTower->getStructures();
			eufe::StructuresList::const_iterator i, end = structuresList.end();
			for (i = structuresList.begin(); i != end; i++)
			{
				if ((*i)->getTypeID() != typeID)
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
		if (structure->getCharge() != nil)
			[actionSheet addButtonWithTitle:ActionButtonShowAmmoInfo];
		
		eufe::Module::State state = structure->getState();
		
		if (state >= eufe::Module::STATE_ACTIVE)
			[actionSheet addButtonWithTitle:ActionButtonOffline];
		else
			[actionSheet addButtonWithTitle:ActionButtonOnline];
		[actionSheet addButtonWithTitle:ActionButtonAmount];
		
		if (chargeGroups.size() > 0) {
			[actionSheet addButtonWithTitle:ActionButtonAmmoCurrentModule];
			if (multiple)
				[actionSheet addButtonWithTitle:ActionButtonAmmoAllModules];
			if (structure->getCharge() != nil)
				[actionSheet addButtonWithTitle:ActionButtonUnloadAmmo];
		}
		[actionSheet addButtonWithTitle:ActionButtonCancel];
		actionSheet.cancelButtonIndex = actionSheet.numberOfButtons - 1;
		
		[actionSheet showFromRect:[aTableView rectForRowAtIndexPath:indexPath] inView:aTableView animated:YES];
		[actionSheet autorelease];
	}
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSArray* array = [structures objectAtIndex:modifiedIndexPath.row];
	ItemInfo* itemInfo = [array objectAtIndex:0];
	eufe::Structure* structure = dynamic_cast<eufe::Structure*>(itemInfo.item);
	int chargeSize = structure->getChargeSize();
	NSString *button = [actionSheet buttonTitleAtIndex:buttonIndex];
	
	eufe::ControlTower* controlTower = posFittingViewController.fit.controlTower;
	
	if ([button isEqualToString:ActionButtonDelete]) {
		for (ItemInfo* itemInfo in array)
			controlTower->removeStructure(dynamic_cast<eufe::Structure*>(itemInfo.item));
		[self.posFittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonAmmo]) {
		const std::vector<eufe::TypeID>& chargeGroups = structure->getChargeGroups();
		bool multiple = false;
		int chargeSize = structure->getChargeSize();
		eufe::TypeID typeID = structure->getTypeID();
		if (chargeGroups.size() > 0)
		{
			const eufe::StructuresList& structuresList = controlTower->getStructures();
			eufe::StructuresList::const_iterator i, end = structuresList.end();
			for (i = structuresList.begin(); i != end; i++)
			{
				if ((*i)->getTypeID() != typeID)
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
		if (structure->getCharge() != NULL)
			[actionSheet addButtonWithTitle:ActionButtonUnloadAmmo];
		
		[actionSheet addButtonWithTitle:ActionButtonCancel];
		actionSheet.cancelButtonIndex = actionSheet.numberOfButtons - 1;
		
		[actionSheet showFromRect:[tableView rectForRowAtIndexPath:modifiedIndexPath] inView:tableView animated:YES];
		[actionSheet autorelease];
	}
	else if ([button isEqualToString:ActionButtonAmmoCurrentModule] || [button isEqualToString:ActionButtonAmmoAllModules]) {
		const std::vector<eufe::TypeID>& chargeGroups = structure->getChargeGroups();
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
		
		fittingItemsViewController.groupsRequest = [NSString stringWithFormat:@"SELECT * FROM invGroups WHERE groupID IN (%@) ORDER BY groupName;", groups];
		if (chargeSize) {
			fittingItemsViewController.typesRequest = [NSString stringWithFormat:@"SELECT invMetaGroups.metaGroupID, invMetaGroups.metaGroupName, invTypes.* FROM invTypes, dgmTypeAttributes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND invTypes.typeID=dgmTypeAttributes.typeID AND dgmTypeAttributes.attributeID=128 AND dgmTypeAttributes.value=%d AND groupID IN (%@) %%@ %%@ ORDER BY invTypes.typeName;",
													   chargeSize, groups];
		}
		else {
			fittingItemsViewController.typesRequest = [NSString stringWithFormat:@"SELECT invMetaGroups.metaGroupID, invMetaGroups.metaGroupName, invTypes.* FROM invTypes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND groupID IN (%@) AND invTypes.volume <= %f %%@ %%@ ORDER BY invTypes.typeName;",
													   groups, structure->getAttribute(eufe::CAPACITY_ATTRIBUTE_ID)->getValue()];
		}
		fittingItemsViewController.title = @"Ammo";
		if ([button isEqualToString:ActionButtonAmmoAllModules])
			fittingItemsViewController.modifiedItem = nil;
		else
			fittingItemsViewController.modifiedItem = itemInfo;
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[popoverController presentPopoverFromRect:[tableView rectForRowAtIndexPath:modifiedIndexPath] inView:tableView permittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
		else
			[self.posFittingViewController presentModalViewController:fittingItemsViewController.navigationController animated:YES];
		
		
		if ([button isEqualToString:ActionButtonAmmoAllModules]) {
			[modifiedIndexPath release];
			modifiedIndexPath = nil;
		}
		[self.posFittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonOffline]) {
		for (ItemInfo* itemInfo in array)
			dynamic_cast<eufe::Structure*>(itemInfo.item)->setState(eufe::Module::STATE_OFFLINE);
		[self.posFittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonOnline]) {
		for (ItemInfo* itemInfo in array)
			dynamic_cast<eufe::Structure*>(itemInfo.item)->setState(eufe::Module::STATE_ACTIVE);
		[self.posFittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonUnloadAmmo]) {
		structure->clearCharge();
		[self.posFittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonAmount]) {
		DronesAmountViewController *dronesAmountViewController = [[DronesAmountViewController alloc] initWithNibName:@"DronesAmountViewController" bundle:nil];
		dronesAmountViewController.amount = array.count;
		dronesAmountViewController.maxAmount = 50;
		dronesAmountViewController.delegate = self;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[dronesAmountViewController presentPopoverFromRect:[tableView rectForRowAtIndexPath:modifiedIndexPath] inView:tableView permittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
		else
			[dronesAmountViewController presentAnimated:YES];
		[dronesAmountViewController release];
	}
	else if ([button isEqualToString:ActionButtonShowModuleInfo]) {
		ItemViewController *itemViewController = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		[itemInfo updateAttributes];
		itemViewController.type = itemInfo;
		[itemViewController setActivePage:ItemViewControllerActivePageInfo];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:itemViewController];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[posFittingViewController presentModalViewController:navController animated:YES];
			[navController release];
		}
		else
			[posFittingViewController.navigationController pushViewController:itemViewController animated:YES];
		[itemViewController release];
	}
	else if ([button isEqualToString:ActionButtonShowAmmoInfo]) {
		ItemViewController *itemViewController = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		ItemInfo* ammo = [ItemInfo itemInfoWithItem:structure->getCharge() error:nil];
		[ammo updateAttributes];
		itemViewController.type = ammo;
		[itemViewController setActivePage:ItemViewControllerActivePageInfo];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:itemViewController];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[posFittingViewController presentModalViewController:navController animated:YES];
			[navController release];
		}
		else
			[posFittingViewController.navigationController pushViewController:itemViewController animated:YES];
		[itemViewController release];
	}
}

#pragma mark DronesAmountViewControllerDelegate

- (void) dronesAmountViewController:(DronesAmountViewController*) aController didSelectAmount:(NSInteger) amount {
	eufe::ControlTower* controlTower = posFittingViewController.fit.controlTower;
	NSMutableArray* array = [structures objectAtIndex:modifiedIndexPath.row];
	int left = array.count - amount;
	if (left < 0) {
		ItemInfo* itemInfo = [array objectAtIndex:0];
		eufe::Structure* structure = dynamic_cast<eufe::Structure*>(itemInfo.item);
		for (;left < 0; left++)
			controlTower->addStructure(new eufe::Structure(*structure))->setCharge(structure->getCharge());
	}
	else if (left > 0) {
		int i = 0;
		for (; left > 0; left--) {
			ItemInfo* itemInfo = [array objectAtIndex:i++];
			eufe::Structure* structure = dynamic_cast<eufe::Structure*>(itemInfo.item);
			controlTower->removeStructure(structure);
		}
	}
	[posFittingViewController update];
}

- (void) dronesAmountViewControllerDidCancel:(DronesAmountViewController*) controller {
}

#pragma mark FittingSection

- (void) update {
	__block float totalPG;
	__block float usedPG;
	__block float totalCPU;
	__block float usedCPU;
	
	NSMutableArray *structuresTmp = [NSMutableArray array];
	POSFittingViewController* aPosFittingViewController = posFittingViewController;
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"ModulesViewController+Update" name:@"Updating POS Structures"];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		@synchronized(posFittingViewController) {
			eufe::ControlTower* controlTower = aPosFittingViewController.fit.controlTower;
			
			NSMutableDictionary* structuresDic = [NSMutableDictionary dictionary];
			
			const eufe::StructuresList& structuresList = controlTower->getStructures();
			eufe::StructuresList::const_iterator i, end = structuresList.end();
			float n = structuresList.size();
			float j = 0;
			for (i = structuresList.begin(); i != end; i++) {
				operation.progress = j++ / n;
				NSString* key = [NSString stringWithFormat:@"%d", (*i)->getTypeID()];
				NSMutableArray* array = [structuresDic valueForKey:key];
				if (!array) {
					array = [NSMutableArray array];
					[structuresDic setValue:array forKey:key];
					[structuresTmp addObject:array];
				}
				[array addObject:[ItemInfo itemInfoWithItem:*i error:nil]];
			}

			
			totalPG = controlTower->getTotalPowerGrid();
			usedPG = controlTower->getPowerGridUsed();
			
			totalCPU = controlTower->getTotalCpu();
			usedCPU = controlTower->getCpuUsed();
		}
		
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			if (structures)
				[structures release];
			structures  = [structuresTmp retain];
			
			powerGridLabel.text = [NSString stringWithTotalResources:totalPG usedResources:usedPG unit:@"MW"];
			powerGridLabel.progress = totalPG > 0 ? usedPG / totalPG : 0;
			cpuLabel.text = [NSString stringWithTotalResources:totalCPU usedResources:usedCPU unit:@"tf"];
			cpuLabel.progress = usedCPU > 0 ? usedCPU / totalCPU : 0;
			[tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end