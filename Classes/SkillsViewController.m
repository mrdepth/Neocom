//
//  SkillsViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/23/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SkillsViewController.h"
#import "EVEOnlineAPI.h"
#import "EVEAccount.h"
#import "EVEDBAPI.h"
#import "UIAlertView+Error.h"
#import "SkillCellView.h"
#import "NibTableViewCell.h"
#import "UIImageView+GIF.h"
#import "SelectCharacterBarButtonItem.h"
#import "Globals.h"
#import "ItemViewController.h"
#import "NSString+TimeLeft.h"

@interface Skill : NSObject {
	NSString *skillName;
	NSString *skillPoints;
	NSString *level;
	NSString *iconImageName;
	NSString *levelImageName;
	NSString *remainingTime;
	NSInteger typeID;
	NSInteger targetLevel;
	NSInteger startSkillPoints;
	NSInteger targetSkillPoints;
}
@property (nonatomic, retain) NSString *skillName;
@property (nonatomic, retain) NSString *skillPoints;
@property (nonatomic, retain) NSString *level;
@property (nonatomic, retain) NSString *iconImageName;
@property (nonatomic, retain) NSString *levelImageName;
@property (nonatomic, retain) NSString *remainingTime;
@property (nonatomic, assign) NSInteger typeID;
@property (nonatomic, assign) NSInteger targetLevel;
@property (nonatomic, assign) NSInteger startSkillPoints;
@property (nonatomic, assign) NSInteger targetSkillPoints;

- (NSComparisonResult) compare:(Skill*) other;
@end


@implementation Skill
@synthesize skillName;
@synthesize skillPoints;
@synthesize level;
@synthesize iconImageName;
@synthesize levelImageName;
@synthesize remainingTime;
@synthesize typeID;
@synthesize targetLevel;
@synthesize startSkillPoints;
@synthesize targetSkillPoints;

- (NSComparisonResult) compare:(Skill*) other {
	return [skillName compare:skillName];
}

- (void) dealloc {
	[skillName release];
	[skillPoints release];
	[level release];
	[iconImageName release];
	[levelImageName release];
	[remainingTime release];
	[super dealloc];
}

@end

/*NSComparisonResult compare(NSArray *a, NSArray *b, void* context) {
 return [[[[[a objectAtIndex:0] skill] group] groupName] compare:[[[[b objectAtIndex:0] skill] group] groupName]];
 }*/

@interface SkillsViewController(Private)

- (void) loadData;
- (void) didSelectAccount:(NSNotification*) notification;
@end


@implementation SkillsViewController
@synthesize skillsTableView;
@synthesize skillsQueueTableView;

@synthesize segmentedControl;
@synthesize characterInfoViewController;
@synthesize characterInfoView;

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
	self.title = @"Skills";
	
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
		[self.navigationItem setRightBarButtonItem:[SelectCharacterBarButtonItem barButtonItemWithParentViewController:self]];
		skillsTableView.visibleTopPartHeight = 24;
		[characterInfoView addSubview:characterInfoViewController.view];
		characterInfoViewController.view.frame = characterInfoView.bounds;
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:NotificationSelectAccount object:nil];

	[self loadData];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.navigationItem setHidesBackButton:YES];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
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
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSelectAccount object:nil];
	[NSObject cancelPreviousPerformRequestsWithTarget:characterInfoViewController];
	self.skillsTableView = nil;
	self.skillsQueueTableView = nil;
	self.segmentedControl = nil;
	self.characterInfoViewController = nil;
	self.characterInfoView = nil;
	
	[skillGroups release];
	[skillQueue release];
	[skillQueueTitle release];
	skillGroups = nil;
	skillQueue = nil;
	skillQueueTitle = nil;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSelectAccount object:nil];
	[NSObject cancelPreviousPerformRequestsWithTarget:characterInfoViewController];
	[skillsTableView release];
	[skillsQueueTableView release];
	[segmentedControl release];
	[characterInfoViewController release];
	[characterInfoView release];
	
	[skillGroups release];
	[skillQueue release];
	[skillQueueTitle release];
    [super dealloc];
}

