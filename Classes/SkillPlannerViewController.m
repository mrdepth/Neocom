//
//  SkillPlannerViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SkillPlannerViewController.h"
#import "SkillCellView.h"
#import "NibTableViewCell.h"
#import "EUOperationQueue.h"
#import "EVEAccount.h"
#import "UIAlertView+Error.h"
#import "SkillPlan.h"
#import "TrainingQueue.h"
#import "UIImageView+GIF.h"
#import "NSString+TimeLeft.h"
#import "ItemViewController.h"
#import "ItemCellView.h"
#import "Globals.h"
#import "SkillPlannerImportViewController.h"
#import "BrowserViewController.h"

#define ActionButtonLevel1 @"Train to Level 1"
#define ActionButtonLevel2 @"Train to Level 2"
#define ActionButtonLevel3 @"Train to Level 3"
#define ActionButtonLevel4 @"Train to Level 4"
#define ActionButtonLevel5 @"Train to Level 5"
#define ActionButtonCancel @"Cancel"

@interface SkillPlannerViewController(Private)

- (void) loadData;
- (void) didAddSkill:(NSNotification*) notification;
- (void) didChangeSkill:(NSNotification*) notification;
- (void) didSelectAccount:(NSNotification*) notification;
- (void) reloadTrainingTime;

@end

@implementation SkillPlannerViewController
@synthesize skillsTableView;
@synthesize trainingTimeLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSkillPlanDidAddSkill object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSkillPlanDidChangeSkill object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSelectAccount object:nil];
	[skillsTableView release];
	[skillPlan release];
	[trainingTimeLabel release];
	[modifiedIndexPath release];
	[super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = @"Skill Planner";
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
    // Do any additional setup after loading the view from its nib.
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAddSkill:) name:NotificationSkillPlanDidAddSkill object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeSkill:) name:NotificationSkillPlanDidChangeSkill object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:NotificationSelectAccount object:nil];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self loadData];
}

- (void)viewDidUnload
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSkillPlanDidAddSkill object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSkillPlanDidChangeSkill object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSelectAccount object:nil];
	[self setTrainingTimeLabel:nil];
    [super viewDidUnload];
	self.skillsTableView = nil;
	[skillPlan release];
	skillPlan = nil;
	[modifiedIndexPath release];
	modifiedIndexPath = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	[skillsTableView setEditing:editing animated:animated];
	//NSArray* clearRow = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:skillPlan.skills.count inSection:0]];
	NSIndexSet* section = [NSIndexSet indexSetWithIndex:1];
	if (editing)
		//[skillsTableView insertRowsAtIndexPaths:clearRow withRowAnimation:UITableViewRowAnimationFade];
		[skillsTableView insertSections:section withRowAnimation:UITableViewRowAnimationFade];
	else {
		[skillsTableView deleteSections:section withRowAnimation:UITableViewRowAnimationFade];
		//[skillsTableView deleteRowsAtIndexPaths:clearRow withRowAnimation:UITableViewRowAnimationFade];
		[skillPlan save];
	}
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.editing ? 2 : 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return section == 0 ? skillPlan.skills.count : 3;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
		NSString *cellIdentifier = @"ItemCellView";
		
		ItemCellView *cell = (ItemCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [ItemCellView cellWithNibName:@"ItemCellView" bundle:nil reuseIdentifier:cellIdentifier];
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
		
		if (indexPath.row == 0) {
			cell.titleLabel.text = @"Clear skill plan";
			cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon77_12.png"];
		}
		else if (indexPath.row == 1) {
			cell.titleLabel.text = @"Import skill plan from EVEMon";
			cell.iconImageView.image = [UIImage imageNamed:@"EVEMonLogoBlue.png"];
		}
		else {
			cell.titleLabel.text = @"Importing tutorial";
			cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon74_14.png"];
		}
		return cell;
	}
	else {
		static NSString *cellIdentifier = @"SkillCellView";
		
		SkillCellView *cell = (SkillCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [SkillCellView cellWithNibName:@"SkillCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		
		EVEAccount* account = [EVEAccount currentAccount];
		
		EVEDBInvTypeRequiredSkill* skill = [skillPlan.skills objectAtIndex:indexPath.row];
		EVESkillQueueItem* trainedSkill = account.skillQueue.skillQueue.count > 0 ? [account.skillQueue.skillQueue objectAtIndex:0] : nil;
		
		BOOL isActive = trainedSkill.typeID == skill.typeID;

		cell.iconImageView.image = [UIImage imageNamed:(isActive ? @"Icons/icon50_12.png" : @"Icons/icon50_13.png")];
		NSString* levelImageName = [NSString stringWithFormat:@"level_%d%d%d.gif", skill.currentLevel, skill.requiredLevel, isActive];
		NSString* levelImagePath = [[NSBundle mainBundle] pathForResource:levelImageName ofType:nil];
		if (levelImagePath)
			[cell.levelImageView setGIFImageWithContentsOfURL:[NSURL fileURLWithPath:levelImagePath]];
		else
			[cell.levelImageView setImage:nil];
		
		EVEDBDgmTypeAttribute *attribute = [[skill attributesDictionary] valueForKey:@"275"];
		cell.skillLabel.text = [NSString stringWithFormat:@"%@ (x%d)", skill.typeName, (int) attribute.value];
		cell.skillPointsLabel.text = [NSString stringWithFormat:@"SP: %@", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:skill.requiredSP] numberStyle:NSNumberFormatterDecimalStyle]];
		cell.levelLabel.text = [NSString stringWithFormat:@"Level %d", skill.requiredLevel];
		NSTimeInterval trainingTime = (skill.requiredSP - skill.currentSP) / [skillPlan.characterAttributes skillpointsPerSecondForSkill:skill];
		cell.remainingLabel.text = [NSString stringWithTimeLeft:trainingTime];
		return cell;
	}
}

