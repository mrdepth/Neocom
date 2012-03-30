//
//  FittingServiceMenuViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FittingServiceMenuViewController.h"
#import "MainMenuCellView.h"
#import "FitCellView.h"
#import "NibTableViewCell.h"
#import "Globals.h"
#import "FittingViewController.h"
#import "POSFittingViewController.h"
#import "EVEDBAPI.h"
#import "BCSearchViewController.h"
#import "Fit.h"
#import "POSFit.h"
#import "EVEAccount.h"
#import "CharacterEVE.h"
#import "NSArray+GroupBy.h"


@implementation FittingServiceMenuViewController
@synthesize menuTableView;
@synthesize fittingItemsViewController;
@synthesize modalController;
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
	self.title = @"Fitting";
	[self.navigationItem setRightBarButtonItem:self.editButtonItem];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.popoverController = [[[UIPopoverController alloc] initWithContentViewController:modalController] autorelease];
		self.popoverController.delegate = (FittingItemsViewController*)  self.modalController.topViewController;
	}
}



// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	__block EUSingleBlockOperation* operation = [EUSingleBlockOperation operationWithIdentifier:@"FittingServiceMenuViewController+Load"];
	NSMutableArray* fitsTmp = [NSMutableArray array];
	[operation addExecutionBlock:^{
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		NSMutableArray *fitsArray = [NSMutableArray arrayWithContentsOfURL:[NSURL fileURLWithPath:[Globals fitsFilePath]]];
		lastID = [[[fitsArray lastObject] valueForKey:@"fitID"] integerValue];
		
		for (NSMutableDictionary* row in fitsArray) {
			EVEDBInvType* type;
			if (![row valueForKey:@"isPOS"])
				[row setValue:[NSNumber numberWithBool:NO] forKey:@"isPOS"];
			if ([[row valueForKey:@"isPOS"] boolValue])
				type = [EVEDBInvType invTypeWithTypeID:[[row valueForKeyPath:@"fit.controlTowerID"] integerValue] error:nil];
			else
				type = [EVEDBInvType invTypeWithTypeID:[[row valueForKeyPath:@"fit.shipID"] integerValue] error:nil];
			if (type) {
				[row setValue:type forKey:@"type"];
				[row setValue:[type typeSmallImageName] forKey:@"imageName"];
			}
		}
		[fitsArray sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"shipName" ascending:YES]]];
		[fitsTmp addObjectsFromArray:[fitsArray arrayGroupedByKey:@"type.groupID"]];
		[fitsTmp sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
			NSDictionary* a = [obj1 objectAtIndex:0];
			NSDictionary* b = [obj2 objectAtIndex:0];
			NSComparisonResult result = [[a valueForKey:@"isPOS"] compare:[b valueForKey:@"isPOS"]];
			if (result == NSOrderedSame)
				return [[a valueForKeyPath:@"type.group.groupName"] compare:[b valueForKeyPath:@"type.group.groupName"]];
			else
				return result;
		}];
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^{
		if (![operation isCancelled]) {
			[fits release];
			fits = [fitsTmp retain];
			[menuTableView reloadData];
		}
	}];
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.menuTableView = nil;
	self.fittingItemsViewController = nil;
	self.modalController = nil;
	self.popoverController = nil;
	[fits release];
	fits = nil;
}


- (void)dealloc {
	[menuTableView release];
	[fittingItemsViewController release];
	[modalController release];
	[popoverController release];
	[fits release];

    [super dealloc];
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	[menuTableView setEditing:editing animated:animated];
	if (!editing) {
		NSMutableArray* allFits = [NSMutableArray array];
		for (NSArray* rows in fits) {
			for (NSDictionary* row in rows) {
				NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithDictionary:row];
				[dictionary setValue:nil forKey:@"type"];
				[allFits addObject:dictionary];
			}
		}
		
		[[allFits sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"fitID" ascending:YES]]]
		 writeToURL:[NSURL fileURLWithPath:[Globals fitsFilePath]] atomically:YES];
	}
}

