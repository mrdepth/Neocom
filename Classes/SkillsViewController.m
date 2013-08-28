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
#import "appearance.h"
#import "RoundRectButton.h"
#import "UIActionSheet+Block.h"

/*@interface Skill : NSObject

@property (nonatomic, strong) NSString *skillName;
@property (nonatomic, strong) NSString *skillPoints;
@property (nonatomic, strong) NSString *level;
@property (nonatomic, strong) NSString *iconImageName;
@property (nonatomic, strong) NSString *levelImageName;
@property (nonatomic, strong) NSString *remainingTime;
@property (nonatomic, assign) NSInteger typeID;
@property (nonatomic, assign) NSInteger targetLevel;
@property (nonatomic, assign) NSInteger startSkillPoints;
@property (nonatomic, assign) NSInteger targetSkillPoints;

@end


@implementation Skill

- (NSComparisonResult) compare:(Skill*) other {
	return [self.skillName compare:other.skillName];
}

@end*/

/*NSComparisonResult compare(NSArray *a, NSArray *b, void* context) {
 return [[[[[a objectAtIndex:0] skill] group] groupName] compare:[[[[b objectAtIndex:0] skill] group] groupName]];
 }*/

@interface SkillsViewController()
@property (nonatomic, strong) NSArray *skillGroups;
@property (nonatomic, strong) NSMutableArray *skillQueue;
@property (nonatomic, strong) NSString *skillQueueTitle;

- (void) didSelectAccount:(NSNotification*) notification;
@end


@implementation SkillsViewController

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
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
    [super viewDidLoad];
	self.title = NSLocalizedString(@"Skills", nil);
	
	self.navigationItem.rightBarButtonItems = @[self.editButtonItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(onAction:)]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:EVEAccountDidSelectNotification object:nil];

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.navigationItem.titleView = self.segmentedControl;
		self.skillsDataSource.account = [EVEAccount currentAccount];
		self.skillsDataSource.mode = SkillsDataSourceModeKnownSkills;
		[self.skillsDataSource reload];
		
		self.skillQueueDataSource.account = [EVEAccount currentAccount];
		self.skillQueueDataSource.mode = SkillsDataSourceModeSkillPlanner;
		[self.skillQueueDataSource reload];

	}
	else {
		self.navigationItem.titleView = self.modeButton;
		self.skillsDataSource.account = [EVEAccount currentAccount];
		self.skillsDataSource.mode = SkillsDataSourceModeSkillPlanner;
		[self.skillsDataSource reload];
	}
	
	
	

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:YES];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.skillsQueueTableView setEditing:editing animated:animated];
	else
		[self.skillsTableView setEditing:editing animated:animated];
}

- (IBAction) onMode:(id)sender {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		switch (self.segmentedControl.selectedSegmentIndex) {
			case 0:
				self.skillsDataSource.mode = SkillsDataSourceModeKnownSkills;
				break;
			case 1:
				self.skillsDataSource.mode = SkillsDataSourceModeAllSkills;
				break;
			case 2:
				self.skillsDataSource.mode = SkillsDataSourceModeNotKnownSkills;
				break;
			case 3:
				self.skillsDataSource.mode = SkillsDataSourceModeCanTrain;
				break;
			default:
				break;
		}
	}
	else {
		[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackOpaque
									   title:nil
						   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
					  destructiveButtonTitle:nil
						   otherButtonTitles:@[NSLocalizedString(@"Skill Queue", nil), NSLocalizedString(@"My Skills", nil), NSLocalizedString(@"All Skills", nil), NSLocalizedString(@"Not Known", nil), NSLocalizedString(@"Can Train", nil)]
							 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
								 if (selectedButtonIndex == actionSheet.cancelButtonIndex)
									 return;
								 
								 [self.modeButton setTitle:[actionSheet buttonTitleAtIndex:selectedButtonIndex] forState:UIControlStateNormal];
								 [self.modeButton setTitle:[actionSheet buttonTitleAtIndex:selectedButtonIndex] forState:UIControlStateHighlighted];
								 switch (selectedButtonIndex) {
									 case 0:
										 self.skillsDataSource.mode = SkillsDataSourceModeSkillPlanner;
										 [self.navigationItem setRightBarButtonItems:@[self.editButtonItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(onAction:)]]
																			animated:YES];
										 break;
									 case 1:
										 self.skillsDataSource.mode = SkillsDataSourceModeKnownSkills;
										 [self.navigationItem setRightBarButtonItems:nil animated:YES];
										 break;
									 case 2:
										 self.skillsDataSource.mode = SkillsDataSourceModeAllSkills;
										 [self.navigationItem setRightBarButtonItems:nil animated:YES];
										 break;
									 case 3:
										 self.skillsDataSource.mode = SkillsDataSourceModeNotKnownSkills;
										 [self.navigationItem setRightBarButtonItems:nil animated:YES];
										 break;
									 case 4:
										 self.skillsDataSource.mode = SkillsDataSourceModeCanTrain;
										 [self.navigationItem setRightBarButtonItems:nil animated:YES];
										 break;
									 default:
										 break;
								 }
							 } cancelBlock:nil] showFromRect:[sender bounds] inView:sender animated:YES];
	}
}

