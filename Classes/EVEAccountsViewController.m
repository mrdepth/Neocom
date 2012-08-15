//
//  EVEAccountsViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "EVEAccountsViewController.h"
#import "Globals.h"
#import "AddEVEAccountViewController.h"
#import "EVEAccount.h"
#import "EVEOnlineAPI.h"
#import "EVEAccountsAPIKeyCellView.h"
#import "EVEAccountsCharacterCellView.h"
#import "NibTableViewCell.h"
#import "EVEUniverseAppDelegate.h"
#import "NSString+TimeLeft.h"
#import "NSInvocation+Variadic.h"
#import "AccessMaskViewController.h"

@interface EVEAccountsViewController(Private)
- (void) loadSection:(NSMutableDictionary*) section;
- (void) accountStorageDidChange:(NSNotification*) notification;
- (void) reload;
@end


@implementation EVEAccountsViewController
@synthesize accountsTableView;
@synthesize logoffButton;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
 // Custom initialization
 }
 return self;
 }
 */

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = @"Accounts";
	[self.navigationItem setRightBarButtonItem:self.editButtonItem];
	self.logoffButton.hidden = [EVEAccount currentAccount] == nil;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountStorageDidChange:) name:NotificationAccountStoargeDidChange object:nil];
}

- (void)viewDidUnload {
    [super viewDidUnload];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationAccountStoargeDidChange object:nil];

	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	self.accountsTableView = nil;
	self.logoffButton = nil;
	[sections release];
	sections = nil;
	loadingOperation = nil;
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
	[self reload];
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[loadingOperation cancel];
}

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationAccountStoargeDidChange object:nil];
	[accountsTableView release];
	[logoffButton release];
	[sections release];
    [super dealloc];
}