- (IBAction) didCloseModalViewController:(id) sender {
	[self dismissModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return [fits count] + 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return section == 0 ? 3 : [[fits objectAtIndex:section - 1] count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
		NSString *cellIdentifier = @"MainMenuCellView";
		
		MainMenuCellView *cell = (MainMenuCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [MainMenuCellView cellWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"MainMenuCellView-iPad" : @"MainMenuCellView")
											  bundle:nil
									 reuseIdentifier:cellIdentifier];
		}
		if (indexPath.row == 0) {
			cell.titleLabel.text = @"Browse Fits on BattleClinic";
			cell.iconImageView.image = [UIImage imageNamed:@"battleclinic.png"];
		}
		else if (indexPath.row == 1) {
			cell.titleLabel.text = @"New Ship Fit";
			cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon17_04.png"];
		}
		else {
			cell.titleLabel.text = @"New POS Fit";
			cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon07_06.png"];
		}
		return cell;
	}
	else {
		NSString *cellIdentifier = @"FitCellView";
		
		FitCellView *cell = (FitCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [FitCellView cellWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"FitCellView-iPad" : @"FitCellView")
										 bundle:nil
								reuseIdentifier:cellIdentifier];
		}
		NSDictionary *fit = [[fits objectAtIndex:indexPath.section - 1] objectAtIndex:indexPath.row];
		cell.shipNameLabel.text = [fit valueForKey:@"shipName"];
		cell.fitNameLabel.text = [fit valueForKey:@"fitName"];
		cell.iconView.image = [UIImage imageNamed:[fit valueForKey:@"imageName"]];
		return cell;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return @"Menu";
	else {
		NSArray* rows = [fits objectAtIndex:section - 1];
		if (rows.count > 0)
			return [[rows objectAtIndex:0] valueForKeyPath:@"type.group.groupName"];
		else
			return @"";
	}
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (UITableViewCellEditingStyleDelete) {
		NSMutableArray* rows = [fits objectAtIndex:indexPath.section - 1];
		[rows removeObjectAtIndex:indexPath.row];

		if (rows.count == 0) {
			[fits removeObjectAtIndex:indexPath.section - 1];
			[menuTableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
		}
		else {
			[menuTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		}
	}
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)] autorelease];
	header.opaque = NO;
	header.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9];
	
	UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, 0, 300, 22)] autorelease];
	label.opaque = NO;
	label.backgroundColor = [UIColor clearColor];
	label.text = [self tableView:tableView titleForHeaderInSection:section];
	label.textColor = [UIColor whiteColor];
	label.font = [label.font fontWithSize:12];
	label.shadowColor = [UIColor blackColor];
	label.shadowOffset = CGSizeMake(1, 1);
	[header addSubview:label];
	return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0)
		return 45;
	else
		return 36;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.section == 0) {
		if (indexPath.row == 0) {
			BCSearchViewController *controller = [[BCSearchViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"BCSearchViewController-iPad" : @"BCSearchViewController")
																						  bundle:nil];
			[self.navigationController pushViewController:controller animated:YES];
			[controller release];
		}
		else if (indexPath.row == 1) {
			fittingItemsViewController.groupsRequest = @"SELECT * FROM invGroups WHERE categoryID = 6 ORDER BY groupName;";
			fittingItemsViewController.typesRequest = @"SELECT invMetaGroups.metaGroupID, invMetaGroups.metaGroupName, invTypes.* FROM invTypes, invGroups LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND invTypes.groupID = invGroups.groupID and invGroups.categoryID = 6 %@ %@ ORDER BY invTypes.typeName";
			fittingItemsViewController.title = @"Ships";
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
				[popoverController presentPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] inView:tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
			else
				[self presentModalViewController:modalController animated:YES];
		}
		else if (indexPath.row == 2) {
			fittingItemsViewController.groupsRequest = @"SELECT * FROM invGroups WHERE groupID = 365 ORDER BY groupName;";
			fittingItemsViewController.group = [EVEDBInvGroup invGroupWithGroupID:365 error:nil];
			fittingItemsViewController.typesRequest = @"SELECT invMetaGroups.metaGroupID, invMetaGroups.metaGroupName, invTypes.* FROM invTypes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND groupID = 365 %@ %@ ORDER BY invTypes.typeName";
			fittingItemsViewController.title = @"Ships";
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
				[popoverController presentPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] inView:tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
			else
				[self presentModalViewController:modalController animated:YES];
		}
	}
	else {
		NSDictionary *row = [[fits objectAtIndex:indexPath.section - 1] objectAtIndex:indexPath.row];
		if ([[row valueForKey:@"isPOS"] boolValue]) {
			POSFittingViewController *posFittingViewController = [[POSFittingViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"POSFittingViewController-iPad" : @"POSFittingViewController")
																											bundle:nil];
			__block EUSingleBlockOperation* operation = [EUSingleBlockOperation operationWithIdentifier:@"FittingServiceMenuViewController+Select"];
			__block POSFit* fit = nil;
			[operation addExecutionBlock:^{
				NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
				fit = [[POSFit posFitWithDictionary:row engine:posFittingViewController.fittingEngine] retain];
				[pool release];
			}];
			
			[operation setCompletionBlockInCurrentThread:^{
				if (![operation isCancelled]) {
					posFittingViewController.fit = fit;
					[self.navigationController pushViewController:posFittingViewController animated:YES];
				}
				[posFittingViewController release];
				[fit release];
			}];
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
		else {
			FittingViewController *fittingViewController = [[FittingViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"FittingViewController-iPad" : @"FittingViewController")
																								   bundle:nil];
			__block EUSingleBlockOperation* operation = [EUSingleBlockOperation operationWithIdentifier:@"FittingServiceMenuViewController+Select"];
			__block Fit* fit = nil;
			__block boost::shared_ptr<eufe::Character> *character = NULL;
			[operation addExecutionBlock:^{
				NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
				character = new boost::shared_ptr<eufe::Character>(new eufe::Character(fittingViewController.fittingEngine));
				
				EVEAccount* currentAccount = [EVEAccount currentAccount];
				if (currentAccount && currentAccount.charKeyID && currentAccount.charVCode && currentAccount.characterID) {
					CharacterEVE* eveCharacter = [CharacterEVE characterWithCharacterID:currentAccount.characterID keyID:currentAccount.charKeyID vCode:currentAccount.charVCode name:currentAccount.characterName];
					(*character)->setCharacterName([eveCharacter.name cStringUsingEncoding:NSUTF8StringEncoding]);
					(*character)->setSkillLevels(*[eveCharacter skillsMap]);
				}
				else
					(*character)->setCharacterName("All Skills 0");
				
				fit = [[Fit fitWithDictionary:row character:*character] retain];
				[pool release];
			}];
			
			[operation setCompletionBlockInCurrentThread:^{
				if (![operation isCancelled]) {
					fittingViewController.fittingEngine->getGang()->addPilot(*character);
					fittingViewController.fit = fit;
					[fittingViewController.fits addObject:fit];
					[self.navigationController pushViewController:fittingViewController animated:YES];
				}
				[fittingViewController release];
				[fit release];
				delete character;
			}];
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
	}
	return;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0)
		return UITableViewCellEditingStyleNone;
	else
		return UITableViewCellEditingStyleDelete;
}