- (IBAction) onChangeSegmentedControl:(id) sender {
	[skillsTableView reloadData];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if (tableView == skillsTableView)
			return skillGroups.count;
		else
			return skillQueue.count > 0 ? 1 : 0;
	}
	else {
		if (segmentedControl.selectedSegmentIndex == 1)
			return skillGroups.count;
		else
			return skillQueue.count > 0 ? 1 : 0;
	}
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if (tableView == skillsTableView)
			return [[[skillGroups objectAtIndex:section] valueForKey:@"skills"] count];
		else
			return skillQueue.count;
	}
	else {
		if (segmentedControl.selectedSegmentIndex == 1)
			return [[[skillGroups objectAtIndex:section] valueForKey:@"skills"] count];
		else
			return skillQueue.count;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if (tableView == skillsTableView)
			return [[skillGroups objectAtIndex:section] valueForKey:@"groupName"];
		else
			return skillQueueTitle;
	}
	else {
		if (segmentedControl.selectedSegmentIndex == 1)
			return [[skillGroups objectAtIndex:section] valueForKey:@"groupName"];
		else
			return skillQueueTitle;
	}
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"SkillCellView";
    
    SkillCellView *cell = (SkillCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [SkillCellView cellWithNibName:@"SkillCellView" bundle:nil reuseIdentifier:cellIdentifier];
    }
	Skill *skill;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if (tableView == skillsTableView)
			skill = [[[skillGroups objectAtIndex:indexPath.section] valueForKey:@"skills"] objectAtIndex:indexPath.row];
		else
			skill = [skillQueue objectAtIndex:indexPath.row];
	}
	else {
		if (segmentedControl.selectedSegmentIndex == 1)
			skill = [[[skillGroups objectAtIndex:indexPath.section] valueForKey:@"skills"] objectAtIndex:indexPath.row];
		else
			skill = [skillQueue objectAtIndex:indexPath.row];
	}
	cell.iconImageView.image = [UIImage imageNamed:skill.iconImageName];
	NSString* levelImagePath = [[NSBundle mainBundle] pathForResource:skill.levelImageName ofType:nil];
	if (levelImagePath)
		[cell.levelImageView setGIFImageWithContentsOfURL:[NSURL fileURLWithPath:levelImagePath]];
	else
		[cell.levelImageView setImage:nil];
	cell.skillLabel.text = skill.skillName;
	cell.skillPointsLabel.text = skill.skillPoints;
	cell.levelLabel.text = skill.level;
	cell.remainingLabel.text = skill.remainingTime ? skill.remainingTime : @"";
	
    return cell;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	Skill *skill;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if (tableView == skillsTableView)
			skill = [[[skillGroups objectAtIndex:indexPath.section] valueForKey:@"skills"] objectAtIndex:indexPath.row];
		else
			skill = [skillQueue objectAtIndex:indexPath.row];
	}
	else {
		if (segmentedControl.selectedSegmentIndex == 1)
			skill = [[[skillGroups objectAtIndex:indexPath.section] valueForKey:@"skills"] objectAtIndex:indexPath.row];
		else
			skill = [skillQueue objectAtIndex:indexPath.row];
	}
	
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"ItemViewController-iPad" : @"ItemViewController")
																		  bundle:nil];
	
	controller.type = [EVEDBInvType invTypeWithTypeID:skill.typeID error:nil];
	[controller setActivePage:ItemViewControllerActivePageInfo];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
		[self presentModalViewController:navController animated:YES];
		[navController release];
	}
	else
		[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

#pragma mark CharacterInfoViewControllerDelegate

- (void) characterInfoViewController:(CharacterInfoViewController*) controller willChangeContentSize:(CGSize) size animated:(BOOL) animated{
	if (animated) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.5];
		[UIView setAnimationBeginsFromCurrentState:YES];
	}
	//characterInfoViewController.view.frame = CGRectMake(0, 0, size.width, size.height);
	characterInfoView.frame = CGRectMake(0, 0, size.width, size.height);
	skillsTableView.frame = CGRectMake(0, size.height, skillsTableView.frame.size.width, skillsTableView.superview.frame.size.height - skillsTableView.visibleTopPartHeight);
	if (animated)
		[UIView commitAnimations];
}

