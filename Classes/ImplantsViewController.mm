//
//  ImplantsViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ImplantsViewController.h"
#import "FittingViewController.h"
#import "ModuleCellView.h"
#import "UITableViewCell+Nib.h"
#import "NSString+Fitting.h"
#import "ItemViewController.h"
#import "EUOperationQueue.h"
#import "EVEDBAPI.h"

#import "ItemInfo.h"
#import "ShipFit.h"

#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)
#define ActionButtonDelete NSLocalizedString(@"Delete", nil)
#define ActionButtonShowInfo NSLocalizedString(@"Show Info", nil)

@interface ImplantsViewController()
@property (nonatomic, strong) NSMutableDictionary *implants;
@property (nonatomic, strong) NSMutableDictionary *boosters;
@property (nonatomic, strong) NSIndexPath *modifiedIndexPath;


@end

@implementation ImplantsViewController
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

/*
 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 - (void)viewDidLoad {
 [super viewDidLoad];
 }
 */

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self update];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.tableView = nil;
	self.implantsHeaderView = nil;
	self.boostersHeaderView = nil;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return section == 0 ? 10 : 4;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	ItemInfo* itemInfo = nil;
	if (indexPath.section == 0)
		itemInfo = [self.implants valueForKey:[NSString stringWithFormat:@"%d", indexPath.row + 1]];
	else
		itemInfo = [self.boosters valueForKey:[NSString stringWithFormat:@"%d", indexPath.row + 1]];
	if (!itemInfo) {
		NSString *cellIdentifier = @"ModuleCellView";
		ModuleCellView *cell = (ModuleCellView*) [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [ModuleCellView cellWithNibName:@"ModuleCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		cell.iconView.image = [UIImage imageNamed:indexPath.section == 0 ? @"implant.png" : @"booster.png"];
		cell.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Slot %d", nil), indexPath.row + 1];
		cell.stateView.image = nil;
		return cell;
	}
	else {
		NSString *cellIdentifier = @"ModuleCellView";
		
		ModuleCellView *cell = (ModuleCellView*) [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [ModuleCellView cellWithNibName:@"ModuleCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		cell.stateView.image = [UIImage imageNamed:@"active.png"];
		
		cell.titleLabel.text = itemInfo.typeName;
		cell.iconView.image = [UIImage imageNamed:[itemInfo typeSmallImageName]];
		return cell;
	}
}


#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return self.implantsHeaderView;
	else
		return self.boostersHeaderView;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return [[self tableView:aTableView cellForRowAtIndexPath:indexPath] frame].size.height;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
	
	ItemInfo* itemInfo = nil;
	if (indexPath.section == 0)
		itemInfo = [self.implants valueForKey:[NSString stringWithFormat:@"%d", indexPath.row + 1]];
	else
		itemInfo = [self.boosters valueForKey:[NSString stringWithFormat:@"%d", indexPath.row + 1]];

	
	if (!itemInfo) {
//		NSString *groups = nil;
//		NSInteger attributeID = 0;
		
		if (indexPath.section == 0) {
			/*groups = @"300,738,740,741,742,743,744,745,746,747,748,749,783";
			fittingItemsViewController.groupsRequest = [NSString stringWithFormat:@"SELECT * FROM invGroups WHERE groupID IN (%@) ORDER BY groupName;", groups];
			fittingItemsViewController.typesRequest = [NSString stringWithFormat:@"SELECT invMetaGroups.metaGroupID, invMetaGroups.metaGroupName, invTypes.* FROM invTypes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND groupID IN (%@) %%@ %%@ ORDER BY invTypes.typeName;",
													   groups];
			fittingItemsViewController.group = nil;*/
			self.fittingItemsViewController.marketGroupID = 27;
			self.fittingItemsViewController.title = NSLocalizedString(@"Implants", nil);
		}
		else {
			/*attributeID = 1087;
			fittingItemsViewController.groupsRequest = nil;
			fittingItemsViewController.typesRequest = [NSString stringWithFormat:@"SELECT invMetaGroups.metaGroupID, invMetaGroups.metaGroupName, invTypes.* FROM invTypes, dgmTypeAttributes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND invTypes.typeID=dgmTypeAttributes.typeID AND dgmTypeAttributes.attributeID=%d AND dgmTypeAttributes.value=%d int (%@) %%@ %%@ ORDER BY invTypes.typeName;",
													   attributeID, indexPath.row + 1, groups];
			fittingItemsViewController.group = [EVEDBInvGroup invGroupWithGroupID:303 error:nil];*/
			self.fittingItemsViewController.marketGroupID = 977;
			self.fittingItemsViewController.title = NSLocalizedString(@"Boosters", nil);
		}
		self.fittingItemsViewController.modifiedItem = nil;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[self.popoverController presentPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] inView:self.tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else
			[self.fittingViewController presentModalViewController:self.fittingItemsViewController.navigationController animated:YES];
	}
	else {
		UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
																 delegate:self
														cancelButtonTitle:nil
												   destructiveButtonTitle:nil
														otherButtonTitles:nil];
		[actionSheet addButtonWithTitle:ActionButtonShowInfo];
		[actionSheet addButtonWithTitle:ActionButtonDelete];
		[actionSheet addButtonWithTitle:ActionButtonCancel];
		actionSheet.destructiveButtonIndex = actionSheet.numberOfButtons - 2;
		actionSheet.cancelButtonIndex = actionSheet.numberOfButtons - 1;
		
		[actionSheet showFromRect:[aTableView rectForRowAtIndexPath:indexPath] inView:aTableView animated:YES];
		self.modifiedIndexPath = indexPath;
	}
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *button = [actionSheet buttonTitleAtIndex:buttonIndex];
	if ([button isEqualToString:ActionButtonDelete]) {
		if (self.modifiedIndexPath.section == 0) {
			ItemInfo* itemInfo = [self.implants valueForKey:[NSString stringWithFormat:@"%d", self.modifiedIndexPath.row + 1]];
			self.fittingViewController.fit.character->removeImplant(dynamic_cast<eufe::Implant*>(itemInfo.item));
		}
		else {
			ItemInfo* itemInfo = [self.boosters valueForKey:[NSString stringWithFormat:@"%d", self.modifiedIndexPath.row + 1]];
			self.fittingViewController.fit.character->removeBooster(dynamic_cast<eufe::Booster*>(itemInfo.item));
		}
		[self.fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonShowInfo]) {
		ItemInfo* type;
		if (self.modifiedIndexPath.section == 0) {
			type = [self.implants valueForKey:[NSString stringWithFormat:@"%d", self.modifiedIndexPath.row + 1]];
		}
		else {
			type = [self.boosters valueForKey:[NSString stringWithFormat:@"%d", self.modifiedIndexPath.row + 1]];
		}
		
		ItemViewController *itemViewController = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		
		[type updateAttributes];
		itemViewController.type = type;
		[itemViewController setActivePage:ItemViewControllerActivePageInfo];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:itemViewController];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self.fittingViewController presentModalViewController:navController animated:YES];
		}
		else
			[self.fittingViewController.navigationController pushViewController:itemViewController animated:YES];
	}
}

#pragma mark FittingSection

- (void) update {
	NSMutableDictionary *implantsTmp = [NSMutableDictionary dictionary];
	NSMutableDictionary *boostersTmp = [NSMutableDictionary dictionary];

	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"ImplantsViewController+Update" name:NSLocalizedString(@"Updating Implants", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		@synchronized(self.fittingViewController) {
			eufe::Character* character = self.fittingViewController.fit.character;
			const eufe::ImplantsList& implantsList = character->getImplants();
			eufe::ImplantsList::const_iterator i, end = implantsList.end();
			for (i = implantsList.begin(); i != end; i++)
				[implantsTmp setValue:[ItemInfo itemInfoWithItem:*i error:nil] forKey:[NSString stringWithFormat:@"%d", (*i)->getSlot()]];
			
			const eufe::BoostersList& boostersList = character->getBoosters();
			eufe::BoostersList::const_iterator j, endj = boostersList.end();
			for (j = boostersList.begin(); j != endj; j++)
				[boostersTmp setValue:[ItemInfo itemInfoWithItem:*j error:nil] forKey:[NSString stringWithFormat:@"%d", (*j)->getSlot()]];
		}
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.implants = implantsTmp;
			self.boosters = boostersTmp;
			[self.tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end