#pragma mark FittingItemsViewControllerDelegate

- (void) fittingItemsViewController:(FittingItemsViewController*) controller didSelectType:(EVEDBInvType*) type {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[popoverController dismissPopoverAnimated:YES];
	else
		[self dismissModalViewControllerAnimated:YES];

	if (type.groupID == eufe::CONTROL_TOWER_GROUP_ID) {
		POSFittingViewController *posFittingViewController = [[POSFittingViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"POSFittingViewController-iPad" : @"POSFittingViewController")
																										bundle:nil];
		__block EUSingleBlockOperation* operation = [EUSingleBlockOperation operationWithIdentifier:@"FittingServiceMenuViewController+Select"];
		__block POSFit* posFit = nil;
		__block boost::shared_ptr<eufe::ControlTower> *controlTower = NULL;
		[operation addExecutionBlock:^{
			NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
			controlTower = new boost::shared_ptr<eufe::ControlTower>(new eufe::ControlTower(posFittingViewController.fittingEngine, type.typeID));

			posFit = [[POSFit posFitWithFitID:-1 fitName:type.typeName controlTower:*controlTower] retain];
			[pool release];
		}];
		
		[operation setCompletionBlockInCurrentThread:^{
			if (![operation isCancelled]) {
				[posFit save];
				posFittingViewController.fittingEngine->setControlTower(*controlTower);
				posFittingViewController.fit = posFit;
				[self.navigationController pushViewController:posFittingViewController animated:YES];
			}
			[posFittingViewController release];
			[posFit release];
			delete controlTower;
		}];
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
	else {
		FittingViewController *fittingViewController = [[FittingViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"FittingViewController-iPad" : @"FittingViewController")
																							   bundle:nil];
		__block EUSingleBlockOperation* operation = [EUSingleBlockOperation operationWithIdentifier:@"FittingServiceMenuViewController+Select"];
		__block Fit* fit = nil;
		__block boost::shared_ptr<eufe::Character> *character = NULL;
		[operation addExecutionBlock:^{
			NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
			character = new boost::shared_ptr<eufe::Character>(new eufe::Character(fittingViewController.fittingEngine));
			(*character)->setShip(type.typeID);
			
			EVEAccount* currentAccount = [EVEAccount currentAccount];
			if (currentAccount && currentAccount.charKeyID && currentAccount.charVCode && currentAccount.characterID) {
				CharacterEVE* eveCharacter = [CharacterEVE characterWithCharacterID:currentAccount.characterID keyID:currentAccount.charKeyID vCode:currentAccount.charVCode name:currentAccount.characterName];
				(*character)->setCharacterName([eveCharacter.name cStringUsingEncoding:NSUTF8StringEncoding]);
				(*character)->setSkillLevels(*[eveCharacter skillsMap]);
			}
			else
				(*character)->setCharacterName("All Skills 0");
			fit = [[Fit fitWithFitID:-1 fitName:type.typeName character:*character] retain];
			[pool release];
		}];
		
		[operation setCompletionBlockInCurrentThread:^{
			if (![operation isCancelled]) {
				[fit save];
				fittingViewController.fittingEngine->getGang()->addPilot(*character);
				fittingViewController.fit = fit;
				[fittingViewController.fits addObject:fit];
				[self.navigationController pushViewController:fittingViewController animated:YES];
			}
			[fittingViewController release];
			[fit release];
			delete character;
		}];
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
}
	
@end
