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
#import "UITableViewCell+Nib.h"
#import "UIImageView+GIF.h"
#import "SelectCharacterBarButtonItem.h"
#import "Globals.h"
#import "ItemViewController.h"
#import "NSString+TimeLeft.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"

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
	self.title = NSLocalizedString(@"Skills", nil);
	
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
		[self.navigationItem setRightBarButtonItem:[SelectCharacterBarButtonItem barButtonItemWithParentViewController:self]];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:NotificationSelectAccount object:nil];

	[self loadData];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.navigationItem setHidesBackButton:YES];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self becomeFirstResponder];
}

- (BOOL) canBecomeFirstResponder {
	return YES;
}

- (void) motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
	if (motion == UIEventSubtypeMotionShake)
		[self.skillsTableView handleShake];
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
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	if (title) {
		CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
		view.collapsed = NO;
		view.titleLabel.text = title;

		BOOL canCollaps = NO;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			if (tableView == skillsTableView)
				canCollaps = YES;
		}
		else if (segmentedControl.selectedSegmentIndex == 1)
				canCollaps = YES;

		if (canCollaps)
			view.collapsed = [self tableView:tableView sectionIsCollapsed:section];
		else
			view.collapsImageView.hidden = YES;
		return view;
	}
	else
		return nil;
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
	
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	
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

#pragma mark - CollapsableTableViewDelegate

- (BOOL) tableView:(UITableView *)tableView sectionIsCollapsed:(NSInteger) section {
	NSMutableDictionary* dic = nil;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if (tableView == skillsTableView)
			dic = [skillGroups objectAtIndex:section];
	}
	else {
		if (segmentedControl.selectedSegmentIndex == 1)
			dic = [skillGroups objectAtIndex:section];
	}

	return [[dic valueForKey:@"collapsed"] boolValue];
}

- (BOOL) tableView:(UITableView *)tableView canCollapsSection:(NSInteger) section {
	NSMutableDictionary* dic = nil;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if (tableView == skillsTableView)
			dic = [skillGroups objectAtIndex:section];
	}
	else {
		if (segmentedControl.selectedSegmentIndex == 1)
			dic = [skillGroups objectAtIndex:section];
	}
	return dic != nil;
}

- (void) tableView:(UITableView *)tableView didCollapsSection:(NSInteger) section {
	NSMutableDictionary* dic = nil;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if (tableView == skillsTableView)
			dic = [skillGroups objectAtIndex:section];
	}
	else {
		if (segmentedControl.selectedSegmentIndex == 1)
			dic = [skillGroups objectAtIndex:section];
	}

	[dic setValue:@(YES) forKey:@"collapsed"];
}

- (void) tableView:(UITableView *)tableView didExpandSection:(NSInteger) section {
	NSMutableDictionary* dic = nil;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if (tableView == skillsTableView)
			dic = [skillGroups objectAtIndex:section];
	}
	else {
		if (segmentedControl.selectedSegmentIndex == 1)
			dic = [skillGroups objectAtIndex:section];
	}
	
	[dic setValue:@(NO) forKey:@"collapsed"];
}

@end

@implementation SkillsViewController(Private)

- (void) loadData {
	NSMutableArray *skillQueueTmp = [NSMutableArray array];
	NSMutableArray *skillGroupsTmp = [NSMutableArray array];
	__block NSString *skillQueueTitleTmp = nil;
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"SkillsViewController+Load" name:NSLocalizedString(@"Loading Skills", nil)];
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
		operation.progress = 0.3;
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
				skill.level = [NSString stringWithFormat:NSLocalizedString(@"Level %d", nil), item.level];
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
			operation.progress = 0.3;
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
					skill.skillPoints = [NSString stringWithFormat:NSLocalizedString(@"SP: %@", nil), [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:item.skillpoints] numberStyle:NSNumberFormatterDecimalStyle]];
					skill.level = [NSString stringWithFormat:NSLocalizedString(@"Level %d", nil), item.level];
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
					[group setValue:[NSString stringWithFormat:NSLocalizedString(@"%@ (%@ skillpoints)", nil), [group valueForKey:@"groupName"], [NSNumberFormatter localizedStringFromNumber:[group valueForKey:@"skillPoints"] numberStyle:NSNumberFormatterDecimalStyle]] forKey:@"groupName"];
				}
			}
			operation.progress = 0.6;
			if (skillQueueTitle) {
				[skillQueueTitle release];
				skillQueueTitle = nil;
			}
			if (account.skillQueue.skillQueue.count == 0)
				skillQueueTitle = [[NSString alloc] initWithFormat:NSLocalizedString(@"Training queue inactive.", nil)];
			else {
				EVESkillQueueItem *lastSkill = [account.skillQueue.skillQueue lastObject];
				if (lastSkill.endTime) {
					NSTimeInterval remainingTime = [lastSkill.endTime timeIntervalSinceDate:currentTime];
					skillQueueTitleTmp = [[NSString alloc] initWithFormat:NSLocalizedString(@"Finishes %@ (%@)", nil),
										  [[NSDateFormatter eveDateFormatter] stringFromDate:lastSkill.endTime],
										  [NSString stringWithTimeLeft:remainingTime]];
				}
				else
					skillQueueTitleTmp = [[NSString alloc] initWithString:NSLocalizedString(@"Training queue is inactive", nil)];
			}
			operation.progress = 1.0;
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
