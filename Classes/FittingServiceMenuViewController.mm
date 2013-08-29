//
//  FittingServiceMenuViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FittingServiceMenuViewController.h"
#import "GroupedCell.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"
#import "GroupedCell.h"
#import "Globals.h"
#import "FittingViewController.h"
#import "POSFittingViewController.h"
#import "EVEDBAPI.h"
#import "BCSearchViewController.h"
#import "ShipFit.h"
#import "POSFit.h"
#import "EVEAccount.h"
#import "NSArray+GroupBy.h"
#import "FittingExportViewController.h"
#import "NSString+UUID.h"
#import "UIActionSheet+Block.h"
#import "UIActionSheet+Neocom.h"
#import "EUStorage.h"
#import "NAPISearchViewController.h"
#import "NeocomAPI.h"
#import "FitCharacter.h"
#import "appearance.h"
#import "UIViewController+Neocom.h"

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
	[self.navigationItem setRightBarButtonItem:self.editButtonItem];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
		self.itemsViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil)
																											style:UIBarButtonItemStyleBordered
																										   target:self
																										   action:@selector(dismiss)];
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

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	[self.tableView setEditing:editing animated:animated];
	if (!editing) {
	}
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return [self.fits count] + 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return section == 0 ? 5 : [self.fits[section - 1] count];
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
		cell.detailTextLabel.text = nil;
		if (indexPath.row == 0) {
			cell.textLabel.text = NSLocalizedString(@"Browse Fits on BattleClinic", nil);
			cell.imageView.image = [UIImage imageNamed:@"battleclinic.png"];
		}
		else if (indexPath.row == 1) {
			cell.textLabel.text = NSLocalizedString(@"Browse Community Fits", nil);
			cell.imageView.image = [UIImage imageNamed:@"Icons/icon26_02.png"];
		}
		else if (indexPath.row == 2) {
			cell.textLabel.text = NSLocalizedString(@"New Ship Fit", nil);
			cell.imageView.image = [UIImage imageNamed:@"Icons/icon17_04.png"];
		}
		else if (indexPath.row == 3) {
			cell.textLabel.text = NSLocalizedString(@"New POS Fit", nil);
			cell.imageView.image = [UIImage imageNamed:@"Icons/icon07_06.png"];
		}
		else {
			cell.textLabel.text = NSLocalizedString(@"Export", nil);
			cell.imageView.image = [UIImage imageNamed:@"Icons/icon94_03.png"];
		}
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
			return [[rows objectAtIndex:0] valueForKeyPath:@"type.group.groupName"];
		else
			return nil;
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
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
		}
		else {
			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
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
		if (indexPath.row == 0) {
			BCSearchViewController *controller = [[BCSearchViewController alloc] initWithNibName:@"BCSearchViewController" bundle:nil];
			[self.navigationController pushViewController:controller animated:YES];
		}
		else if (indexPath.row == 1) {
			NAPISearchViewController *controller = [[NAPISearchViewController alloc] initWithNibName:@"NAPISearchViewController" bundle:nil];
			[self.navigationController pushViewController:controller animated:YES];
		}
		else if (indexPath.row == 2) {
			self.itemsViewController.conditions = @[@"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 6"];
			self.itemsViewController.title = NSLocalizedString(@"Ships", nil);
			
			__weak FittingServiceMenuViewController* weakSelf = self;
			self.itemsViewController.completionHandler = ^(EVEDBInvType* type) {
				[weakSelf dismiss];
				FittingViewController *fittingViewController = [[FittingViewController alloc] initWithNibName:@"FittingViewController" bundle:nil];
				EUOperation* operation = [EUOperation operationWithIdentifier:@"FittingServiceMenuViewController+Select" name:NSLocalizedString(@"Creating Ship Fit", nil)];
				__weak EUOperation* weakOperation = operation;
				__block ShipFit* fit = nil;
				__block eufe::Character* character = NULL;
				[operation addExecutionBlock:^{
					character = new eufe::Character(fittingViewController.fittingEngine);
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
						fittingViewController.fittingEngine->getGang()->addPilot(character);
						fittingViewController.fit = fit;
						[fittingViewController.fits addObject:fit];
						[weakSelf.navigationController pushViewController:fittingViewController animated:YES];
					}
					else {
						if (character)
							delete character;
					}
				}];
				[[EUOperationQueue sharedQueue] addOperation:operation];
			};
			
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
				[self presentViewControllerInPopover:self.itemsViewController
											fromRect:[tableView rectForRowAtIndexPath:indexPath]
											  inView:tableView
							permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
			else
				[self presentViewController:self.itemsViewController animated:YES completion:nil];

		}
		else if (indexPath.row == 3) {
			self.itemsViewController.conditions = @[@"invTypes.marketGroupID = 478"];
			self.itemsViewController.title = NSLocalizedString(@"Ships", nil);
			
			__weak FittingServiceMenuViewController* weakSelf = self;
			self.itemsViewController.completionHandler = ^(EVEDBInvType* type) {
				[weakSelf dismiss];
				POSFittingViewController *posFittingViewController = [[POSFittingViewController alloc] initWithNibName:@"POSFittingViewController" bundle:nil];
				EUOperation* operation = [EUOperation operationWithIdentifier:@"FittingServiceMenuViewController+Select" name:NSLocalizedString(@"Creating POS Fit", nil)];
				__weak EUOperation* weakOperation = operation;
				__block POSFit* posFit = nil;
				__block eufe::ControlTower* controlTower = NULL;
				[operation addExecutionBlock:^{
					controlTower = new eufe::ControlTower(posFittingViewController.fittingEngine, type.typeID);
					
					weakOperation.progress = 0.5;
					posFit = [POSFit posFitWithFitName:type.typeName controlTower:controlTower];
					weakOperation.progress = 1.0;
				}];
				
				[operation setCompletionBlockInMainThread:^{
					if (![weakOperation isCancelled]) {
						[posFit save];
						posFittingViewController.fittingEngine->setControlTower(controlTower);
						posFittingViewController.fit = posFit;
						[weakSelf.navigationController pushViewController:posFittingViewController animated:YES];
					}
					else {
						if (controlTower)
							delete controlTower;
					}
				}];
				[[EUOperationQueue sharedQueue] addOperation:operation];
			};
			
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
				[self presentViewControllerInPopover:self.itemsViewController
											fromRect:[tableView rectForRowAtIndexPath:indexPath]
											  inView:tableView
							permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
			else
				[self presentViewController:self.itemsViewController animated:YES completion:nil];
		}
		else {
			[self exportFits];
		}
	}
	else {
		Fit* fit = self.fits[indexPath.section - 1][indexPath.row];

		if ([fit isKindOfClass:[POSFit class]]) {
			POSFittingViewController *posFittingViewController = [[POSFittingViewController alloc] initWithNibName:@"POSFittingViewController" bundle:nil];
			EUOperation* operation = [EUOperation operationWithIdentifier:@"FittingServiceMenuViewController+Select" name:NSLocalizedString(@"Loading POS Fit", nil)];
			__weak EUOperation* weakOperation = operation;
			__block POSFit* posFit = (POSFit*)(fit);
			[operation addExecutionBlock:^{
				posFit.controlTower = posFittingViewController.fittingEngine->setControlTower(posFit.typeID);
				[posFit load];
			}];
			
			[operation setCompletionBlockInMainThread:^{
				if (![weakOperation isCancelled]) {
					posFittingViewController.fit = posFit;
					[self.navigationController pushViewController:posFittingViewController animated:YES];
				}
			}];
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
		else {
			FittingViewController *fittingViewController = [[FittingViewController alloc] initWithNibName:@"FittingViewController" bundle:nil];
			EUOperation* operation = [EUOperation operationWithIdentifier:@"FittingServiceMenuViewController+Select" name:NSLocalizedString(@"Loading Ship Fit", nil)];
			__weak EUOperation* weakOperation = operation;
			__block ShipFit* shipFit = (ShipFit*)(fit);
			
			__block eufe::Character* character = NULL;
			[operation addExecutionBlock:^{
				character = new eufe::Character(fittingViewController.fittingEngine);
				
				EVEAccount* currentAccount = [EVEAccount currentAccount];
				if (currentAccount.characterSheet) {
					FitCharacter* fitCharacter = [FitCharacter fitCharacterWithAccount:currentAccount];
					character->setCharacterName([fitCharacter.name cStringUsingEncoding:NSUTF8StringEncoding]);
					character->setSkillLevels(*[fitCharacter skillsMap]);
				}
				else
					character->setCharacterName([NSLocalizedString(@"All Skills 0", nil) UTF8String]);
				weakOperation.progress = 0.5;

				shipFit.character = character;
				[shipFit load];

				weakOperation.progress = 1.0;
			}];
			
			[operation setCompletionBlockInMainThread:^{
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

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex != alertView.cancelButtonIndex)
		[self convertFits];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
	[self dismissViewControllerAnimated:YES completion:nil];
}
	
#pragma mark - Private

- (void) reload {
	EUOperation* operation = [EUOperation operationWithIdentifier:@"FittingServiceMenuViewController+Load" name:NSLocalizedString(@"Loading Fits", nil)];
	__weak EUOperation* weakOperation = operation;
	
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
	
	[operation setCompletionBlockInMainThread:^{
		if (![weakOperation isCancelled]) {
			self.fits = fitsTmp;
			[self.tableView reloadData];
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
	
	[operation setCompletionBlockInMainThread:^{
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
	[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackOpaque
								   title:NSLocalizedString(@"Export", nil)
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
								 
								 [self presentViewController:navController animated:YES completion:nil];
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
								 [self presentViewController:controller animated:YES completion:nil];
							 }
						 }
							 cancelBlock:nil] showInWindowFromRect:[self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]] inView:self.tableView animated:YES];
	NSLog(@"%@", [NSValue valueWithCGRect:[self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]]]);
	
}

- (void) didUpdateCloud:(NSNotification*) notification {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self reload];
	});
}

@end