@end

@implementation SkillsViewController(Private)

- (void) loadData {
	NSMutableArray *skillQueueTmp = [NSMutableArray array];
	NSMutableArray *skillGroupsTmp = [NSMutableArray array];
	__block NSString *skillQueueTitleTmp = nil;
	__block EUSingleBlockOperation *operation = [EUSingleBlockOperation operationWithIdentifier:@"SkillsViewController+Load"];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		EVEAccount *account = [EVEAccount currentAccount];
		if (!account) {
			[pool release];
			return;
		}
		
		NSError *error = nil;
		//character.skillQueue = [EVESkillQueue skillQueueWithUserID:character.userID apiKey:character.apiKey characterID:character.characterID error:&error];
		account.skillQueue = [EVESkillQueue skillQueueWithKeyID:account.charKeyID vCode:account.charVCode characterID:account.characterID error:&error];
		//[character updateSkillpoints];
		
		if (error) {
			[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
		}
		else {
			NSDate *currentTime = [account.skillQueue serverTimeWithLocalTime:[NSDate date]];
			
			int i = 0;
			for (EVESkillQueueItem *item in account.skillQueue.skillQueue) {
				EVEDBInvType *type = [EVEDBInvType invTypeWithTypeID:item.typeID error:nil];
				Skill *skill = [[Skill alloc] init];
				EVEDBDgmTypeAttribute *attribute = [[type attributesDictionary] valueForKey:@"275"];
				skill.skillName = [NSString stringWithFormat:@"%@ (x%d)", type.typeName, (int) attribute.value];
				skill.skillPoints = @"";
				skill.level = [NSString stringWithFormat:@"Level %d", item.level];
				skill.targetLevel = item.level;
				skill.typeID = item.typeID;
				skill.startSkillPoints = [type skillpointsAtLevel:item.level - 1];
				skill.targetSkillPoints = item.endSP;
				
				skill.iconImageName = @"Icons/icon50_12.png";
				skill.levelImageName = [NSString stringWithFormat:@"level_%d%d%d.gif", item.level - 1, item.level, 1];

				
				if (item.endTime) {
					NSTimeInterval remainingTime = [item.endTime timeIntervalSinceDate:i == 0 ? currentTime : item.startTime];
					skill.remainingTime = [NSString stringWithTimeLeft:remainingTime];
				}
				else
					skill.remainingTime = nil;
				
				[skillQueueTmp addObject:skill];
				[skill release];
				i++;
			}
			
			if (account.characterSheet.skills) {
				NSMutableDictionary *groups = [NSMutableDictionary dictionary];
				for (EVECharacterSheetSkill *item in account.characterSheet.skills) {
					EVEDBInvType *type = [EVEDBInvType invTypeWithTypeID:item.typeID error:nil];
					NSString *key = [NSString stringWithFormat:@"%d", type.group.groupID];
					NSMutableDictionary *group = [groups valueForKey:key];
					if (!group) {
						group = [NSMutableDictionary dictionaryWithObjectsAndKeys:type.group.groupName, @"groupName", [NSMutableArray array], @"skills", [NSNumber numberWithInt:0], @"skillPoints", nil];
						[groups setValue:group forKey:key];
					}
					NSMutableArray *skills = [group valueForKey:@"skills"];
					
					Skill *skill = [[Skill alloc] init];
					EVEDBDgmTypeAttribute *attribute = [[type attributesDictionary] valueForKey:@"275"];
					skill.skillName = [NSString stringWithFormat:@"%@ (x%d)", type.typeName, (int) attribute.value];
					skill.skillPoints = [NSString stringWithFormat:@"SP: %@", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:item.skillpoints] numberStyle:NSNumberFormatterDecimalStyle]];
					skill.level = [NSString stringWithFormat:@"Level %d", item.level];
					skill.typeID = item.typeID;
					
					NSInteger targetLevel = 0;
					BOOL isActive = NO;
					
					int i = 0;
					for (Skill *learnedSkill in skillQueueTmp) {
						if (learnedSkill.typeID == skill.typeID) {
							targetLevel = learnedSkill.targetLevel;
							if (i == 0) {
								isActive = YES;
							}
							learnedSkill.levelImageName = [NSString stringWithFormat:@"level_%d%d%d.gif", item.level, learnedSkill.targetLevel < item.level ? item.level : learnedSkill.targetLevel, item.level < learnedSkill.targetLevel ? isActive : NO];
							learnedSkill.iconImageName = isActive ? @"Icons/icon50_12.png" : @"Icons/icon50_13.png";
							learnedSkill.skillPoints = skill.skillPoints;
							if (!skill.remainingTime) {
								int progress;
								if (targetLevel == item.level + 1)
									progress = (item.skillpoints - learnedSkill.startSkillPoints) * 100 / (learnedSkill.targetSkillPoints - learnedSkill.startSkillPoints);
								else
									progress = 0;
								if (progress > 100)
									progress = 100;
								if (learnedSkill.remainingTime)
									learnedSkill.remainingTime = [NSString stringWithFormat:@"%@ (%d%%)", learnedSkill.remainingTime, progress];
								skill.remainingTime = learnedSkill.remainingTime;
							}
						}
						i++;
					}
					skill.iconImageName = isActive ? @"Icons/icon50_12.png" : (item.level == 5 ? @"Icons/icon50_14.png" : @"Icons/icon50_13.png");
					skill.targetLevel = targetLevel;
					skill.levelImageName = [NSString stringWithFormat:@"level_%d%d%d.gif", item.level, targetLevel, isActive];
					[group setValue:[NSNumber numberWithInt:[[group valueForKey:@"skillPoints"] integerValue] + item.skillpoints] forKey:@"skillPoints"];
					
					[skills addObject:skill];
					[skill release];
				}
				
				[skillGroupsTmp addObjectsFromArray:[[groups allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"groupName" ascending:YES]]]];
				for (NSDictionary *group in skillGroupsTmp) {
					[[group valueForKey:@"skills"] sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"skillName" ascending:YES]]];
					[group setValue:[NSString stringWithFormat:@"%@ (%@ skillpoints)", [group valueForKey:@"groupName"], [NSNumberFormatter localizedStringFromNumber:[group valueForKey:@"skillPoints"] numberStyle:NSNumberFormatterDecimalStyle]] forKey:@"groupName"];
				}
			}
			
			if (skillQueueTitle) {
				[skillQueueTitle release];
				skillQueueTitle = nil;
			}
			if (account.skillQueue.skillQueue.count == 0)
				skillQueueTitle = [[NSString alloc] initWithFormat:@"Training queue inactive."];
			else {
				EVESkillQueueItem *lastSkill = [account.skillQueue.skillQueue lastObject];
				if (lastSkill.endTime) {
					NSTimeInterval remainingTime = [lastSkill.endTime timeIntervalSinceDate:currentTime];
					skillQueueTitleTmp = [[NSString alloc] initWithFormat:@"Finishes %@ (%@)",
										  [[NSDateFormatter eveDateFormatter] stringFromDate:lastSkill.endTime],
										  [NSString stringWithTimeLeft:remainingTime]];
				}
				else
					skillQueueTitleTmp = [[NSString alloc] initWithString:@"Training queue is inactive"];
			}
		}
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		skillQueueTitle = skillQueueTitleTmp;
		[skillGroups release];
		skillGroups = [skillGroupsTmp retain];
		[skillQueue release];
		skillQueue = [skillQueueTmp retain];
		[skillsTableView reloadData];
		[skillsQueueTableView reloadData];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) didSelectAccount:(NSNotification*) notification {
	EVEAccount *account = [EVEAccount currentAccount];
	if (!account) {
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[self loadData];
		else
			[self.navigationController popToRootViewControllerAnimated:YES];
	}
	else {
		[self loadData];
	}
}

@end