- (IBAction) onAction:(id)sender {
	[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackOpaque
								   title:nil
					   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
				  destructiveButtonTitle:NSLocalizedString(@"Clear Skill Plan", nil)
					   otherButtonTitles:@[NSLocalizedString(@"Import Skill Plan", nil)]
						 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
							 if (selectedButtonIndex == actionSheet.destructiveButtonIndex) {
								 if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
									 [self.skillQueueDataSource.account.skillPlan clear];
									 [self.skillQueueDataSource.account.skillPlan save];
									 [self.skillQueueDataSource reload];
								 }
								 else {
									 [self.skillsDataSource.account.skillPlan clear];
									 [self.skillsDataSource.account.skillPlan save];
									 [self.skillsDataSource reload];
								 }
							 }
							 else if (selectedButtonIndex == 1) {
								 SkillPlannerImportViewController* controller = [[SkillPlannerImportViewController alloc] initWithNibName:@"SkillPlannerImportViewController" bundle:nil];
								 controller.delegate = self;
								 UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
								 navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
								 
								 if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
									 navController.modalPresentationStyle = UIModalPresentationFormSheet;
								 [self presentViewController:navController animated:YES completion:nil];
							 }
						 } cancelBlock:nil] showFromBarButtonItem:sender animated:YES];
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 22;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
	view.titleLabel.text = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];
	return view;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	EVEDBInvType* skill = [(SkillsDataSource*) tableView.dataSource skillAtIndexPath:indexPath];
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	
	controller.type = [EVEDBInvType invTypeWithTypeID:skill.typeID error:nil];
	[controller setActivePage:ItemViewControllerActivePageInfo];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
		[self presentViewController:navController animated:YES completion:nil];
	}
	else
		[self.navigationController pushViewController:controller animated:YES];
}

#pragma mark SkillPlannerImportViewControllerDelegate
- (void) skillPlannerImportViewController:(SkillPlannerImportViewController*) controller didSelectSkillPlan:(SkillPlan*) aSkillPlan {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.skillQueueDataSource.account.skillPlan.skills = aSkillPlan.skills;
		[self.skillQueueDataSource reload];
	}
	else {
		self.skillsDataSource.account.skillPlan.skills = aSkillPlan.skills;
		[self.skillsDataSource reload];
	}
}

#pragma mark - Private

- (void) didSelectAccount:(NSNotification*) notification {
	EVEAccount* account = [EVEAccount currentAccount];
	self.skillsDataSource.account = account;
	self.skillQueueDataSource.account = account;
	[self.skillsDataSource reload];
	[self.skillQueueDataSource reload];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if (!account)
			[self.navigationItem setRightBarButtonItems:nil animated:YES];
		else if (!self.navigationItem.rightBarButtonItems)
			[self.navigationItem setRightBarButtonItems:@[self.editButtonItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(onAction:)]]
											   animated:YES];
	}
	else
		[self.navigationController popToRootViewControllerAnimated:YES];
}

@end