- (BOOL) tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section == 0;
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section == 0;
}

/*- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
 return proposedDestinationIndexPath;
 }*/

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    NSObject *objectToMove = [[skillPlan.skills objectAtIndex:fromIndexPath.row] retain];
    [skillPlan.skills removeObjectAtIndex:fromIndexPath.row];
    [skillPlan.skills insertObject:objectToMove atIndex:toIndexPath.row];
    [objectToMove release];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		[skillPlan removeSkill:[skillPlan.skills objectAtIndex:indexPath.row]];
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		[self reloadTrainingTime];
	}
}

#pragma mark -
#pragma mark Table view delegate


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.section == 0) {
		EVEDBInvTypeRequiredSkill* skill = [skillPlan.skills objectAtIndex:indexPath.row];
		if (self.editing) {
			[modifiedIndexPath release];
			modifiedIndexPath = [indexPath retain];
			UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:nil
																	 delegate:self
															cancelButtonTitle:nil
													   destructiveButtonTitle:nil
															otherButtonTitles:nil];
			if (skill.currentLevel < 1)
				[actionSheet addButtonWithTitle:ActionButtonLevel1];
			if (skill.currentLevel < 2)
				[actionSheet addButtonWithTitle:ActionButtonLevel2];
			if (skill.currentLevel < 3)
				[actionSheet addButtonWithTitle:ActionButtonLevel3];
			if (skill.currentLevel < 4)
				[actionSheet addButtonWithTitle:ActionButtonLevel4];
			if (skill.currentLevel < 5)
				[actionSheet addButtonWithTitle:ActionButtonLevel5];
			
			[actionSheet addButtonWithTitle:ActionButtonCancel];
			actionSheet.cancelButtonIndex = actionSheet.numberOfButtons - 1;
			
			[actionSheet showFromRect:[tableView rectForRowAtIndexPath:indexPath] inView:tableView animated:YES];
			[actionSheet release];
		}
		else {
			ItemViewController *controller = [[ItemViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"ItemViewController-iPad" : @"ItemViewController")
																				  bundle:nil];
			
			controller.type = skill;
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
	}
	else {
		if (indexPath.row == 0) {
			UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Clear skill plan?"
																message:@""
															   delegate:self
													  cancelButtonTitle:@"No"
													  otherButtonTitles:@"Yes", nil];
			[alertView show];
			[alertView autorelease];
		}
		else if (indexPath.row == 1) {
			SkillPlannerImportViewController* controller = [[SkillPlannerImportViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"SkillPlannerImportViewController-iPad" : @"SkillPlannerImportViewController")
																											  bundle:nil];
			controller.delegate = self;
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
			navController.navigationBar.barStyle = UIBarStyleBlackOpaque;

			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
				navController.modalPresentationStyle = UIModalPresentationFormSheet;
			
			[self presentModalViewController:navController animated:YES];
			[navController release];
			[controller release];
		}
		else {
			BrowserViewController *controller = [[BrowserViewController alloc] initWithNibName:@"BrowserViewController" bundle:nil];
			NSString* path = [[NSBundle mainBundle] pathForResource:@"ImportingTutorial/index" ofType:@"html"];
			controller.title = @"Importing tutorial";
			controller.startPageURL = [NSURL fileURLWithPath:path];
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
				controller.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentModalViewController:controller animated:YES];
			[controller release];
		}
	}
}

