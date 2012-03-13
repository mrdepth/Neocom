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
#import "NibTableViewCell.h"
#import "NSString+Fitting.h"
#import "ItemViewController.h"
#import "EUOperationQueue.h"
#import "EVEDBAPI.h"

#import "ItemInfo.h"
#import "Fit.h"

#define ActionButtonCancel @"Cancel"
#define ActionButtonDelete @"Delete"
#define ActionButtonShowInfo @"Show Info"

@implementation ImplantsViewController
@synthesize fittingViewController;
@synthesize tableView;
@synthesize implantsHeaderView;
@synthesize boostersHeaderView;
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

/*
 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 - (void)viewDidLoad {
 [super viewDidLoad];
 }
 */

- (void) viewWillAppear:(BOOL)animated {
	[self update];
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
	self.implantsHeaderView = nil;
	self.boostersHeaderView = nil;
}


- (void)dealloc {
	[tableView release];
	[implantsHeaderView release];
	[boostersHeaderView release];
	[fittingItemsViewController release];
	[popoverController release];
	[implants release];
	[boosters release];
	[modifiedIndexPath release];
    [super dealloc];
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
		itemInfo = [implants valueForKey:[NSString stringWithFormat:@"%d", indexPath.row + 1]];
	else
		itemInfo = [boosters valueForKey:[NSString stringWithFormat:@"%d", indexPath.row + 1]];
	if (!itemInfo) {
		NSString *cellIdentifier = @"ModuleCellView";
		ModuleCellView *cell = (ModuleCellView*) [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [ModuleCellView cellWithNibName:@"ModuleCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		cell.iconView.image = [UIImage imageNamed:indexPath.section == 0 ? @"implant.png" : @"booster.png"];
		cell.titleLabel.text = [NSString stringWithFormat:@"Slot %d", indexPath.row + 1];
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
		return implantsHeaderView;
	else
		return boostersHeaderView;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return [[self tableView:aTableView cellForRowAtIndexPath:indexPath] frame].size.height;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
	
	ItemInfo* itemInfo = nil;
	if (indexPath.section == 0)
		itemInfo = [implants valueForKey:[NSString stringWithFormat:@"%d", indexPath.row + 1]];
	else
		itemInfo = [boosters valueForKey:[NSString stringWithFormat:@"%d", indexPath.row + 1]];

	
	if (!itemInfo) {
		NSString *groups = nil;
		NSInteger attributeID = 0;
		
		if (indexPath.section == 0) {
			groups = @"300,738,740,741,742,743,744,745,746,747,748,749,783";
			fittingItemsViewController.groupsRequest = [NSString stringWithFormat:@"SELECT * FROM invGroups WHERE groupID IN (%@) ORDER BY groupName;", groups];
			fittingItemsViewController.typesRequest = [NSString stringWithFormat:@"SELECT invMetaGroups.metaGroupID, invMetaGroups.metaGroupName, invTypes.* FROM invTypes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND groupID IN (%@) %%@ %%@ ORDER BY invTypes.typeName;",
													   groups];
			fittingItemsViewController.title = @"Implants";
			fittingItemsViewController.group = nil;
		}
		else {
			attributeID = 1087;
			fittingItemsViewController.groupsRequest = nil;
			fittingItemsViewController.typesRequest = [NSString stringWithFormat:@"SELECT invMetaGroups.metaGroupID, invMetaGroups.metaGroupName, invTypes.* FROM invTypes, dgmTypeAttributes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND invTypes.typeID=dgmTypeAttributes.typeID AND dgmTypeAttributes.attributeID=%d AND dgmTypeAttributes.value=%d %%@ %%@ ORDER BY invTypes.typeName;",
													   attributeID, indexPath.row + 1, groups];
			fittingItemsViewController.group = [EVEDBInvGroup invGroupWithGroupID:303 error:nil];
			fittingItemsViewController.title = @"Boosters";
		}
		fittingItemsViewController.modifiedItem = nil;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[popoverController presentPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] inView:tableView permittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
		else
			[self.fittingViewController presentModalViewController:fittingItemsViewController.navigationController animated:YES];
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
		[actionSheet autorelease];
		[modifiedIndexPath release];
		modifiedIndexPath = [indexPath retain];
	}
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *button = [actionSheet buttonTitleAtIndex:buttonIndex];
	if ([button isEqualToString:ActionButtonDelete]) {
		if (modifiedIndexPath.section == 0) {
			ItemInfo* itemInfo = [implants valueForKey:[NSString stringWithFormat:@"%d", modifiedIndexPath.row + 1]];
			fittingViewController.fit.character.get()->removeImplant(boost::dynamic_pointer_cast<eufe::Implant>(itemInfo.item));
		}
		else {
			ItemInfo* itemInfo = [boosters valueForKey:[NSString stringWithFormat:@"%d", modifiedIndexPath.row + 1]];
			fittingViewController.fit.character.get()->removeBooster(boost::dynamic_pointer_cast<eufe::Booster>(itemInfo.item));
		}
		[fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonShowInfo]) {
		ItemInfo* type;
		if (modifiedIndexPath.section == 0) {
			type = [implants valueForKey:[NSString stringWithFormat:@"%d", modifiedIndexPath.row + 1]];
		}
		else {
			type = [boosters valueForKey:[NSString stringWithFormat:@"%d", modifiedIndexPath.row + 1]];
		}
		
		ItemViewController *itemViewController = [[ItemViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"ItemViewController-iPad" : @"ItemViewController")
																					  bundle:nil];
		
		[type updateAttributes];
		itemViewController.type = type;
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
	NSMutableDictionary *implantsTmp = [NSMutableDictionary dictionary];
	NSMutableDictionary *boostersTmp = [NSMutableDictionary dictionary];
	__block EUSingleBlockOperation *operation = [EUSingleBlockOperation operationWithIdentifier:@"ImplantsViewController+Update"];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		@synchronized(fittingViewController) {
			boost::shared_ptr<eufe::Character> character = fittingViewController.fit.character;
			const eufe::ImplantsList& implantsList = character->getImplants();
			eufe::ImplantsList::const_iterator i, end = implantsList.end();
			for (i = implantsList.begin(); i != end; i++)
				[implantsTmp setValue:[ItemInfo itemInfoWithItem:*i error:nil] forKey:[NSString stringWithFormat:@"%d", (*i)->getSlot()]];
			
			const eufe::BoostersList& boostersList = character->getBoosters();
			eufe::BoostersList::const_iterator j, endj = boostersList.end();
			for (j = boostersList.begin(); j != endj; j++)
				[boostersTmp setValue:[ItemInfo itemInfoWithItem:*j error:nil] forKey:[NSString stringWithFormat:@"%d", (*j)->getSlot()]];
		}
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			if (implants)
				[implants release];
			implants = [implantsTmp retain];

			if (boosters)
				[boosters release];
			boosters = [boostersTmp retain];

			[tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end
