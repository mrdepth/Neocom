//
//  SkillPlannerViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SkillPlannerViewController.h"
#import "SkillCellView.h"
#import "UITableViewCell+Nib.h"
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
#import "EUStorage.h"
#import "SkillPlannerSkillsBrowserViewController.h"

#define ActionButtonLevel1 NSLocalizedString(@"Train to Level 1", nil)
#define ActionButtonLevel2 NSLocalizedString(@"Train to Level 2", nil)
#define ActionButtonLevel3 NSLocalizedString(@"Train to Level 3", nil)
#define ActionButtonLevel4 NSLocalizedString(@"Train to Level 4", nil)
#define ActionButtonLevel5 NSLocalizedString(@"Train to Level 5", nil)
#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)

@interface SkillPlannerViewController()
@property (nonatomic, strong) SkillPlan* skillPlan;
@property (nonatomic, strong) NSIndexPath* modifiedIndexPath;

- (void) loadData;
- (void) didAddSkill:(NSNotification*) notification;
- (void) didChangeSkill:(NSNotification*) notification;
- (void) didRemoveSkill:(NSNotification*) notification;
- (void) didSelectAccount:(NSNotification*) notification;
- (void) reloadTrainingTime;
- (void) didUpdateCloud:(NSNotification*) notification;

@end

@implementation SkillPlannerViewController

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
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
	self.title = NSLocalizedString(@"Skill Planner", nil);
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
    // Do any additional setup after loading the view from its nib.
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAddSkill:) name:NotificationSkillPlanDidAddSkill object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeSkill:) name:NotificationSkillPlanDidChangeSkill object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRemoveSkill:) name:NotificationSkillPlanDidRemoveSkill object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:EVEAccountDidSelectNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateCloud:) name:NotificationSkillPlanDidImportFromCloud object:nil];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self loadData];
}

- (void)viewDidUnload
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self setTrainingTimeLabel:nil];
    [super viewDidUnload];
	self.skillPlan = nil;
	self.modifiedIndexPath = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	[self.tableView setEditing:editing animated:animated];
	//NSArray* clearRow = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:skillPlan.skills.count inSection:0]];
	NSIndexSet* section = [NSIndexSet indexSetWithIndex:1];
	if (editing)
		[self.tableView insertSections:section withRowAnimation:UITableViewRowAnimationFade];
	else {
		[self.tableView deleteSections:section withRowAnimation:UITableViewRowAnimationFade];
		[self.skillPlan save];
	}
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.editing ? 2 : 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return section == 0 ? self.skillPlan.skills.count : 4;
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
			cell.titleLabel.text = NSLocalizedString(@"Clear skill plan", nil);
			cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon77_12.png"];
		}
		else if (indexPath.row == 1) {
			cell.titleLabel.text = NSLocalizedString(@"Import skill plan from EVEMon", nil);
			cell.iconImageView.image = [UIImage imageNamed:@"EVEMonLogoBlue.png"];
		}
		else if (indexPath.row == 2) {
			cell.titleLabel.text = NSLocalizedString(@"Importing tutorial", nil);
			cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon74_14.png"];
		}
		else {
			cell.titleLabel.text = NSLocalizedString(@"Browse skills", nil);
			cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon50_12.png"];
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
		
		EVEDBInvTypeRequiredSkill* skill = [self.skillPlan.skills objectAtIndex:indexPath.row];
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
		cell.skillPointsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"SP: %@", nil), [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:skill.requiredSP] numberStyle:NSNumberFormatterDecimalStyle]];
		cell.levelLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Level %d", nil), skill.requiredLevel];
		NSTimeInterval trainingTime = (skill.requiredSP - skill.currentSP) / [self.skillPlan.characterAttributes skillpointsPerSecondForSkill:skill];
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

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
	if (proposedDestinationIndexPath.section > 0)
		proposedDestinationIndexPath = [NSIndexPath indexPathForRow:self.skillPlan.skills.count - 1 inSection:0];
	return proposedDestinationIndexPath;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    NSObject *objectToMove = [self.skillPlan.skills objectAtIndex:fromIndexPath.row];
    [self.skillPlan.skills removeObjectAtIndex:fromIndexPath.row];
    [self.skillPlan.skills insertObject:objectToMove atIndex:toIndexPath.row];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		[tableView beginUpdates];
		[self.skillPlan removeSkill:[self.skillPlan.skills objectAtIndex:indexPath.row]];
		[tableView endUpdates];
		//[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		[self reloadTrainingTime];
		[self.skillPlan save];
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
		EVEDBInvTypeRequiredSkill* skill = [self.skillPlan.skills objectAtIndex:indexPath.row];
		if (self.editing) {
			self.modifiedIndexPath = indexPath;
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
		}
		else {
			ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
			
			controller.type = skill;
			[controller setActivePage:ItemViewControllerActivePageInfo];
			
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
				UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
				navController.modalPresentationStyle = UIModalPresentationFormSheet;
				[self presentModalViewController:navController animated:YES];
			}
			else
				[self.navigationController pushViewController:controller animated:YES];
		}
	}
	else {
		if (indexPath.row == 0) {
			UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Clear skill plan?", nil)
																message:@""
															   delegate:self
													  cancelButtonTitle:NSLocalizedString(@"No", nil)
													  otherButtonTitles:NSLocalizedString(@"Yes", nil), nil];
			[alertView show];
		}
		else if (indexPath.row == 1) {
			SkillPlannerImportViewController* controller = [[SkillPlannerImportViewController alloc] initWithNibName:@"SkillPlannerImportViewController" bundle:nil];
			controller.delegate = self;
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
			navController.navigationBar.barStyle = UIBarStyleBlackOpaque;

			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
				navController.modalPresentationStyle = UIModalPresentationFormSheet;
			
			[self presentModalViewController:navController animated:YES];
		}
		else if (indexPath.row == 2) {
			BrowserViewController *controller = [[BrowserViewController alloc] initWithNibName:@"BrowserViewController" bundle:nil];
			NSString* path = [[NSBundle mainBundle] pathForResource:@"ImportingTutorial/index" ofType:@"html"];
			controller.title = NSLocalizedString(@"Importing tutorial", nil);
			controller.startPageURL = [NSURL fileURLWithPath:path];
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
				controller.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentModalViewController:controller animated:YES];
		}
		else {
			SkillPlannerSkillsBrowserViewController* controller = [[SkillPlannerSkillsBrowserViewController alloc] initWithNibName:@"SkillPlannerSkillsBrowserViewController" bundle:nil];
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
			navController.navigationBar.barStyle = self.navigationController.navigationBar.barStyle;
			
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
				navController.modalPresentationStyle = UIModalPresentationFormSheet;
			
			[self presentModalViewController:navController animated:YES];
		}
	}
}