- (IBAction) onAddAccount: (id) sender {
	AddEVEAccountViewController *controller = [[AddEVEAccountViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"AddEVEAccountViewController-iPad" : @"AddEVEAccountViewController")
																							bundle:nil];
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

- (IBAction) onLogoff: (id) sender {
	[[EVEAccount currentAccount] logoff];
	[self.navigationController dismissModalViewControllerAnimated:YES];
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	[accountsTableView setEditing:editing animated:animated];
	NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
	int sectionIndex = 0;
	for (NSDictionary *section in sections) {
		EVEAccountStorageCharacter *character = [section valueForKey:@"character"];
		if (character && !character.enabled) {
			[indexes addIndex:sectionIndex]; 
		}
		sectionIndex++;
	}
	[accountsTableView reloadSections:indexes withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSDictionary *sectionDic = [sections objectAtIndex:section];
	EVEAccountStorageCharacter *character = [sectionDic valueForKey:@"character"];
	if (character) {
		if (self.editing || character.enabled)
			return [[sectionDic valueForKey:@"apiKeys"] count] + 1;
		else
			return 0;
	}
	else
		return [[sectionDic valueForKey:@"apiKeys"] count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *section = [sections objectAtIndex:indexPath.section];
	EVEAccountStorageCharacter *character = [section valueForKey:@"character"];
	if (character && indexPath.row == 0) {
		static NSString *cellIdentifier = @"EVEAccountsCharacterCellView";
		
		EVEAccountsCharacterCellView *cell = (EVEAccountsCharacterCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [EVEAccountsCharacterCellView cellWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"EVEAccountsCharacterCellView-iPad" : @"EVEAccountsCharacterCellView")
														  bundle:nil
												 reuseIdentifier:cellIdentifier];
		}
		
		if (RETINA_DISPLAY) {
			[cell.portraitImageView setImageWithContentsOfURL:[EVEImage characterPortraitURLWithCharacterID:character.characterID size:EVEImageSize128 error:nil] scale:2.0];
			[cell.corpImageView setImageWithContentsOfURL:[EVEImage corporationLogoURLWithCorporationID:character.corporationID size:EVEImageSize64 error:nil] scale:2.0];
		}
		else {
			[cell.portraitImageView setImageWithContentsOfURL:[EVEImage characterPortraitURLWithCharacterID:character.characterID size:EVEImageSize64 error:nil] scale:1.0];
			[cell.corpImageView setImageWithContentsOfURL:[EVEImage corporationLogoURLWithCorporationID:character.corporationID size:EVEImageSize32 error:nil] scale:1.0];
		}
		cell.userNameLabel.text = character.characterName;
		cell.corpLabel.text = character.corporationName;
		
		cell.character = character;
		UIColor *color;

		cell.trainingTimeLabel.text = [section valueForKey:@"trainingTime"];
		color = [section valueForKey:@"trainingTimeColor"];
		if (color)
			cell.trainingTimeLabel.textColor = color;
		
		cell.paidUntilLabel.text = [section valueForKey:@"paidUntil"];
		color = [section valueForKey:@"paidUntilColor"];
		if (color)
			cell.paidUntilLabel.textColor = color;

		
		return cell;
	}
	else {
		EVEAccountStorageAPIKey *apiKey = [[section valueForKey:@"apiKeys"] objectAtIndex:indexPath.row - (character ? 1 : 0)];
		
		NSString *cellIdentifier = apiKey.error ? @"EVEAccountsAPIKeyCellViewError" : @"EVEAccountsAPIKeyCellView";

		
		EVEAccountsAPIKeyCellView *cell = (EVEAccountsAPIKeyCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [EVEAccountsAPIKeyCellView cellWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"EVEAccountsAPIKeyCellView-iPad" : @"EVEAccountsAPIKeyCellView")
														bundle:nil
											   reuseIdentifier:cellIdentifier];
		}
		cell.accessMaskLabel.text = [NSString stringWithFormat:@"%d", apiKey.apiKeyInfo.key.accessMask];
		cell.keyIDLabel.text = [NSString stringWithFormat:@"%d", apiKey.keyID];
		cell.topSeparator.hidden = indexPath.row > 0;
		if (apiKey.error) {
			cell.errorLabel.text = [apiKey.error localizedDescription];
		}
		else {
			cell.keyTypeLabel.text = apiKey.apiKeyInfo.key.type == EVEAPIKeyTypeCorporation ? @"Corporation" : @"Character";
			if (apiKey.apiKeyInfo.key.expires) {
				NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
				[dateFormatter setDateFormat:@"yyyy.MM.dd"];
				cell.expiredLabel.text = [dateFormatter stringFromDate:apiKey.apiKeyInfo.key.expires];
				[dateFormatter release];
			}
			else
				cell.expiredLabel.text = @"-";
		}
		return cell;
	}
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (UITableViewCellEditingStyleDelete) {
		NSDictionary *sectionDic = [sections objectAtIndex:indexPath.section];
		EVEAccountStorageCharacter *character = [sectionDic valueForKey:@"character"];
		EVEAccountStorageAPIKey *apiKey = [[sectionDic valueForKey:@"apiKeys"] objectAtIndex:indexPath.row - (character ? 1 : 0)];
		[tableView beginUpdates];
		
		NSInteger sectionIndex = 0;
		for (NSDictionary *section in [NSArray arrayWithArray:sections]) {
			NSMutableArray *apiKeys = [section valueForKey:@"apiKeys"];
			NSInteger index = [apiKeys indexOfObject:apiKey];
			if (index != NSNotFound) {
				[apiKeys removeObjectAtIndex:index];
				if (apiKeys.count == 0) {
					[tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
					[sections removeObject:section];
				}
				else {
					NSInteger rowIndex = index + ([section valueForKey:@"character"] ? 1 : 0);
					[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex]] withRowAnimation:UITableViewRowAnimationFade];
				}
			}
			sectionIndex++;
		}
		[[EVEAccountStorage sharedAccountStorage] removeAPIKey:apiKey.keyID];
		
		[tableView endUpdates];
	}
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *sectionDic = [sections objectAtIndex:indexPath.section];
	EVEAccountStorageCharacter *character = [sectionDic valueForKey:@"character"];
	if (character && indexPath.row == 0)
		return 112;
	else
		return 40;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *section = [sections objectAtIndex:indexPath.section];
	EVEAccountStorageCharacter *character = [section valueForKey:@"character"];
	if (character && indexPath.row == 0) {
		[[EVEAccount accountWithCharacter:character] login];
		[self.navigationController dismissModalViewControllerAnimated:YES];
	}
	else {
		EVEAccountStorageAPIKey *apiKey = [[section valueForKey:@"apiKeys"] objectAtIndex:indexPath.row - (character ? 1 : 0)];
		if (apiKey && !apiKey.error) {
			AccessMaskViewController *controller = [[AccessMaskViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"AccessMaskViewController-iPad" : @"AccessMaskViewController")
																							  bundle:nil];
			controller.accessMask = apiKey.apiKeyInfo.key.accessMask;
			controller.corporate = apiKey.apiKeyInfo.key.type == EVEAPIKeyTypeCorporation;
			[self.navigationController pushViewController:controller animated:YES];
			[controller release];
		}
	}
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *sectionDic = [sections objectAtIndex:indexPath.section];
	EVEAccountStorageCharacter *character = [sectionDic valueForKey:@"character"];
	if (character && indexPath.row == 0)
		return UITableViewCellEditingStyleNone;
	else
		return UITableViewCellEditingStyleDelete;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	UIView *footer = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
	footer.opaque = NO;
	footer.backgroundColor = [UIColor clearColor];
	return footer;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	NSDictionary *sectionDic = [sections objectAtIndex:section];
	EVEAccountStorageCharacter *character = [sectionDic valueForKey:@"character"];
	if (character) {
		if (self.editing || character.enabled)
			return 10;
		else
			return 0;
	}
	else
		return [[sectionDic valueForKey:@"apiKeys"] count] > 0 ? 10 : 0;
}

@end

@implementation EVEAccountsViewController(Private)

