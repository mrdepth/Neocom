//
//  RequiredSkillsViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 2/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RequiredSkillsViewController.h"
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
#import "ShipFit.h"
#import "ItemInfo.h"
#import "Globals.h"

#define ActionButtonLevel1 NSLocalizedString(@"Train to Level 1", nil)
#define ActionButtonLevel2 NSLocalizedString(@"Train to Level 2", nil)
#define ActionButtonLevel3 NSLocalizedString(@"Train to Level 3", nil)
#define ActionButtonLevel4 NSLocalizedString(@"Train to Level 4", nil)
#define ActionButtonLevel5 NSLocalizedString(@"Train to Level 5", nil)
#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)

@interface RequiredSkillsViewController()
@property (nonatomic, strong) SkillPlan* skillPlan;

- (void) loadData;

@end

@implementation RequiredSkillsViewController

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
	self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
	self.title = NSLocalizedString(@"Required Skills", nil);
	[self loadData];
	[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onClose:)]];
	if ([[EVEAccount currentAccount] skillPlan])
		[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Learn", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onAddToSkillPlan:)]];
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

- (void)viewDidUnload
{
	[self setTrainingTimeLabel:nil];
    [super viewDidUnload];
	self.skillPlan = nil;
}

- (IBAction) onClose:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)onAddToSkillPlan:(id)sender {
	UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add to skill plan?", nil)
														message:[NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:self.skillPlan.trainingTime]]
													   delegate:self
											  cancelButtonTitle:NSLocalizedString(@"No", nil)
											  otherButtonTitles:NSLocalizedString(@"Yes", nil), nil];
	[alertView show];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.skillPlan.skills.count + (self.editing ? 1 : 0);
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
	return cell;
}

#pragma mark -
#pragma mark Table view delegate


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	
	EVEDBInvTypeRequiredSkill* skill = [self.skillPlan.skills objectAtIndex:indexPath.row];
	controller.type = skill;
	[controller setActivePage:ItemViewControllerActivePageInfo];
	[self.navigationController pushViewController:controller animated:YES];
}

#pragma mark UIAlertViewDelegate

- (void) alertView:(UIAlertView *)aAlertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		SkillPlan* currentSkillPlan = [[EVEAccount currentAccount] skillPlan];
		if (currentSkillPlan) {
			for (EVEDBInvTypeRequiredSkill* skill in self.skillPlan.skills)
				[currentSkillPlan addSkill:skill];
			[currentSkillPlan save];
			UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Skill plan updated", nil)
																message:[NSString stringWithFormat:NSLocalizedString(@"Total training time: %@", nil), [NSString stringWithTimeLeft:currentSkillPlan.trainingTime]]
															   delegate:nil
													  cancelButtonTitle:@"Ok"
													  otherButtonTitles:nil];
			[alertView show];
		}
	}
}

#pragma mark - Private

- (void) loadData {
	__block EUOperation* operation = [EUOperation operationWithIdentifier:@"RequiredSkillsViewController+Load" name:NSLocalizedString(@"Loading Requirements", nil)];
	__weak EUOperation* weakOperation = operation;
	__block SkillPlan* skillPlanTmp = nil;
	[operation addExecutionBlock:^(void) {
		skillPlanTmp = [[SkillPlan alloc] init];
		EVEAccount* account = [EVEAccount currentAccount];
		if (account) {
			skillPlanTmp.characterSkills = account.characterSheet.skillsMap;
			skillPlanTmp.characterAttributes = account.characterAttributes;
		}
		
		eufe::Character* character = self.fit.character;

		[skillPlanTmp addType:[ItemInfo itemInfoWithItem:character->getShip() error:nil]];
		weakOperation.progress = 0.25;
		{
			const eufe::ModulesList& modules = character->getShip()->getModules();
			eufe::ModulesList::const_iterator i, end = modules.end();
			for (i = modules.begin(); i != end; i++) {
				[skillPlanTmp addType:[ItemInfo itemInfoWithItem:*i error:nil]];
				if ((*i)->getCharge() != NULL)
					[skillPlanTmp addType:[ItemInfo itemInfoWithItem:(*i)->getCharge() error:nil]];
			}
		}
		weakOperation.progress = 0.5;

		{
			const eufe::DronesList& drones = character->getShip()->getDrones();
			eufe::DronesList::const_iterator i, end = drones.end();
			for (i = drones.begin(); i != end; i++) {
				[skillPlanTmp addType:[ItemInfo itemInfoWithItem:*i error:nil]];
			}
		}

		{
			const eufe::ImplantsList& implants = character->getImplants();
			eufe::ImplantsList::const_iterator i, end = implants.end();
			for (i = implants.begin(); i != end; i++) {
				[skillPlanTmp addType:[ItemInfo itemInfoWithItem:*i error:nil]];
			}
		}
		weakOperation.progress = 0.75;

		{
			const eufe::BoostersList& boosters = character->getBoosters();
			eufe::BoostersList::const_iterator i, end = boosters.end();
			for (i = boosters.begin(); i != end; i++) {
				[skillPlanTmp addType:[ItemInfo itemInfoWithItem:*i error:nil]];
			}
		}
	
		[skillPlanTmp trainingTime];
		weakOperation.progress = 1.0;
	}];
	
	[weakOperation setCompletionBlockInMainThread:^(void) {
		if (![operation isCancelled]) {
			self.skillPlan = skillPlanTmp;
			
			[self.tableView reloadData];
			self.trainingTimeLabel.text = self.skillPlan.skills.count > 0 ? [NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:self.skillPlan.trainingTime]] : NSLocalizedString(@"Skill plan is empty", nil);
		}
		else {
			self.skillPlan = nil;
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end
