//
//  SkillPlanViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 2/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SkillPlanViewController.h"
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
#import "Globals.h"
#import "SkillPlannerImportViewController.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"
#import "appearance.h"

#define ActionButtonLevel1 NSLocalizedString(@"Train to Level 1", nil)
#define ActionButtonLevel2 NSLocalizedString(@"Train to Level 2", nil)
#define ActionButtonLevel3 NSLocalizedString(@"Train to Level 3", nil)
#define ActionButtonLevel4 NSLocalizedString(@"Train to Level 4", nil)
#define ActionButtonLevel5 NSLocalizedString(@"Train to Level 5", nil)
#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)

@interface SkillPlanViewController()
@property (nonatomic, strong) NSString* headerTitle;
- (void) loadData;

@end

@implementation SkillPlanViewController

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

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	self.title = self.skillPlan.name;
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Import", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onImport:)];
	//self.navigationItem.rightBarButtonItem.enabled = NO;
//	[self loadData];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (IBAction)onImport:(id)sender {
	UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Import", nil)
														message:NSLocalizedString(@"Do you wish to replace or merge the existing skill plan with imported skill plan?", nil)
													   delegate:self
											  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
											  otherButtonTitles:NSLocalizedString(@"Replace", nil), NSLocalizedString(@"Merge", nil), nil];
	[alertView show];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.skillPlan.skills.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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
	
	GroupedCellGroupStyle groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = groupStyle;
	
	return cell;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return self.headerTitle;
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	if (title) {
		CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
		view.titleLabel.text = title;
		view.collapsImageView.hidden = YES;
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
	EVEDBInvType* skill = [self.skillPlan.skills objectAtIndex:indexPath.row];
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	
	controller.type = skill;
	[controller setActivePage:ItemViewControllerActivePageInfo];
	[self.navigationController pushViewController:controller animated:YES];
}

#pragma mark UIAlertViewDelegate

- (void) alertView:(UIAlertView *)aAlertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		[self.skillPlannerImportViewController.delegate skillPlannerImportViewController:self.skillPlannerImportViewController didSelectSkillPlan:self.skillPlan];
		[self dismissViewControllerAnimated:YES completion:nil];
	}
	else if (buttonIndex == 2) {
		EUOperation* operation = [EUOperation operationWithIdentifier:@"SkillPlanViewController+Merge" name:NSLocalizedString(@"Merging Skill Plans", nil)];
		__weak EUOperation* weakOperation = operation;
		__block SkillPlan* skillPlanTmp = nil;
		[operation addExecutionBlock:^(void) {
			EVEAccount *account = [EVEAccount currentAccount];
			if (!account)
				return;
			skillPlanTmp = [SkillPlan skillPlanWithAccount:account name:@"main"];
			for (EVEDBInvTypeRequiredSkill* skill in account.skillPlan.skills)
				[skillPlanTmp addSkill:skill];
			weakOperation.progress = 0.3;
			
			for (EVEDBInvTypeRequiredSkill* skill in self.skillPlan.skills)
				[skillPlanTmp addSkill:skill];
			weakOperation.progress = 0.6;
			
			[skillPlanTmp trainingTime];
			weakOperation.progress = 1.0;
		}];
		
		[operation setCompletionBlockInMainThread:^(void) {
			if (![weakOperation isCancelled]) {
				[self.skillPlannerImportViewController.delegate skillPlannerImportViewController:self.skillPlannerImportViewController didSelectSkillPlan:skillPlanTmp];
				[self dismissViewControllerAnimated:YES completion:nil];
			}
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
}

#pragma mark - Private

- (void) loadData {
	EUOperation* operation = [EUOperation operationWithIdentifier:@"SkillPlanViewController+Load" name:NSLocalizedString(@"Updating Training Time", nil)];
	__weak EUOperation* weakOperation = operation;
	__block SkillPlan* skillPlanTmp = nil;
	[operation addExecutionBlock:^(void) {
		EVEAccount *account = [EVEAccount currentAccount];
		if (!account)
			return;
		//skillPlanTmp = [[SkillPlan alloc] initWithAccount:account eveMonSkillPlanPath:skillPlanPath];
		
		[skillPlanTmp trainingTime];
		//[skillPlan trainingTime];
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.skillPlan = skillPlanTmp;
			self.headerTitle = self.skillPlan.skills.count > 0 ? [NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:self.skillPlan.trainingTime]] : NSLocalizedString(@"Skill plan is empty", nil);
			
			[self.tableView reloadData];
			self.navigationItem.rightBarButtonItem.enabled = YES;
		}
		else {
			self.skillPlan = nil;
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end