#pragma mark UIActionSheetDelegate

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *button = [actionSheet buttonTitleAtIndex:buttonIndex];
	if ([button isEqualToString:ActionButtonCancel])
		return;
	
	NSInteger requiredLevel = 0;
	if ([button isEqualToString:ActionButtonLevel1])
		requiredLevel = 1;
	else if ([button isEqualToString:ActionButtonLevel2])
		requiredLevel = 2;
	else if ([button isEqualToString:ActionButtonLevel3])
		requiredLevel = 3;
	else if ([button isEqualToString:ActionButtonLevel4])
		requiredLevel = 4;
	else if ([button isEqualToString:ActionButtonLevel5])
		requiredLevel = 5;
	
	EVEDBInvTypeRequiredSkill* skill = [self.skillPlan.skills objectAtIndex:self.modifiedIndexPath.row];
	
	EVEDBInvTypeRequiredSkill* skillToDelete = nil;
	EVEDBInvTypeRequiredSkill* skillToInsert = nil;
	
	for (EVEDBInvTypeRequiredSkill* requiredSkill in self.skillPlan.skills) {
		if (requiredSkill.typeID == skill.typeID) {
			if (requiredSkill.requiredLevel > requiredLevel) {
				if (!skillToDelete)
					skillToDelete = requiredSkill;
				else if (skillToDelete.requiredLevel > requiredSkill.requiredLevel)
					skillToDelete = requiredSkill;
			}
			else if (requiredSkill.requiredLevel < requiredLevel) {
				if (!skillToInsert)
					skillToInsert = requiredSkill;
				else if (skillToInsert.requiredLevel < requiredSkill.requiredLevel)
					skillToInsert = requiredSkill;
			}
		}
	}
	
	if (skillToDelete) {
		[self.skillPlan removeSkill:skillToDelete];
	}
	else if (skillToInsert) {
		NSInteger index = [self.skillPlan.skills indexOfObject:skillToInsert];
		[self.tableView beginUpdates];
		EVECharacterSheetSkill *characterSkill = [self.skillPlan.characterSkills valueForKey:[NSString stringWithFormat:@"%d", skill.typeID]];
		for (NSInteger level = skillToInsert.requiredLevel + 1; level <= requiredLevel; level++) {
			if (characterSkill.level >= skill.requiredLevel)
				return;

			EVEDBInvTypeRequiredSkill* requiredSkill = [EVEDBInvTypeRequiredSkill invTypeWithTypeID:skill.typeID error:nil];
			requiredSkill.requiredLevel = level;
			requiredSkill.currentLevel = characterSkill.level;
			float sp = [requiredSkill skillPointsAtLevel:level - 1];
			requiredSkill.currentSP = MAX(sp, characterSkill.skillpoints);
			[self.skillPlan.skills insertObject:requiredSkill atIndex:++index];
			[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
		}
		[self.skillPlan resetTrainingTime];
		[self.tableView endUpdates];
		[self reloadTrainingTime];
	}
}

