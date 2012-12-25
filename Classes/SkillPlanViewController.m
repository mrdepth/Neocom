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
#import "ItemCellView.h"
#import "Globals.h"
#import "SkillPlannerImportViewController.h"

#define ActionButtonLevel1 NSLocalizedString(@"Train to Level 1", nil)
#define ActionButtonLevel2 NSLocalizedString(@"Train to Level 2", nil)
#define ActionButtonLevel3 NSLocalizedString(@"Train to Level 3", nil)
#define ActionButtonLevel4 NSLocalizedString(@"Train to Level 4", nil)
#define ActionButtonLevel5 NSLocalizedString(@"Train to Level 5", nil)
#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)

@interface SkillPlanViewController(Private)

- (void) loadData;

@end

@implementation SkillPlanViewController
@synthesize skillsTableView;
@synthesize trainingTimeLabel;
@synthesize skillPlanPath;
@synthesize skillPlannerImportViewController;
@synthesize skillPlan;

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
	[skillsTableView release];
	[skillPlan release];
	[trainingTimeLabel release];
	[skillPlanPath release];
	[super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	//self.title = [[skillPlanPath lastPathComponent] stringByDeletingPathExtension];
	self.title = skillPlan.name;
	trainingTimeLabel.text = skillPlan.skills.count > 0 ? [NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:skillPlan.trainingTime]] : NSLocalizedString(@"Skill plan is empty", nil);

	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Import", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onImport:)] autorelease];
	//self.navigationItem.rightBarButtonItem.enabled = NO;
//	[self loadData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	[self setTrainingTimeLabel:nil];
	self.skillsTableView = nil;
	[skillPlan release];
	skillPlan = nil;
}

- (IBAction)onImport:(id)sender {
	UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Import", nil)
														message:NSLocalizedString(@"Do you wish to replace or merge the existing skill plan with imported skill plan?", nil)
													   delegate:self
											  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
											  otherButtonTitles:NSLocalizedString(@"Replace", nil), NSLocalizedString(@"Merge", nil), nil];
	[alertView show];
	[alertView autorelease];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return skillPlan.skills.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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
	cell.skillPointsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"SP: %@", nil), [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:skill.requiredSP] numberStyle:NSNumberFormatterDecimalStyle]];
	cell.levelLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Level %d", nil), skill.requiredLevel];
	NSTimeInterval trainingTime = (skill.requiredSP - skill.currentSP) / [skillPlan.characterAttributes skillpointsPerSecondForSkill:skill];
	cell.remainingLabel.text = [NSString stringWithTimeLeft:trainingTime];
	return cell;
}

#pragma mark -
#pragma mark Table view delegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	EVEDBInvType* skill = [skillPlan.skills objectAtIndex:indexPath.row];
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	
	controller.type = skill;
	[controller setActivePage:ItemViewControllerActivePageInfo];
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

#pragma mark UIAlertViewDelegate

- (void) alertView:(UIAlertView *)aAlertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		[skillPlannerImportViewController.delegate skillPlannerImportViewController:skillPlannerImportViewController didSelectSkillPlan:skillPlan];
		[self dismissModalViewControllerAnimated:YES];
	}
	else if (buttonIndex == 2) {
		__block EUOperation* operation = [EUOperation operationWithIdentifier:@"SkillPlanViewController+Merge" name:NSLocalizedString(@"Merging Skill Plans", nil)];
		__block SkillPlan* skillPlanTmp = nil;
		[operation addExecutionBlock:^(void) {
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			EVEAccount *account = [EVEAccount currentAccount];
			if (!account) {
				[pool release];
				return;
			}
			skillPlanTmp = [[SkillPlan skillPlanWithAccount:account] retain];
			for (EVEDBInvTypeRequiredSkill* skill in account.skillPlan.skills)
				[skillPlanTmp addSkill:skill];
			operation.progress = 0.3;
			
			for (EVEDBInvTypeRequiredSkill* skill in skillPlan.skills)
				[skillPlanTmp addSkill:skill];
			operation.progress = 0.6;
			
			[skillPlanTmp trainingTime];
			operation.progress = 1.0;
			[pool release];
		}];
		
		[operation setCompletionBlockInCurrentThread:^(void) {
			if (![operation isCancelled]) {
				[skillPlannerImportViewController.delegate skillPlannerImportViewController:skillPlannerImportViewController didSelectSkillPlan:skillPlanTmp];
				[self dismissModalViewControllerAnimated:YES];
			}
			[skillPlanTmp release];
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
}

@end


@implementation SkillPlanViewController(Private)

- (void) loadData {
	__block EUOperation* operation = [EUOperation operationWithIdentifier:@"SkillPlanViewController+Load" name:NSLocalizedString(@"Updating Training Time", nil)];
	__block SkillPlan* skillPlanTmp = nil;
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		EVEAccount *account = [EVEAccount currentAccount];
		if (!account) {
			[pool release];
			return;
		}
		//skillPlanTmp = [[SkillPlan alloc] initWithAccount:account eveMonSkillPlanPath:skillPlanPath];
		
		//[skillPlanTmp trainingTime];
		[skillPlan trainingTime];
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		[skillPlan release];
		if (![operation isCancelled]) {
			skillPlan = skillPlanTmp;
			trainingTimeLabel.text = skillPlan.skills.count > 0 ? [NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:skillPlan.trainingTime]] : NSLocalizedString(@"Skill plan is empty", nil);
			
			[skillsTableView reloadData];
			self.navigationItem.rightBarButtonItem.enabled = YES;
		}
		else {
			skillPlan = nil;
			[skillPlanTmp release];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end