- (void) loadSection:(NSMutableDictionary*) section {
	EVEAccountStorageCharacter *character = [section valueForKey:@"character"];
	
	if (character) {
		EVEAccountStorageAPIKey *apiKey = [character anyCharAPIKey];
		if (!apiKey) {
		}
		else {
			NSError *error = nil;
			EVEAccountStatus *accountStatus = [EVEAccountStatus accountStatusWithKeyID:apiKey.keyID vCode:apiKey.vCode error:&error];
			if (error) {
				[section setValue:[error localizedDescription] forKey:@"paidUntil"];
				[section setValue:[UIColor whiteColor] forKey:@"paidUntilColor"];
			}
			else {
				UIColor *color;
				NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
				[dateFormatter setDateFormat:@"yyyy-MM-dd"];
				int days = [accountStatus.paidUntil timeIntervalSinceNow] / (60 * 60 * 24);
				if (days < 0)
					days = 0;
				if (days > 7)
					color = [UIColor greenColor];
				else if (days == 0)
					color = [UIColor redColor];
				else
					color = [UIColor yellowColor];
				[section setValue:[NSString stringWithFormat:@"%@ (%d days remaining)", [dateFormatter stringFromDate:accountStatus.paidUntil], days]
						   forKey:@"paidUntil"];
				[section setValue:color forKey:@"paidUntilColor"];
				[dateFormatter release];
			}
			
			EVESkillQueue *skillQueue = [EVESkillQueue skillQueueWithKeyID:apiKey.keyID vCode:apiKey.vCode characterID:character.characterID error:&error];
			if (error) {
				[section setValue:[error localizedDescription] forKey:@"trainingTime"];
				[section setValue:[UIColor whiteColor] forKey:@"trainingTimeColor"];
			}
			else {
				NSString *text;
				UIColor *color = nil;
				if (skillQueue.skillQueue.count > 0) {
					NSDate *endTime = [[skillQueue.skillQueue lastObject] endTime];
					NSTimeInterval timeLeft = [endTime timeIntervalSinceDate:[skillQueue serverTimeWithLocalTime:[NSDate date]]];
					if (timeLeft > 3600 * 24)
						color = [UIColor greenColor];
					else
						color = [UIColor yellowColor];
					text = [NSString stringWithFormat:@"%@ (%d skills in queue)", [NSString stringWithTimeLeft:timeLeft], skillQueue.skillQueue.count];
				}
				else {
					text = @"Training queue is inactive";
					color = [UIColor redColor];
				}
				[section setValue:text forKeyPath:@"trainingTime"];
				[section setValue:color forKeyPath:@"trainingTimeColor"];
			}
		}
	}
	else {
	}
}

- (void) accountStorageDidChange:(NSNotification*) notification {
	if (self.navigationController.visibleViewController == self)
		[self reload];
}

- (void) reload {
	NSMutableArray *sectionsTmp = [NSMutableArray array];
	NSMutableArray *emptyKeysTmp = [NSMutableArray array];
	
	__block EUSingleBlockOperation *operation = [EUSingleBlockOperation operationWithIdentifier:@"EVEAccountsViewController+Load"];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		if ([operation isCancelled]) {
			[pool release];
			return;
		}
		
		loadingOperation = operation;
		
		EVEAccountStorage *accountStorage = [EVEAccountStorage sharedAccountStorage];
		[accountStorage reload];
		
		NSOperationQueue *queue = [[NSOperationQueue alloc] init];
		
		for (EVEAccountStorageCharacter *character in [accountStorage.characters allValues]) {
			if ([operation isCancelled])
				break;
			
			NSMutableDictionary *section = [NSMutableDictionary dictionaryWithObject:character forKey:@"character"];
			NSMutableArray *apiKeys = [NSMutableArray arrayWithArray:character.assignedCharAPIKeys];
			[apiKeys addObjectsFromArray:character.assignedCorpAPIKeys];
			[section setValue:apiKeys forKey:@"apiKeys"];
			
			[sectionsTmp addObject:section];
			[queue addOperationWithBlock:^(void) {
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				[self loadSection:section];
				[pool release];
			}];
		}
		
		for (EVEAccountStorageAPIKey *apiKey in [accountStorage.apiKeys allValues])
			if (apiKey.assignedCharacters.count == 0)
				[emptyKeysTmp addObject:apiKey];
		
		if (emptyKeysTmp.count > 0) {
			NSMutableDictionary *section = [NSMutableDictionary dictionaryWithObject:emptyKeysTmp forKey:@"apiKeys"];
			[sectionsTmp addObject:section];
			[queue addOperationWithBlock:^(void) {
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				[self loadSection:section];
				[pool release];
			}];
		}
		
		
		[queue waitUntilAllOperationsAreFinished];
		[sectionsTmp sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
			EVEAccountStorageCharacter *character1 = [obj1 valueForKey:@"character"];
			EVEAccountStorageCharacter *character2 = [obj2 valueForKey:@"character"];
			if (!character1 && character2)
				return NSOrderedDescending;
			else if (character1 && !character2)
				return NSOrderedAscending;
			else
				return [character1.characterName compare:character2.characterName ? character2.characterName : @""];
		}];
		[queue release];
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (loadingOperation == operation)
			loadingOperation = nil;
		if (![operation isCancelled]) {
			[sections release];
			sections = [sectionsTmp retain];
		}
		[accountsTableView reloadData];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end
