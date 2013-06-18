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
#import "ShipFit.h"
#import "POSFit.h"
#import "EVEAccount.h"
#import "CharacterEVE.h"
#import "NSArray+GroupBy.h"
#import "FittingExportViewController.h"
#import "NSString+UUID.h"
#import "UIActionSheet+Block.h"
#import "EUStorage.h"
#import "NAPISearchViewController.h"

@interface FittingServiceMenuViewController()
@property (nonatomic, strong) NSMutableArray *fits;
@property (nonatomic, assign) BOOL needsConvert;

- (void) reload;
- (void) convertFits;
- (void) save;
- (void) exportFits;
- (void) didUpdateCloud:(NSNotification*) notification;
@end

@implementation FittingServiceMenuViewController
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
		self.popoverController = [[UIPopoverController alloc] initWithContentViewController:self.modalController];
		self.popoverController.delegate = (FittingItemsViewController*)  self.modalController.topViewController;
	}
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateCloud:) name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:nil];
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

- (void)viewDidUnload {
//	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:nil];
    [super viewDidUnload];
	self.menuTableView = nil;
	self.fittingItemsViewController = nil;
	self.modalController = nil;
	self.popoverController = nil;
	self.fits = nil;
}


- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	[self.menuTableView setEditing:editing animated:animated];
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
	return [self.fits count] + 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return section == 0 ? 5 : [[self.fits objectAtIndex:section - 1] count];
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
			cell.titleLabel.text = NSLocalizedString(@"Browse Neocom Community Fits", nil);
			cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon17_04.png"];
		}
		else if (indexPath.row == 2) {
			cell.titleLabel.text = NSLocalizedString(@"New Ship Fit", nil);
			cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon17_04.png"];
		}
		else if (indexPath.row == 3) {
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
		//NSDictionary *fit = [[fits objectAtIndex:indexPath.section - 1] objectAtIndex:indexPath.row];
		Fit* fit = [[self.fits objectAtIndex:indexPath.section - 1] objectAtIndex:indexPath.row];
		cell.shipNameLabel.text = fit.typeName;//[fit valueForKey:@"shipName"];
		cell.fitNameLabel.text = fit.fitName;//[fit valueForKey:@"fitName"];
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

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (UITableViewCellEditingStyleDelete) {
		NSMutableArray* rows = [self.fits objectAtIndex:indexPath.section - 1];
		Fit* fit = [rows objectAtIndex:indexPath.row];
		
		EUStorage* storage = [EUStorage sharedStorage];
		[storage.managedObjectContext deleteObject:fit];
		[storage saveContext];
		
		[rows removeObjectAtIndex:indexPath.row];

		if (rows.count == 0) {
			[self.fits removeObjectAtIndex:indexPath.section - 1];
			[self.menuTableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
		}
		else {
			[self.menuTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
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
		if (indexPath.row == 0) {
			BCSearchViewController *controller = [[BCSearchViewController alloc] initWithNibName:@"BCSearchViewController" bundle:nil];
			[self.navigationController pushViewController:controller animated:YES];
		}
		else if (indexPath.row == 1) {
			NAPISearchViewController *controller = [[NAPISearchViewController alloc] initWithNibName:@"NAPISearchViewController" bundle:nil];
			[self.navigationController pushViewController:controller animated:YES];
		}
		else if (indexPath.row == 2) {
			self.fittingItemsViewController.marketGroupID = 4;
			self.fittingItemsViewController.title = NSLocalizedString(@"Ships", nil);
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
				[self.popoverController presentPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] inView:tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
			else
				[self presentModalViewController:self.modalController animated:YES];

		}
		else if (indexPath.row == 3) {
			self.fittingItemsViewController.marketGroupID = 478;
			self.fittingItemsViewController.title = NSLocalizedString(@"Control Towers", nil);
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
				[self.popoverController presentPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] inView:tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
			else
				[self presentModalViewController:self.modalController animated:YES];
		}
		else {
			if (self.needsConvert) {
				UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Export", nil)
																	message:NSLocalizedString(@"To continue, Neocom must convert the loadouts database to its new format. This may take a few minutes.", nil)
																   delegate:self
														  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
														  otherButtonTitles:NSLocalizedString(@"Convert", nil), nil];
				[alertView show];
			}
			else {
				[self exportFits];
			}
		}
	}
	else {
		//NSDictionary *row = [[fits objectAtIndex:indexPath.section - 1] objectAtIndex:indexPath.row];
		Fit* fit = [[self.fits objectAtIndex:indexPath.section - 1] objectAtIndex:indexPath.row];

		if ([fit isKindOfClass:[POSFit class]]) {
			POSFittingViewController *posFittingViewController = [[POSFittingViewController alloc] initWithNibName:@"POSFittingViewController" bundle:nil];
			__block EUOperation* operation = [EUOperation operationWithIdentifier:@"FittingServiceMenuViewController+Select" name:NSLocalizedString(@"Loading POS Fit", nil)];
			__weak EUOperation* weakOperation = operation;
			__block POSFit* posFit = (POSFit*)(fit);
			[operation addExecutionBlock:^{
				posFit.controlTower = posFittingViewController.fittingEngine->setControlTower(posFit.typeID);
				[posFit load];
			}];
			
			[operation setCompletionBlockInCurrentThread:^{
				if (![weakOperation isCancelled]) {
					posFittingViewController.fit = posFit;
					[self.navigationController pushViewController:posFittingViewController animated:YES];
				}
			}];
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
		else {
			FittingViewController *fittingViewController = [[FittingViewController alloc] initWithNibName:@"FittingViewController" bundle:nil];
			__block EUOperation* operation = [EUOperation operationWithIdentifier:@"FittingServiceMenuViewController+Select" name:NSLocalizedString(@"Loading Ship Fit", nil)];
			__weak EUOperation* weakOperation = operation;
			__block ShipFit* shipFit = (ShipFit*)(fit);
			
			__block eufe::Character* character = NULL;
			[operation addExecutionBlock:^{
				character = new eufe::Character(fittingViewController.fittingEngine);
				
				EVEAccount* currentAccount = [EVEAccount currentAccount];
				if (currentAccount && currentAccount.charKeyID && currentAccount.charVCode && currentAccount.characterID) {
					CharacterEVE* eveCharacter = [CharacterEVE characterWithCharacterID:currentAccount.characterID keyID:currentAccount.charKeyID vCode:currentAccount.charVCode name:currentAccount.characterName];
					character->setCharacterName([eveCharacter.name cStringUsingEncoding:NSUTF8StringEncoding]);
					character->setSkillLevels(*[eveCharacter skillsMap]);
				}
				else
					character->setCharacterName("All Skills 0");
				weakOperation.progress = 0.5;

				shipFit.character = character;
				[shipFit load];

				weakOperation.progress = 1.0;
			}];
			
			[operation setCompletionBlockInCurrentThread:^{
				if (![weakOperation isCancelled]) {
					fittingViewController.fittingEngine->getGang()->addPilot(character);
					fittingViewController.fit = shipFit;
					[fittingViewController.fits addObject:shipFit];
					[self.navigationController pushViewController:fittingViewController animated:YES];
				}
				else {
					if (character)
						delete character;
				}
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
		__block EUOperation* operation = [EUOperation operationWithIdentifier:@"FittingServiceMenuViewController+Select" name:NSLocalizedString(@"Creating POS Fit", nil)];
		__weak EUOperation* weakOperation = operation;
		__block POSFit* posFit = nil;
		__block eufe::ControlTower* controlTower = NULL;
		[operation addExecutionBlock:^{
			controlTower = new eufe::ControlTower(posFittingViewController.fittingEngine, type.typeID);

			weakOperation.progress = 0.5;
			posFit = [POSFit posFitWithFitName:type.typeName controlTower:controlTower];
			weakOperation.progress = 1.0;
		}];
		
		[operation setCompletionBlockInCurrentThread:^{
			if (![weakOperation isCancelled]) {
				[posFit save];
				posFittingViewController.fittingEngine->setControlTower(controlTower);
				posFittingViewController.fit = posFit;
				[self.navigationController pushViewController:posFittingViewController animated:YES];
			}
			else {
				if (controlTower)
					delete controlTower;
			}
		}];
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
	else {
		FittingViewController *fittingViewController = [[FittingViewController alloc] initWithNibName:@"FittingViewController" bundle:nil];
		__block EUOperation* operation = [EUOperation operationWithIdentifier:@"FittingServiceMenuViewController+Select" name:NSLocalizedString(@"Creating Ship Fit", nil)];
		__weak EUOperation* weakOperation = operation;
		__block ShipFit* fit = nil;
		__block eufe::Character* character = NULL;
		[operation addExecutionBlock:^{
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

			weakOperation.progress = 0.5;
			fit = [ShipFit shipFitWithFitName:type.typeName character:character];
			weakOperation.progress = 1.0;
		}];
		
		[operation setCompletionBlockInCurrentThread:^{
			if (![weakOperation isCancelled]) {
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
	
#pragma mark - Private

- (void) reload {
	__block EUOperation* operation = [EUOperation operationWithIdentifier:@"FittingServiceMenuViewController+Load" name:NSLocalizedString(@"Loading Fits", nil)];
	__weak EUOperation* weakOperation = operation;
	__block BOOL needsConvertTmp = NO;
	
	NSMutableArray* fitsTmp = [NSMutableArray array];
	[operation addExecutionBlock:^{
		@autoreleasepool {
			EUStorage* storage = [EUStorage sharedStorage];
			[storage.managedObjectContext performBlockAndWait:^{
				NSArray* shipFits = [ShipFit allFits];
				weakOperation.progress = 0.25;
				
				[fitsTmp addObjectsFromArray:[shipFits arrayGroupedByKey:@"type.groupID"]];
				weakOperation.progress = 0.5;
				[fitsTmp sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
					Fit* a = [obj1 objectAtIndex:0];
					Fit* b = [obj2 objectAtIndex:0];
					return [a.type.group.groupName compare:b.type.group.groupName];
				}];
				
				weakOperation.progress = 0.75;
				
				NSMutableArray* posFits = [NSMutableArray arrayWithArray:[POSFit allFits]];
				if (posFits.count > 0)
					[fitsTmp addObject:posFits];
				
				weakOperation.progress = 1.0;
			}];
		}
	}];
	
	[operation setCompletionBlockInCurrentThread:^{
		if (![weakOperation isCancelled]) {
			self.needsConvert = needsConvertTmp;
			self.fits = fitsTmp;
			[self.menuTableView reloadData];
		}
	}];
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) convertFits {
/*	__block EUOperation* operation = [EUOperation operationWithIdentifier:@"FittingServiceMenuViewController+Convert" name:NSLocalizedString(@"Converting Fits", nil)];
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
	[[EUOperationQueue sharedQueue] addOperation:operation];*/
}

- (void) save {
/*	NSMutableArray* allFits = [NSMutableArray array];
	for (NSArray* rows in fits) {
		for (NSDictionary* row in rows) {
			NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithDictionary:row];
			[dictionary setValue:nil forKey:@"type"];
			[allFits addObject:dictionary];
		}
	}
	
	[[allFits sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"fitID" ascending:YES]]]
	 writeToURL:[NSURL fileURLWithPath:[Globals fitsFilePath]] atomically:YES];*/
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
							 }
							 else if (selectedButtonIndex == 1) {
								 NSString* xml = [ShipFit allFitsEveXML];
								 [[UIPasteboard generalPasteboard] setString:xml];
							 }
							 else if (selectedButtonIndex == 2) {
								 NSString* xml = [ShipFit allFitsEveXML];
								 MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
								 controller.mailComposeDelegate = self;
								 [controller setSubject:NSLocalizedString(@"Neocom fits", nil)];
								 [controller addAttachmentData:[xml dataUsingEncoding:NSUTF8StringEncoding] mimeType:@"application/xml" fileName:@"fits.xml"];
								 [self presentModalViewController:controller animated:YES];
								 
							 }
						 }
							 cancelBlock:nil] showFromRect:[self.menuTableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]] inView:self.menuTableView animated:YES];
	
}

- (void) didUpdateCloud:(NSNotification*) notification {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self reload];
	});
}

@end
