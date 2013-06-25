//
//  FitsViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 12/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "FitsViewController.h"
#import "MainMenuCellView.h"
#import "FitCellView.h"
#import "UITableViewCell+Nib.h"
#import "Globals.h"
#import "FittingViewController.h"
#import "EVEDBAPI.h"
#import "BCSearchViewController.h"
#import "ShipFit.h"
#import "EUOperationQueue.h"
#import "EVEAccount.h"
#import "CharacterEVE.h"
#import "NSArray+GroupBy.h"
#import "EUStorage.h"

@interface FitsViewController()
@property(nonatomic, strong) NSMutableArray *fits;


@end

@implementation FitsViewController
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
	self.title = NSLocalizedString(@"Fitting", nil);
	[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onClose:)]];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.popoverController = [[UIPopoverController alloc] initWithContentViewController:self.modalController];
		self.popoverController.delegate = (FittingItemsViewController*)  self.modalController.topViewController;
	}
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	__block EUOperation* operation = [EUOperation operationWithIdentifier:@"FitsViewController+Load" name:NSLocalizedString(@"Loading Fits", nil)];
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
	
	[operation setCompletionBlockInCurrentThread:^{
		if (![weakOperation isCancelled]) {
			self.fits = fitsTmp;
			[self.menuTableView reloadData];
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
	self.fits = nil;
}

- (IBAction) didCloseModalViewController:(id) sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction) onClose:(id) sender {
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return [self.fits count] + 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return section == 0 ? 1 : [[self.fits objectAtIndex:section - 1] count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
		NSString *cellIdentifier = @"MainMenuCellView";
		
		MainMenuCellView *cell = (MainMenuCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [MainMenuCellView cellWithNibName:@"MainMenuCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		cell.titleLabel.text = NSLocalizedString(@"New Ship Fit", nil);
		cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon17_04.png"];
		return cell;
	}
	else {
		NSString *cellIdentifier = @"FitCellView";
		
		FitCellView *cell = (FitCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [FitCellView cellWithNibName:@"FitCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		Fit* fit = [[self.fits objectAtIndex:indexPath.section - 1] objectAtIndex:indexPath.row];
		cell.shipNameLabel.text = fit.typeName;
		cell.fitNameLabel.text = fit.fitName;
		cell.iconView.image = [UIImage imageNamed:fit.imageName];
		return cell;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return NSLocalizedString(@"Menu", nil);
	else {
		NSArray* rows = [self.fits objectAtIndex:section - 1];
		if (rows.count > 0)
			return [[rows objectAtIndex:0] valueForKeyPath:@"type.group.groupName"];
		else
			return @"";
	}
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)];
	header.opaque = NO;
	header.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9];
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 300, 22)];
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
		//fittingItemsViewController.groupsRequest = @"SELECT * FROM invGroups WHERE groupID IN (25,26,27,28,30,31,324,358,380,419,420,463,485,513,540,541,543,547,659,830,831,832,833,834,883,893,894,898,900,902,906,941,963,1022) ORDER BY groupName;";
		//fittingItemsViewController.typesRequest = @"SELECT * FROM invTypes WHERE published=1 AND groupID IN (25,26,27,28,30,31,324,358,380,419,420,463,485,513,540,541,543,547,659,830,831,832,833,834,883,893,894,898,900,902,906,941,963,1022) %@ %@ ORDER BY invTypes.typeName;";
		//fittingItemsViewController.typesRequest = @"SELECT invMetaGroups.metaGroupID, invMetaGroups.metaGroupName, invTypes.* FROM invTypes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND groupID IN (25,26,27,28,30,31,324,358,380,419,420,463,485,513,540,541,543,547,659,830,831,832,833,834,883,893,894,898,900,902,906,941,963,1022) %@ %@ ORDER BY invTypes.typeName";
		self.fittingItemsViewController.marketGroupID = 4;
		self.fittingItemsViewController.title = NSLocalizedString(@"Ships", nil);
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[self.popoverController presentPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] inView:tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else
			[self presentModalViewController:self.modalController animated:YES];
	}
	else {
		__block EUOperation* operation = [EUOperation operationWithIdentifier:@"FittingServiceMenuViewController+Select" name:NSLocalizedString(@"Loading Ship Fit", nil)];
		__weak EUOperation* weakOperation = operation;
		__block ShipFit* fit = [[self.fits objectAtIndex:indexPath.section - 1] objectAtIndex:indexPath.row];
		__block eufe::Character* character = NULL;
		[operation addExecutionBlock:^{
			@autoreleasepool {
				character = new eufe::Character(self.engine);
				
				EVEAccount* currentAccount = [EVEAccount currentAccount];
				if (currentAccount && currentAccount.charKeyID && currentAccount.charVCode && currentAccount.characterID) {
					CharacterEVE* eveCharacter = [CharacterEVE characterWithCharacterID:currentAccount.characterID keyID:currentAccount.charKeyID vCode:currentAccount.charVCode name:currentAccount.characterName];
					character->setCharacterName([eveCharacter.name cStringUsingEncoding:NSUTF8StringEncoding]);
					character->setSkillLevels(*[eveCharacter skillsMap]);
				}
				else
					character->setCharacterName([NSLocalizedString(@"All Skills 0", nil) cStringUsingEncoding:NSUTF8StringEncoding]);
				
				weakOperation.progress = 0.5;
				
				fit.character = character;
				[fit load];
				
				weakOperation.progress = 1.0;
			}
		}];
		
		[operation setCompletionBlockInCurrentThread:^{
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
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[popoverController dismissPopoverAnimated:YES];
	
	__block EUOperation* operation = [EUOperation operationWithIdentifier:@"FittingServiceMenuViewController+Select" name:NSLocalizedString(@"Creating Ship Fit", nil)];
	__weak EUOperation* weakOperation = operation;
	__block ShipFit* fit = nil;
	__block eufe::Character* character = NULL;
	[operation addExecutionBlock:^{
		character = new eufe::Character(self.engine);
		character->setShip(type.typeID);

		EVEAccount* currentAccount = [EVEAccount currentAccount];
		if (currentAccount && currentAccount.charKeyID && currentAccount.charVCode && currentAccount.characterID) {
			CharacterEVE* eveCharacter = [CharacterEVE characterWithCharacterID:currentAccount.characterID keyID:currentAccount.charKeyID vCode:currentAccount.charVCode name:currentAccount.characterName];
			character->setCharacterName([eveCharacter.name cStringUsingEncoding:NSUTF8StringEncoding]);
			character->setSkillLevels(*[eveCharacter skillsMap]);
		}
		else
			character->setCharacterName([NSLocalizedString(@"All Skills 0", nil) cStringUsingEncoding:NSUTF8StringEncoding]);

		weakOperation.progress = 0.5;
		fit = [ShipFit shipFitWithFitName:type.typeName character:character];
		weakOperation.progress = 1.0;
	}];
	
	[operation setCompletionBlockInCurrentThread:^{
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

@end
