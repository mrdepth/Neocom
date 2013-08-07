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

#define ActionButtonOffline NSLocalizedString(@"Put Offline", nil)
#define ActionButtonOnline NSLocalizedString(@"Put Online", nil)
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
#define ActionButtonAmount NSLocalizedString(@"Set Amount", nil)

@interface StructuresViewController()
@property(nonatomic, strong) NSMutableArray *structures;
@property(nonatomic, strong) NSIndexPath *modifiedIndexPath;


@end

@implementation StructuresViewController
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
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self update];
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.structures.count + 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	if (indexPath.row >= self.structures.count) {
		NSString *cellIdentifier = @"ModuleCellView";
		ModuleCellView *cell = (ModuleCellView*) [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [ModuleCellView cellWithNibName:@"ModuleCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		cell.stateView.image = nil;
		cell.targetView.image = nil;
		cell.iconView.image = [UIImage imageNamed:@"slotRig.png"];
		cell.titleLabel.text = NSLocalizedString(@"Add Structure", nil);
		return cell;
	}
	else {
		NSArray* array = [self.structures objectAtIndex:indexPath.row];
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
	eufe::ControlTower* controlTower = self.posFittingViewController.fit.controlTower;
	if (indexPath.row >= self.structures.count) {
		/*fittingItemsViewController.groupsRequest = @"SELECT * FROM invGroups WHERE groupID IN (311,363,397,404,413,416,417,426,430,438,439,440,441,443,444,449,471,473,707,709,837,838,839) ORDER BY groupName;";
		fittingItemsViewController.typesRequest = @"SELECT invMetaGroups.metaGroupID, invMetaGroups.metaGroupName, invTypes.* FROM invTypes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND groupID IN (311,363,397,404,413,416,417,426,430,438,439,440,441,443,444,449,471,473,707,709,837,838,839) %@ %@ ORDER BY invTypes.typeName;";*/
		self.fittingItemsViewController.marketGroupID = 1285;
		self.fittingItemsViewController.except = @[@(478)];
		self.fittingItemsViewController.title = NSLocalizedString(@"Structures", nil);
		//fittingItemsViewController.group = nil;
		self.fittingItemsViewController.modifiedItem = nil;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[self.popoverController presentPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] inView:self.tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else
			[self.posFittingViewController presentModalViewController:self.fittingItemsViewController.navigationController animated:YES];
	}
	else {
		self.modifiedIndexPath = indexPath;
		
		NSArray* array = [self.structures objectAtIndex:indexPath.row];
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
	}
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSArray* array = [self.structures objectAtIndex:self.modifiedIndexPath.row];
	ItemInfo* itemInfo = [array objectAtIndex:0];
	eufe::Structure* structure = dynamic_cast<eufe::Structure*>(itemInfo.item);
	int chargeSize = structure->getChargeSize();
	NSString *button = [actionSheet buttonTitleAtIndex:buttonIndex];
	
	eufe::ControlTower* controlTower = self.posFittingViewController.fit.controlTower;
	
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
		
		[actionSheet showFromRect:[self.tableView rectForRowAtIndexPath:self.modifiedIndexPath] inView:self.tableView animated:YES];
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
		
/*		fittingItemsViewController.groupsRequest = [NSString stringWithFormat:@"SELECT * FROM invGroups WHERE groupID IN (%@) ORDER BY groupName;", groups];
		if (chargeSize) {
			fittingItemsViewController.typesRequest = [NSString stringWithFormat:@"SELECT invMetaGroups.metaGroupID, invMetaGroups.metaGroupName, invTypes.* FROM invTypes, dgmTypeAttributes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND invTypes.typeID=dgmTypeAttributes.typeID AND dgmTypeAttributes.attributeID=128 AND dgmTypeAttributes.value=%d AND groupID IN (%@) %%@ %%@ ORDER BY invTypes.typeName;",
													   chargeSize, groups];
		}
		else {
			fittingItemsViewController.typesRequest = [NSString stringWithFormat:@"SELECT invMetaGroups.metaGroupID, invMetaGroups.metaGroupName, invTypes.* FROM invTypes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND groupID IN (%@) AND invTypes.volume <= %f %%@ %%@ ORDER BY invTypes.typeName;",
													   groups, structure->getAttribute(eufe::CAPACITY_ATTRIBUTE_ID)->getValue()];
		}*/
		
		self.fittingItemsViewController.marketGroupID = 0;
		if (chargeSize) {
			self.fittingItemsViewController.typesRequest = [NSString stringWithFormat:@"SELECT invMetaGroups.*, invTypes.* FROM invTypes, dgmTypeAttributes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND invTypes.typeID=dgmTypeAttributes.typeID AND dgmTypeAttributes.attributeID=128 AND dgmTypeAttributes.value=%d AND groupID IN (%@) ORDER BY invTypes.typeName;",
													   chargeSize, groups];
			self.fittingItemsViewController.searchRequest = [NSString stringWithFormat:@"SELECT invMetaGroups.*, invTypes.* FROM invTypes, dgmTypeAttributes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND invTypes.typeID=dgmTypeAttributes.typeID AND dgmTypeAttributes.attributeID=128 AND dgmTypeAttributes.value=%d AND groupID IN (%@) AND typeName LIKE \"%%%%%%@%%%%\" ORDER BY invTypes.typeName;",
														chargeSize, groups];
		}
		else {
			self.fittingItemsViewController.typesRequest = [NSString stringWithFormat:@"SELECT invMetaGroups.*, invTypes.* FROM invTypes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND groupID IN (%@) AND invTypes.volume <= %f ORDER BY invTypes.typeName;",
													   groups, structure->getAttribute(eufe::CAPACITY_ATTRIBUTE_ID)->getValue()];
			self.fittingItemsViewController.searchRequest = [NSString stringWithFormat:@"SELECT invMetaGroups.*, invTypes.* FROM invTypes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND groupID IN (%@) AND invTypes.volume <= %f AND typeName LIKE \"%%%%%%@%%%%\" ORDER BY invTypes.typeName;",
														groups, structure->getAttribute(eufe::CAPACITY_ATTRIBUTE_ID)->getValue()];
		}

		self.fittingItemsViewController.title = NSLocalizedString(@"Ammo", nil);
		if ([button isEqualToString:ActionButtonAmmoAllModules])
			self.fittingItemsViewController.modifiedItem = nil;
		else
			self.fittingItemsViewController.modifiedItem = itemInfo;
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[self.popoverController presentPopoverFromRect:[self.tableView rectForRowAtIndexPath:self.modifiedIndexPath] inView:self.tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else
			[self.posFittingViewController presentModalViewController:self.fittingItemsViewController.navigationController animated:YES];
		
		if ([button isEqualToString:ActionButtonAmmoAllModules]) {
			self.modifiedIndexPath = nil;
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
		/*dronesAmountViewController.delegate = self;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[dronesAmountViewController presentPopoverFromRect:[self.tableView rectForRowAtIndexPath:self.modifiedIndexPath] inView:self.tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else
			[dronesAmountViewController presentAnimated:YES];*/
	}
	else if ([button isEqualToString:ActionButtonShowModuleInfo]) {
		ItemViewController *itemViewController = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		[itemInfo updateAttributes];
		itemViewController.type = itemInfo;
		[itemViewController setActivePage:ItemViewControllerActivePageInfo];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:itemViewController];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self.posFittingViewController presentModalViewController:navController animated:YES];
		}
		else
			[self.posFittingViewController.navigationController pushViewController:itemViewController animated:YES];
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
			[self.posFittingViewController presentModalViewController:navController animated:YES];
		}
		else
			[self.posFittingViewController.navigationController pushViewController:itemViewController animated:YES];
	}
}