#pragma mark UIActionSheetDelegate

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *button = [actionSheet buttonTitleAtIndex:buttonIndex];
	EVEDBInvTypeRequiredSkill* skill = [skillPlan.skills objectAtIndex:modifiedIndexPath.row];
	if ([button isEqualToString:ActionButtonCancel]) {
		return;
	}
	else if ([button isEqualToString:ActionButtonLevel1]) {
		skill.requiredLevel = 1;
	}
	else if ([button isEqualToString:ActionButtonLevel2]) {
		skill.requiredLevel = 2;
	}
	else if ([button isEqualToString:ActionButtonLevel3]) {
		skill.requiredLevel = 3;
	}
	else if ([button isEqualToString:ActionButtonLevel4]) {
		skill.requiredLevel = 4;
	}
	else if ([button isEqualToString:ActionButtonLevel5]) {
		skill.requiredLevel = 5;
	}
	[skillPlan resetTrainingTime];
	[self reloadTrainingTime];
	
	[skillsTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:modifiedIndexPath] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark UIAlertViewDelegate

- (void) alertView:(UIAlertView *)aAlertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		[skillPlan clear];
		[skillPlan save];
		[self loadData];
	}
}

#pragma mark SkillPlannerImportViewControllerDelegate
- (void) skillPlannerImportViewController:(SkillPlannerImportViewController*) controller didSelectSkillPlan:(SkillPlan*) aSkillPlan {
	[[EVEAccount currentAccount] setSkillPlan:aSkillPlan];
	[aSkillPlan save];
	[self loadData];
}

@end


@implementation SkillPlannerViewController(Private)

- (void) loadData {
	__block EUSingleBlockOperation* operation = [EUSingleBlockOperation operationWithIdentifier:@"SkillPlannerViewController+Load"];
	__block SkillPlan* skillPlanTmp = nil;
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		EVEAccount *account = [EVEAccount currentAccount];
		if (!account) {
			[pool release];
			return;
		}
		skillPlanTmp = [account.skillPlan retain];
		
		NSError *error = nil;
		account.skillQueue = [EVESkillQueue skillQueueWithKeyID:account.charKeyID vCode:account.charVCode characterID:account.characterID error:&error];
		[skillPlanTmp trainingTime];
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		[skillPlan release];
		if (![operation isCancelled]) {
			skillPlan = skillPlanTmp;

			[skillsTableView reloadData];
			[self reloadTrainingTime];
		}
		else {
			skillPlan = nil;
			[skillPlanTmp release];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) didAddSkill:(NSNotification*) notification {
	if (notification.object == skillPlan) {
		[self reloadTrainingTime];
		[skillsTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:skillPlan.skills.count - 1 inSection:0]]
							   withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (void) didChangeSkill:(NSNotification*) notification {
	if (notification.object == skillPlan) {
		[self reloadTrainingTime];
		EVEDBInvTypeRequiredSkill* skill = [notification.userInfo valueForKey:@"skill"];
		[skillsTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:[skillPlan.skills indexOfObject:skill] inSection:0]]
							   withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (void) didSelectAccount:(NSNotification*) notification {
	EVEAccount *account = [EVEAccount currentAccount];
	if (!account)
		[self.navigationController popToRootViewControllerAnimated:YES];
	else {
		[skillPlan release];
		skillPlan = nil;
		[self loadData];
	}
}

- (void) reloadTrainingTime {
	trainingTimeLabel.text = skillPlan.skills.count > 0 ? [NSString stringWithFormat:@"Training time: %@", [NSString stringWithTimeLeft:skillPlan.trainingTime]] : @"Skill plan is empty";
}

@end
