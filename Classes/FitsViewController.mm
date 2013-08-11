//
//  FitsViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 12/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "FitsViewController.h"
#import "MainMenuCellView.h"
#import "GroupedCell.h"
#import "Globals.h"
#import "FittingViewController.h"
#import "EVEDBAPI.h"
#import "BCSearchViewController.h"
#import "ShipFit.h"
#import "EUOperationQueue.h"
#import "EVEAccount.h"
#import "FitCharacter.h"
#import "NSArray+GroupBy.h"
#import "EUStorage.h"
#import "appearance.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"
#import "NCItemsViewController.h"

@interface FitsViewController()
@property(nonatomic, strong) NSMutableArray *fits;

- (void) reload;
@end

@implementation FitsViewController


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
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];

	self.title = NSLocalizedString(@"Fitting", nil);
	[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)]];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self reload];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return [self.fits count] + 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return section == 0 ? 1 : [self.fits[section - 1] count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"Cell";
	
	GroupedCell* cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];//[ItemCellView cellWithNibName:@"ItemCellView" bundle:nil reuseIdentifier:cellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	if (indexPath.section == 0) {
		cell.textLabel.text = NSLocalizedString(@"New Ship Fit", nil);
		cell.imageView.image = [UIImage imageNamed:@"Icons/icon17_04.png"];
	}
	else {
		Fit* fit = self.fits[indexPath.section - 1][indexPath.row];
		cell.textLabel.text = fit.typeName;
		cell.detailTextLabel.text = fit.fitName;
		cell.imageView.image = [UIImage imageNamed:fit.imageName];
	}
	
	int groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = static_cast<GroupedCellGroupStyle>(groupStyle);
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return nil;
	else {
		NSArray* rows = [self.fits objectAtIndex:section - 1];
		if (rows.count > 0)
			return [rows[0] valueForKeyPath:@"type.group.groupName"];
		else
			return nil;
	}
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	if (title) {
		CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
		view.titleLabel.text = title;
		return view;
	}
	else
		return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return [self tableView:tableView titleForHeaderInSection:section] ? 22 : 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.section == 0) {
		NCItemsViewController* controller = [[NCItemsViewController alloc] init];
		controller.conditions = @[@"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 6"];
		controller.title = NSLocalizedString(@"Ships", nil);
		[self presentViewController:controller animated:YES completion:nil];
	}
	else {
		EUOperation* operation = [EUOperation operationWithIdentifier:@"FleetViewController+Select" name:NSLocalizedString(@"Loading Ship Fit", nil)];
		__weak EUOperation* weakOperation = operation;
		__block ShipFit* fit = [[self.fits objectAtIndex:indexPath.section - 1] objectAtIndex:indexPath.row];
		__block eufe::Character* character = NULL;
		[operation addExecutionBlock:^{
			@autoreleasepool {
				character = new eufe::Character(self.engine);
				
				EVEAccount* currentAccount = [EVEAccount currentAccount];
				if (currentAccount.characterSheet) {
					FitCharacter* fitCharacter = [FitCharacter fitCharacterWithAccount:currentAccount];
					character->setCharacterName([fitCharacter.name cStringUsingEncoding:NSUTF8StringEncoding]);
					character->setSkillLevels(*[fitCharacter skillsMap]);
				}
				else
					character->setCharacterName([NSLocalizedString(@"All Skills 0", nil) UTF8String]);
				
				weakOperation.progress = 0.5;
				
				fit.character = character;
				[fit load];
				
				weakOperation.progress = 1.0;
			}
		}];
		
		[operation setCompletionBlockInMainThread:^{
			if (![weakOperation isCancelled]) {
				[fit save];
				[self.delegate fitsViewController:self didSelectFit:fit];
			}
			else {
				if (character)
					delete character;
			}
		}];
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
	return;
}

#pragma mark FittingItemsViewControllerDelegate

- (void) fittingItemsViewController:(FittingItemsViewController*) controller didSelectType:(EVEDBInvType*) type {
	EUOperation* operation = [EUOperation operationWithIdentifier:@"FittingServiceMenuViewController+Select" name:NSLocalizedString(@"Creating Ship Fit", nil)];
	__weak EUOperation* weakOperation = operation;
	__block ShipFit* fit = nil;
	__block eufe::Character* character = NULL;
	[operation addExecutionBlock:^{
		character = new eufe::Character(self.engine);
		character->setShip(type.typeID);

		EVEAccount* currentAccount = [EVEAccount currentAccount];
		if (currentAccount.characterSheet) {
			FitCharacter* fitCharacter = [FitCharacter fitCharacterWithAccount:currentAccount];
			character->setCharacterName([fitCharacter.name cStringUsingEncoding:NSUTF8StringEncoding]);
			character->setSkillLevels(*[fitCharacter skillsMap]);
		}
		else
			character->setCharacterName([NSLocalizedString(@"All Skills 0", nil) UTF8String]);

		weakOperation.progress = 0.5;
		fit = [ShipFit shipFitWithFitName:type.typeName character:character];
		weakOperation.progress = 1.0;
	}];
	
	[operation setCompletionBlockInMainThread:^{
		if (![weakOperation isCancelled]) {
			[fit save];
			[self.delegate fitsViewController:self didSelectFit:fit];
		}
		else {
			if (!character)
				delete character;
		}
	}];
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

#pragma mark - Private

- (void) reload {
	EUOperation* operation = [EUOperation operationWithIdentifier:@"FitsViewController+reload" name:NSLocalizedString(@"Loading Fits", nil)];
	__weak EUOperation* weakOperation = operation;
	NSMutableArray* fitsTmp = [NSMutableArray array];
	[operation addExecutionBlock:^{
		@autoreleasepool {
			EUStorage* storage = [EUStorage sharedStorage];
			[storage.managedObjectContext performBlockAndWait:^{
				NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
				NSEntityDescription *entity = [NSEntityDescription entityForName:@"ShipFit" inManagedObjectContext:storage.managedObjectContext];
				[fetchRequest setEntity:entity];
				
				NSError *error = nil;
				NSArray *fetchedObjects = [storage.managedObjectContext executeFetchRequest:fetchRequest error:&error];
				
				weakOperation.progress = 0.5;
				
				[fitsTmp addObjectsFromArray:[fetchedObjects arrayGroupedByKey:@"type.groupID"]];
				weakOperation.progress = 0.75;
				[fitsTmp sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
					Fit* a = [obj1 objectAtIndex:0];
					Fit* b = [obj2 objectAtIndex:0];
					return [a.type.group.groupName compare:b.type.group.groupName];
				}];
				weakOperation.progress = 1.0;
			}];
		}
		
	}];
	
	[operation setCompletionBlockInMainThread:^{
		if (![weakOperation isCancelled]) {
			self.fits = fitsTmp;
			[self.tableView reloadData];
		}
	}];
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end