#pragma mark DronesAmountViewControllerDelegate

- (void) dronesAmountViewController:(DronesAmountViewController*) aController didSelectAmount:(NSInteger) amount {
	eufe::ControlTower* controlTower = self.posFittingViewController.fit.controlTower;
	NSMutableArray* array = [self.structures objectAtIndex:self.modifiedIndexPath.row];
	int left = array.count - amount;
	if (left < 0) {
		ItemInfo* itemInfo = [array objectAtIndex:0];
		eufe::Structure* structure = dynamic_cast<eufe::Structure*>(itemInfo.item);
		for (;left < 0; left++)
			controlTower->addStructure(new eufe::Structure(*structure))->setCharge(structure->getCharge());
	}
	else if (left > 0) {
		int i = array.count - 1;
		for (; left > 0; left--) {
			ItemInfo* itemInfo = [array objectAtIndex:i--];
			eufe::Structure* structure = dynamic_cast<eufe::Structure*>(itemInfo.item);
			controlTower->removeStructure(structure);
		}
	}
	[self.posFittingViewController update];
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
	POSFittingViewController* aPosFittingViewController = self.posFittingViewController;
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"ModulesViewController+Update" name:NSLocalizedString(@"Updating POS Structures", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		@synchronized(self.posFittingViewController) {
			eufe::ControlTower* controlTower = aPosFittingViewController.fit.controlTower;
			
			NSMutableDictionary* structuresDic = [NSMutableDictionary dictionary];
			
			const eufe::StructuresList& structuresList = controlTower->getStructures();
			eufe::StructuresList::const_iterator i, end = structuresList.end();
			float n = structuresList.size();
			float j = 0;
			for (i = structuresList.begin(); i != end; i++) {
				weakOperation.progress = j++ / n;
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
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.structures  = structuresTmp;
			
			self.powerGridLabel.text = [NSString stringWithTotalResources:totalPG usedResources:usedPG unit:@"MW"];
			self.powerGridLabel.progress = totalPG > 0 ? usedPG / totalPG : 0;
			self.cpuLabel.text = [NSString stringWithTotalResources:totalCPU usedResources:usedCPU unit:@"tf"];
			self.cpuLabel.progress = usedCPU > 0 ? usedCPU / totalCPU : 0;
			[self.tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end