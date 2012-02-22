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
#import "NibTableViewCell.h"
#import "Globals.h"
#import "FittingViewController.h"
#import "EVEDBAPI.h"
#import "BCSearchViewController.h"
#import "Fit.h"
#import "EUOperationQueue.h"
#import "EVEAccount.h"
#import "CharacterEVE.h"


@implementation FitsViewController
@synthesize menuTableView;
@synthesize fittingItemsViewController;
@synthesize modalController;
@synthesize popoverController;
@synthesize delegate;
@synthesize engine;


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
	[self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(onClose:)] autorelease]];
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
	[fits release];
	NSArray *fitsArray = [NSArray arrayWithContentsOfURL:[NSURL fileURLWithPath:[Globals fitsFilePath]]];
	lastID = [[[fitsArray lastObject] valueForKey:@"fitID"] integerValue];
	fits = [[NSMutableArray arrayWithArray:[fitsArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"shipName" ascending:YES]]]] retain];
	[menuTableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
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
	return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return section == 0 ? 1 : fits.count;
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
		cell.titleLabel.text = @"New Fit";
		cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon17_04.png"];
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
		NSDictionary *fit = [fits objectAtIndex:indexPath.row];
		cell.shipNameLabel.text = [fit valueForKey:@"shipName"];
		cell.fitNameLabel.text = [fit valueForKey:@"fitName"];
		cell.iconView.image = [UIImage imageNamed:[fit valueForKey:@"imageName"]];
		return cell;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return @"Menu";
	else
		return @"My Fits";
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
		fittingItemsViewController.groupsRequest = @"SELECT * FROM invGroups WHERE groupID IN (25,26,27,28,30,31,324,358,380,419,420,463,485,513,540,541,543,547,659,830,831,832,833,834,883,893,894,898,900,902,906,941,963,1022) ORDER BY groupName;";
		//fittingItemsViewController.typesRequest = @"SELECT * FROM invTypes WHERE published=1 AND groupID IN (25,26,27,28,30,31,324,358,380,419,420,463,485,513,540,541,543,547,659,830,831,832,833,834,883,893,894,898,900,902,906,941,963,1022) %@ %@ ORDER BY invTypes.typeName;";
		fittingItemsViewController.typesRequest = @"SELECT invMetaGroups.metaGroupID, invMetaGroups.metaGroupName, invTypes.* FROM invTypes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND groupID IN (25,26,27,28,30,31,324,358,380,419,420,463,485,513,540,541,543,547,659,830,831,832,833,834,883,893,894,898,900,902,906,941,963,1022) %@ %@ ORDER BY invTypes.typeName";
		fittingItemsViewController.title = @"Ships";
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[popoverController presentPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] inView:tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else
			[self presentModalViewController:modalController animated:YES];
	}
	else {
		NSDictionary *row = [fits objectAtIndex:indexPath.row];
		__block EUSingleBlockOperation* operation = [EUSingleBlockOperation operationWithIdentifier:@"FittingServiceMenuViewController+Select"];
		__block Fit* fit = nil;
		__block boost::shared_ptr<eufe::Character> *character = NULL;
		[operation addExecutionBlock:^{
			NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
			character = new boost::shared_ptr<eufe::Character>(new eufe::Character(engine));

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
				[fit save];
				[delegate fitsViewController:self didSelectFit:[fit autorelease]];
			}
			delete character;
		}];
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
	return;
}

#pragma mark FittingItemsViewControllerDelegate

- (void) fittingItemsViewController:(FittingItemsViewController*) controller didSelectType:(EVEDBInvType*) type {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[popoverController dismissPopoverAnimated:YES];
	
	__block EUSingleBlockOperation* operation = [EUSingleBlockOperation operationWithIdentifier:@"FittingServiceMenuViewController+Select"];
	__block Fit* fit = nil;
	__block boost::shared_ptr<eufe::Character> *character = NULL;
	[operation addExecutionBlock:^{
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		character = new boost::shared_ptr<eufe::Character>(new eufe::Character(engine));
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
			[delegate fitsViewController:self didSelectFit:[fit autorelease]];
		}
		delete character;
	}];
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end
