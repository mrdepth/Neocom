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
#import "UITableViewCell+Nib.h"
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
#import "FittingExportViewController.h"
#import "NSString+UUID.h"
#import "UIActionSheet+Block.h"

@interface FittingServiceMenuViewController(Private)
- (void) convertFits;
- (void) save;
- (void) exportFits;
@end

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
	self.title = NSLocalizedString(@"Fitting", nil);
	[self.navigationItem setRightBarButtonItem:self.editButtonItem];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.popoverController = [[[UIPopoverController alloc] initWithContentViewController:modalController] autorelease];
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
	
	__block EUOperation* operation = [EUOperation operationWithIdentifier:@"FittingServiceMenuViewController+Load" name:NSLocalizedString(@"Loading Fits", nil)];
	__block BOOL needsConvertTmp = NO;
	
	NSMutableArray* fitsTmp = [NSMutableArray array];
	[operation addExecutionBlock:^{
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		NSMutableArray *fitsArray = [NSMutableArray arrayWithContentsOfURL:[NSURL fileURLWithPath:[Globals fitsFilePath]]];
		
		BOOL needsSave = NO;
		float n = fitsArray.count;
		float i = 0;
		for (NSMutableDictionary* row in fitsArray) {
			operation.progress = i++ / n / 2;
			EVEDBInvType* type;
			NSObject* fitID = [row valueForKey:@"fitID"];
			if ([fitID isKindOfClass:[NSNumber class]]) {
				fitID = [NSString uuidString];
				[row setValue:fitID forKey:@"fitID"];
				needsSave = YES;
			}
			
			if (![row valueForKey:@"isPOS"])
				[row setValue:[NSNumber numberWithBool:NO] forKey:@"isPOS"];
			if ([[row valueForKey:@"isPOS"] boolValue])
				type = [EVEDBInvType invTypeWithTypeID:[[row valueForKeyPath:@"fit.controlTowerID"] integerValue] error:nil];
			else {
				type = [EVEDBInvType invTypeWithTypeID:[[row valueForKeyPath:@"fit.shipID"] integerValue] error:nil];
				if ([row valueForKeyPath:@"fit.modules"])
					needsConvertTmp = YES;
			}
			if (type) {
				[row setValue:type forKey:@"type"];
				[row setValue:[type typeSmallImageName] forKey:@"imageName"];
			}
		}
		
		if (needsSave) {
			NSMutableArray* allFits = [NSMutableArray array];
			for (NSDictionary* row in fitsArray) {
				NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithDictionary:row];
				[dictionary setValue:nil forKey:@"type"];
				[allFits addObject:dictionary];
			}
			[allFits writeToURL:[NSURL fileURLWithPath:[Globals fitsFilePath]] atomically:YES];
		}
		
		[fitsArray sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"shipName" ascending:YES]]];
		operation.progress = 0.75;
		
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
		operation.progress = 1.0;
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^{
		if (![operation isCancelled]) {
			needsConvert = needsConvertTmp;
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
	return section == 0 ? 4 : [[fits objectAtIndex:section - 1] count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
		NSString *cellIdentifier = @"MainMenuCellView";
		
		MainMenuCellView *cell = (MainMenuCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [MainMenuCellView cellWithNibName:@"MainMenuCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		if (indexPath.row == 0) {
			cell.titleLabel.text = NSLocalizedString(@"Browse Fits on BattleClinic", nil);
			cell.iconImageView.image = [UIImage imageNamed:@"battleclinic.png"];
		}
		else if (indexPath.row == 1) {
			cell.titleLabel.text = NSLocalizedString(@"New Ship Fit", nil);
			cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon17_04.png"];
		}
		else if (indexPath.row == 2) {
			cell.titleLabel.text = NSLocalizedString(@"New POS Fit", nil);
			cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon07_06.png"];
		}
		else {
			cell.titleLabel.text = NSLocalizedString(@"Export", nil);
			cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon94_03.png"];
		}
		return cell;
	}
	else {
		NSString *cellIdentifier = @"FitCellView";
		
		FitCellView *cell = (FitCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [FitCellView cellWithNibName:@"FitCellView" bundle:nil reuseIdentifier:cellIdentifier];
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
		return NSLocalizedString(@"Menu", nil);
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
		[self save];
	}
}

#pragma mark -
#pragma mark Table view delegate

- (BOOL) tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section > 0;
}

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
			BCSearchViewController *controller = [[BCSearchViewController alloc] initWithNibName:@"BCSearchViewController" bundle:nil];
			[self.navigationController pushViewController:controller animated:YES];
			[controller release];
		}
		else if (indexPath.row == 1) {
			fittingItemsViewController.groupsRequest = @"SELECT * FROM invGroups WHERE categoryID = 6 ORDER BY groupName;";
			fittingItemsViewController.typesRequest = @"SELECT invMetaGroups.metaGroupID, invMetaGroups.metaGroupName, invTypes.* FROM invTypes, invGroups LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND invTypes.groupID = invGroups.groupID and invGroups.categoryID = 6 %@ %@ ORDER BY invTypes.typeName";
			fittingItemsViewController.title = NSLocalizedString(@"Ships", nil);
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
				[popoverController presentPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] inView:tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
			else
				[self presentModalViewController:modalController animated:YES];
		}
		else if (indexPath.row == 2) {
			fittingItemsViewController.groupsRequest = @"SELECT * FROM invGroups WHERE groupID = 365 ORDER BY groupName;";
			fittingItemsViewController.group = [EVEDBInvGroup invGroupWithGroupID:365 error:nil];
			fittingItemsViewController.typesRequest = @"SELECT invMetaGroups.metaGroupID, invMetaGroups.metaGroupName, invTypes.* FROM invTypes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND groupID = 365 %@ %@ ORDER BY invTypes.typeName";
			fittingItemsViewController.title = NSLocalizedString(@"Ships", nil);
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
				[popoverController presentPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] inView:tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
			else
				[self presentModalViewController:modalController animated:YES];
		}
		else {
			if (needsConvert) {
				UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Export", nil)
																	message:NSLocalizedString(@"To continue, Neocom must convert the loadouts database to its new format. This may take a few minutes.", nil)
																   delegate:self
														  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
														  otherButtonTitles:NSLocalizedString(@"Convert", nil), nil];
				[alertView show];
				[alertView release];
			}
			else {
				[self exportFits];
			}
		}
	}
	else {
		NSDictionary *row = [[fits objectAtIndex:indexPath.section - 1] objectAtIndex:indexPath.row];
		if ([[row valueForKey:@"isPOS"] boolValue]) {
			POSFittingViewController *posFittingViewController = [[POSFittingViewController alloc] initWithNibName:@"POSFittingViewController" bundle:nil];
			__block EUOperation* operation = [EUOperation operationWithIdentifier:@"FittingServiceMenuViewController+Select" name:NSLocalizedString(@"Loading POS Fit", nil)];
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
			FittingViewController *fittingViewController = [[FittingViewController alloc] initWithNibName:@"FittingViewController" bundle:nil];
			__block EUOperation* operation = [EUOperation operationWithIdentifier:@"FittingServiceMenuViewController+Select" name:NSLocalizedString(@"Loading Ship Fit", nil)];
			__block Fit* fit = nil;
			__block eufe::Character* character = NULL;
			[operation addExecutionBlock:^{
				NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
				character = new eufe::Character(fittingViewController.fittingEngine);
				
				EVEAccount* currentAccount = [EVEAccount currentAccount];
				if (currentAccount && currentAccount.charKeyID && currentAccount.charVCode && currentAccount.characterID) {
					CharacterEVE* eveCharacter = [CharacterEVE characterWithCharacterID:currentAccount.characterID keyID:currentAccount.charKeyID vCode:currentAccount.charVCode name:currentAccount.characterName];
					character->setCharacterName([eveCharacter.name cStringUsingEncoding:NSUTF8StringEncoding]);
					character->setSkillLevels(*[eveCharacter skillsMap]);
				}
				else
					character->setCharacterName("All Skills 0");
				
				operation.progress = 0.5;
				fit = [[Fit fitWithDictionary:row character:character] retain];
				operation.progress = 1.0;
				[pool release];
			}];
			
			[operation setCompletionBlockInCurrentThread:^{
				if (![operation isCancelled]) {
					fittingViewController.fittingEngine->getGang()->addPilot(character);
					fittingViewController.fit = fit;
					[fittingViewController.fits addObject:fit];
					[self.navigationController pushViewController:fittingViewController animated:YES];
				}
				else {
					if (character)
						delete character;
				}
				[fittingViewController release];
				[fit release];
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
		POSFittingViewController *posFittingViewController = [[POSFittingViewController alloc] initWithNibName:@"POSFittingViewController" bundle:nil];
		__block EUOperation* operation = [EUOperation operationWithIdentifier:@"FittingServiceMenuViewController+Select" name:NSLocalizedString(@"Creating Pos Fit", nil)];
		__block POSFit* posFit = nil;
		__block eufe::ControlTower* controlTower = NULL;
		[operation addExecutionBlock:^{
			NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
			controlTower = new eufe::ControlTower(posFittingViewController.fittingEngine, type.typeID);

			operation.progress = 0.5;
			posFit = [[POSFit posFitWithFitID:nil fitName:type.typeName controlTower:controlTower] retain];
			operation.progress = 1.0;
			[pool release];
		}];
		
		[operation setCompletionBlockInCurrentThread:^{
			if (![operation isCancelled]) {
				[posFit save];
				posFittingViewController.fittingEngine->setControlTower(controlTower);
				posFittingViewController.fit = posFit;
				[self.navigationController pushViewController:posFittingViewController animated:YES];
			}
			else {
				if (controlTower)
					delete controlTower;
			}
			[posFittingViewController release];
			[posFit release];
		}];
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
	else {
		FittingViewController *fittingViewController = [[FittingViewController alloc] initWithNibName:@"FittingViewController" bundle:nil];
		__block EUOperation* operation = [EUOperation operationWithIdentifier:@"FittingServiceMenuViewController+Select" name:NSLocalizedString(@"Creating Pos Fit", nil)];
		__block Fit* fit = nil;
		__block eufe::Character* character = NULL;
		[operation addExecutionBlock:^{
			NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
			character = new eufe::Character(fittingViewController.fittingEngine);
			character->setShip(type.typeID);
			
			EVEAccount* currentAccount = [EVEAccount currentAccount];
			if (currentAccount && currentAccount.charKeyID && currentAccount.charVCode && currentAccount.characterID) {
				CharacterEVE* eveCharacter = [CharacterEVE characterWithCharacterID:currentAccount.characterID keyID:currentAccount.charKeyID vCode:currentAccount.charVCode name:currentAccount.characterName];
				character->setCharacterName([eveCharacter.name cStringUsingEncoding:NSUTF8StringEncoding]);
				character->setSkillLevels(*[eveCharacter skillsMap]);
			}
			else
				character->setCharacterName("All Skills 0");

			operation.progress = 0.5;
			fit = [[Fit fitWithFitID:nil fitName:type.typeName character:character] retain];
			operation.progress = 1.0;
			[pool release];
		}];
		
		[operation setCompletionBlockInCurrentThread:^{
			if (![operation isCancelled]) {
				[fit save];
				fittingViewController.fittingEngine->getGang()->addPilot(character);
				fittingViewController.fit = fit;
				[fittingViewController.fits addObject:fit];
				[self.navigationController pushViewController:fittingViewController animated:YES];
			}
			else {
				if (character)
					delete character;
			}
			[fittingViewController release];
			[fit release];
		}];
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex != alertView.cancelButtonIndex)
		[self convertFits];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
	[self dismissModalViewControllerAnimated:YES];
}
	
@end

@implementation FittingServiceMenuViewController(Private)

- (void) convertFits {
	__block EUOperation* operation = [EUOperation operationWithIdentifier:@"FittingServiceMenuViewController+Convert" name:NSLocalizedString(@"Converting Fits", nil)];
	NSMutableArray* fitsTmp = [NSMutableArray array];
	for (NSArray* group in fits)
		[fitsTmp addObject:[NSMutableArray arrayWithArray:group]];
	[operation addExecutionBlock:^{
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		
		eufe::Engine* fittingEngine = new eufe::Engine([[[NSBundle mainBundle] pathForResource:@"eufe" ofType:@"sqlite"] cStringUsingEncoding:NSUTF8StringEncoding]);
		eufe::Character* character = new eufe::Character(fittingEngine);

		float count = fitsTmp.count;
		float j = 0;
		for (NSMutableArray* group in fitsTmp) {
			operation.progress = j++ / count;
			int n = group.count;
			for (int i = 0; i < n; i++) {
				NSDictionary* row = [group objectAtIndex:i];
				if ([[row valueForKey:@"isPOS"] boolValue])
					break;
				
				Fit* fit = [[Fit alloc] initWithDictionary:row character:character];
				row = [fit dictionary];
				[group replaceObjectAtIndex:i withObject:row];
				[fit release];
			}
		}

		delete character;
		delete fittingEngine;
	
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^{
		if (![operation isCancelled]) {
			needsConvert = NO;
			[fits release];
			fits = [fitsTmp retain];
			
			NSMutableArray* allFits = [NSMutableArray array];
			for (NSArray* rows in fits) {
				for (NSDictionary* row in rows) {
					NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithDictionary:row];
					[dictionary setValue:nil forKey:@"type"];
					[allFits addObject:dictionary];
				}
			}
			
			[allFits writeToURL:[NSURL fileURLWithPath:[Globals fitsFilePath]] atomically:YES];

			
			FittingExportViewController *fittingExportViewController = [[FittingExportViewController alloc] initWithNibName:@"FittingExportViewController" bundle:nil];
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:fittingExportViewController];
			navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
			
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
				navController.modalPresentationStyle = UIModalPresentationFormSheet;
			
			[self presentModalViewController:navController animated:YES];
			[navController release];
			[fittingExportViewController release];
		}
	}];
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) save {
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

- (void) exportFits {
	NSMutableArray* buttons = [NSMutableArray arrayWithObjects:NSLocalizedString(@"Browser", nil), NSLocalizedString(@"Clipboard", nil), nil];
	if ([MFMailComposeViewController canSendMail])
		[buttons addObject:NSLocalizedString(@"Email", nil)];
	[[UIActionSheet actionSheetWithTitle:NSLocalizedString(@"Export", nil)
					   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
				  destructiveButtonTitle:nil
					   otherButtonTitles:buttons
						 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
							 if (selectedButtonIndex == actionSheet.cancelButtonIndex)
								 return;
							 
							 if (selectedButtonIndex == 0) {
								 FittingExportViewController *fittingExportViewController = [[FittingExportViewController alloc] initWithNibName:@"FittingExportViewController" bundle:nil];
								 UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:fittingExportViewController];
								 navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
								 
								 if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
									 navController.modalPresentationStyle = UIModalPresentationFormSheet;
								 
								 [self presentModalViewController:navController animated:YES];
								 [navController release];
								 [fittingExportViewController release];
							 }
							 else if (selectedButtonIndex == 1) {
								 NSString* xml = [Fit allFitsEveXML];
								 [[UIPasteboard generalPasteboard] setString:xml];
							 }
							 else if (selectedButtonIndex == 2) {
								 NSString* xml = [Fit allFitsEveXML];
								 MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
								 controller.mailComposeDelegate = self;
								 [controller setSubject:NSLocalizedString(@"Neocom fits", nil)];
								 [controller addAttachmentData:[xml dataUsingEncoding:NSUTF8StringEncoding] mimeType:@"application/xml" fileName:@"fits.xml"];
								 [self presentModalViewController:controller animated:YES];
								 [controller release];
								 
							 }
						 }
							 cancelBlock:nil] showFromRect:[self.menuTableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]] inView:self.menuTableView animated:YES];
	
}

@end