#pragma mark UIAlertViewDelegate

- (void) alertView:(UIAlertView *)aAlertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		[self.skillPlan clear];
		[self.skillPlan save];
		[self loadData];
	}
}

#pragma mark SkillPlannerImportViewControllerDelegate
- (void) skillPlannerImportViewController:(SkillPlannerImportViewController*) controller didSelectSkillPlan:(SkillPlan*) aSkillPlan {
	SkillPlan* currentSkillPlan = [[EVEAccount currentAccount] skillPlan];
	currentSkillPlan.skills = aSkillPlan.skills;
	[currentSkillPlan save];
	[self loadData];
}

#pragma mark - Private

- (void) loadData {
	__block EUOperation* operation = [EUOperation operationWithIdentifier:@"SkillPlannerViewController+Load" name:NSLocalizedString(@"Loading Skill Plan", nil)];
	__weak EUOperation* weakOperation = operation;
	__block SkillPlan* skillPlanTmp = nil;
	self.skillPlan = nil;
	[self.tableView reloadData];
	[operation addExecutionBlock:^(void) {
		EVEAccount *account = [EVEAccount currentAccount];
		if (!account)
			return;
		skillPlanTmp = account.skillPlan;
		
		NSError *error = nil;
		account.skillQueue = [EVESkillQueue skillQueueWithKeyID:account.charKeyID vCode:account.charVCode characterID:account.characterID error:&error progressHandler:nil];
		weakOperation.progress = 0.5;
		[skillPlanTmp trainingTime];
		weakOperation.progress = 1.0;
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.skillPlan = skillPlanTmp;

			[self.tableView reloadData];
			[self reloadTrainingTime];
		}
		else {
			self.skillPlan = nil;
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) didAddSkill:(NSNotification*) notification {
	if (notification.object == self.skillPlan) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadTrainingTime) object:nil];
		[self performSelector:@selector(reloadTrainingTime) withObject:nil afterDelay:0];
		[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:self.skillPlan.skills.count - 1 inSection:0]]
									withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (void) didChangeSkill:(NSNotification*) notification {
	if (notification.object == self.skillPlan) {
		[self reloadTrainingTime];
		EVEDBInvTypeRequiredSkill* skill = [notification.userInfo valueForKey:@"skill"];
		[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:[self.skillPlan.skills indexOfObject:skill] inSection:0]]
									withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (void) didRemoveSkill:(NSNotification*) notification {
	if (notification.object == self.skillPlan) {
		[self reloadTrainingTime];
		NSIndexSet* indexesSet = [notification.userInfo valueForKey:@"indexes"];
		NSMutableArray* indexes = [NSMutableArray array];
		[indexesSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
			[indexes addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
		}];
		[self.tableView deleteRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (void) didSelectAccount:(NSNotification*) notification {
	EVEAccount *account = [EVEAccount currentAccount];
	if (!account)
		[self.navigationController popToRootViewControllerAnimated:YES];
	else {
		self.skillPlan = nil;
		[self loadData];
	}
}

- (void) reloadTrainingTime {
	self.trainingTimeLabel.text = self.skillPlan.skills.count > 0 ? [NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:self.skillPlan.trainingTime]] : NSLocalizedString(@"Skill plan is empty", nil);
}

- (void) didUpdateCloud:(NSNotification*) notification {
	if (notification.object == self.skillPlan)
		[self loadData];
}

@end
