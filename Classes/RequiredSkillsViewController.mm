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
#import "Fit.h"
#import "ItemInfo.h"
#import "Globals.h"

#define ActionButtonLevel1 @"Train to Level 1"
#define ActionButtonLevel2 @"Train to Level 2"
#define ActionButtonLevel3 @"Train to Level 3"
#define ActionButtonLevel4 @"Train to Level 4"
#define ActionButtonLevel5 @"Train to Level 5"
#define ActionButtonCancel @"Cancel"

@interface RequiredSkillsViewController(Private)

- (void) loadData;

@end

@implementation RequiredSkillsViewController
@synthesize skillsTableView;
@synthesize trainingTimeLabel;
@synthesize fit;

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
	[trainingTimeLabel release];
	[skillPlan release];
	[fit release];
	[super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = @"Required Skills";
	[self loadData];
	[self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(onClose:)] autorelease]];
	if ([[EVEAccount currentAccount] skillPlan])
		[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:@"Learn" style:UIBarButtonItemStyleBordered target:self action:@selector(onAddToSkillPlan:)] autorelease]];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewDidUnload
{
	[self setTrainingTimeLabel:nil];
    [super viewDidUnload];
	self.skillsTableView = nil;
	[skillPlan release];
	skillPlan = nil;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction) onClose:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)onAddToSkillPlan:(id)sender {
	UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Add to skill plan?"
														message:[NSString stringWithFormat:@"Training time: %@", [NSString stringWithTimeLeft:skillPlan.trainingTime]]
													   delegate:self
											  cancelButtonTitle:@"No"
											  otherButtonTitles:@"Yes", nil];
	[alertView show];
	[alertView autorelease];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return skillPlan.skills.count + (self.editing ? 1 : 0);
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
	cell.skillPointsLabel.text = [NSString stringWithFormat:@"SP: %@", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:skill.requiredSP] numberStyle:NSNumberFormatterDecimalStyle]];
	cell.levelLabel.text = [NSString stringWithFormat:@"Level %d", skill.requiredLevel];
	NSTimeInterval trainingTime = (skill.requiredSP - skill.currentSP) / [skillPlan.characterAttributes skillpointsPerSecondForSkill:skill];
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
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"ItemViewController-iPad" : @"ItemViewController")
																		  bundle:nil];
	
	EVEDBInvTypeRequiredSkill* skill = [skillPlan.skills objectAtIndex:indexPath.row];
	controller.type = skill;
	[controller setActivePage:ItemViewControllerActivePageInfo];
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

#pragma mark UIAlertViewDelegate

- (void) alertView:(UIAlertView *)aAlertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		SkillPlan* currentSkillPlan = [[EVEAccount currentAccount] skillPlan];
		if (currentSkillPlan) {
			for (EVEDBInvTypeRequiredSkill* skill in skillPlan.skills)
				[currentSkillPlan addSkill:skill];
			[currentSkillPlan save];
			UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Skill plan updated"
																message:[NSString stringWithFormat:@"Total training time: %@", [NSString stringWithTimeLeft:currentSkillPlan.trainingTime]]
															   delegate:nil
													  cancelButtonTitle:@"Ok"
													  otherButtonTitles:nil];
			[alertView show];
			[alertView autorelease];
		}
	}
}

@end


@implementation RequiredSkillsViewController(Private)

- (void) loadData {
	__block EUOperation* operation = [EUOperation operationWithIdentifier:@"RequiredSkillsViewController+Load" name:@"Loading Requirements"];
	__block SkillPlan* skillPlanTmp = nil;
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		skillPlanTmp = [[SkillPlan alloc] init];
		EVEAccount* account = [EVEAccount currentAccount];
		if (account) {
			skillPlanTmp.characterSkills = account.characterSheet.skillsMap;
			skillPlanTmp.characterAttributes = account.characterAttributes;
		}
		
		eufe::Character* character = fit.character;

		[skillPlanTmp addType:[ItemInfo itemInfoWithItem:character->getShip() error:nil]];
		operation.progress = 0.25;
		{
			const eufe::ModulesList& modules = character->getShip()->getModules();
			eufe::ModulesList::const_iterator i, end = modules.end();
			for (i = modules.begin(); i != end; i++) {
				[skillPlanTmp addType:[ItemInfo itemInfoWithItem:*i error:nil]];
				if ((*i)->getCharge() != NULL)
					[skillPlanTmp addType:[ItemInfo itemInfoWithItem:(*i)->getCharge() error:nil]];
			}
		}
		operation.progress = 0.5;

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
		operation.progress = 0.75;

		{
			const eufe::BoostersList& boosters = character->getBoosters();
			eufe::BoostersList::const_iterator i, end = boosters.end();
			for (i = boosters.begin(); i != end; i++) {
				[skillPlanTmp addType:[ItemInfo itemInfoWithItem:*i error:nil]];
			}
		}
	
		[skillPlanTmp trainingTime];
		operation.progress = 1.0;
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		[skillPlan release];
		if (![operation isCancelled]) {
			skillPlan = skillPlanTmp;
			
			[skillsTableView reloadData];
			trainingTimeLabel.text = skillPlan.skills.count > 0 ? [NSString stringWithFormat:@"Training time: %@", [NSString stringWithTimeLeft:skillPlan.trainingTime]] : @"Skill plan is empty";
		}
		else {
			skillPlan = nil;
			[skillPlanTmp release];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end
