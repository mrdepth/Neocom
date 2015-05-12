//
//  NCSkillPlansViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 04.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCSkillPlansViewController.h"
#import "NCAccount.h"
#import "NCSkillPlan.h"
#import "NCStorage.h"
#import "NCTableViewCell.h"
#import "UIActionSheet+Block.h"
#import "UIAlertView+Block.h"
#import "NSString+Neocom.h"

@interface NCSkillPlansViewController ()
@property (nonatomic, strong) NSArray* skillPlans;
- (void) renameSkillPlanAtIndexPath:(NSIndexPath*) indexPath;
@end

@implementation NCSkillPlansViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.refreshControl = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillDisappear:(BOOL)animated {
	NCStorage* storage = [NCStorage sharedStorage];
	[storage saveContext];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.skillPlans.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row < self.skillPlans.count) {
		NCDefaultTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
		NCSkillPlan* skillPlan = self.skillPlans[indexPath.row];
		cell.object = skillPlan;
		cell.titleLabel.text = skillPlan.name.length > 0 ? skillPlan.name : NSLocalizedString(@"Unnamed", nil);
		cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ (%d skills)", nil), [NSString stringWithTimeLeft:skillPlan.trainingQueue.trainingTime], (int32_t) skillPlan.trainingQueue.skills.count];

		if (skillPlan.active)
			cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]];
		else
			cell.accessoryView = nil;
		return cell;
	}
	else
		return [tableView dequeueReusableCellWithIdentifier:@"AddCell" forIndexPath:indexPath];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		NSMutableArray* skillPlans = [self.skillPlans mutableCopy];
		NCSkillPlan* skillPlan = skillPlans[indexPath.row];
		BOOL active = skillPlan.active;
		
		NCStorage* storage = [NCStorage sharedStorage];
		NSManagedObjectContext* context = [NSThread isMainThread] ? storage.managedObjectContext : storage.backgroundManagedObjectContext;
		[context performBlockAndWait:^{
			[context deleteObject:skillPlan];
			[storage saveContext];
		}];
		
		[skillPlans removeObjectAtIndex:indexPath.row];
		self.skillPlans = skillPlans;
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
		if (active) {
			if (self.skillPlans.count > 0)
				[[NCAccount currentAccount] setActiveSkillPlan:self.skillPlans[0]];
			else {
				NCSkillPlan* skillPlan = [[NCSkillPlan alloc] initWithEntity:[NSEntityDescription entityForName:@"SkillPlan" inManagedObjectContext:storage.managedObjectContext]
								 insertIntoManagedObjectContext:storage.managedObjectContext];
				skillPlan.active = YES;
				skillPlan.account = [NCAccount currentAccount];
				skillPlan.name = NSLocalizedString(@"Default Skill Plan", nil);

				[[NCAccount currentAccount] setActiveSkillPlan:skillPlan];
			}
		}
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
		NSMutableArray* skillPlans = [self.skillPlans mutableCopy];
		NCStorage* storage = [NCStorage sharedStorage];
		NSManagedObjectContext* context = [NSThread isMainThread] ? storage.managedObjectContext : storage.backgroundManagedObjectContext;
		[context performBlockAndWait:^{
			NCSkillPlan* skillPlan = [[NCSkillPlan alloc] initWithEntity:[NSEntityDescription entityForName:@"SkillPlan" inManagedObjectContext:context]
										  insertIntoManagedObjectContext:context];
			skillPlan.name = NSLocalizedString(@"Skill Plan", nil);
			skillPlan.account = [NCAccount currentAccount];
			[skillPlans addObject:skillPlan];
		}];
		self.skillPlans = skillPlans;
		[tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
		[self renameSkillPlanAtIndexPath:indexPath];
    }
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == self.skillPlans.count)
		return 37;
	else
		return 42;
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.row < self.skillPlans.count ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleInsert;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == self.skillPlans.count) {
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		[self tableView:tableView commitEditingStyle:UITableViewCellEditingStyleInsert forRowAtIndexPath:indexPath];
	}
	else {
		NCTableViewCell* cell = (NCTableViewCell*) [tableView cellForRowAtIndexPath:indexPath];
		[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackTranslucent
									   title:nil
						   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
					  destructiveButtonTitle:NSLocalizedString(@"Delete", nil)
						   otherButtonTitles:@[NSLocalizedString(@"Rename", nil), NSLocalizedString(@"Switch", nil)]
							 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
								 [tableView deselectRowAtIndexPath:indexPath animated:YES];
								 if (selectedButtonIndex == 0)
									 [self tableView:tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:indexPath];
								 else if (selectedButtonIndex == 1) {
									 [self renameSkillPlanAtIndexPath:indexPath];
								 }
								 else if (selectedButtonIndex == 2) {
									 [[NCAccount currentAccount] setActiveSkillPlan:cell.object];
									 [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
								 }
							 }
								 cancelBlock:^{
									 [tableView deselectRowAtIndexPath:indexPath animated:YES];
								 }] showFromRect:cell.bounds inView:cell animated:YES];
	}
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (void) update {
	//self.skillPlans = [[[NCAccount currentAccount] skillPlans] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
	NCAccount* account = [NCAccount currentAccount];
	[super update];
	__block NSArray* skillPlans = nil;
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NCStorage* storage = [NCStorage sharedStorage];
											 NSManagedObjectContext* context = [NSThread isMainThread] ? storage.managedObjectContext : storage.backgroundManagedObjectContext;
											 [context performBlockAndWait:^{
												skillPlans = [[account skillPlans] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
											 }];
											 for (NCSkillPlan* skillPlan in skillPlans)
												 [skillPlan.trainingQueue trainingTime];
											 
										 }
							 completionHandler:^(NCTask *task) {
								 self.skillPlans = skillPlans;
								 [self.tableView reloadData];
							 }];
}

- (void) didChangeAccount:(NCAccount *)account {
	[super didChangeAccount:account];
	if ([self isViewLoaded])
		[self update];
}

- (void) didChangeStorage {
	if ([self isViewLoaded])
		[self update];
}

#pragma mark - Private

- (void) renameSkillPlanAtIndexPath:(NSIndexPath*) indexPath {
	NCTableViewCell* cell = (NCTableViewCell*) [self.tableView cellForRowAtIndexPath:indexPath];
	NCSkillPlan* skillPlan = cell.object;

	UIAlertView* alertView = [UIAlertView alertViewWithTitle:NSLocalizedString(@"Rename", nil)
													 message:nil
										   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
										   otherButtonTitles:@[NSLocalizedString(@"Rename", nil)]
											 completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
												 if (selectedButtonIndex != alertView.cancelButtonIndex) {
													 UITextField* textField = [alertView textFieldAtIndex:0];
													 skillPlan.name = textField.text;
													 [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
												 }
											 } cancelBlock:nil];
	alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
	UITextField* textField = [alertView textFieldAtIndex:0];
	textField.text = skillPlan.name;
	[alertView show];
}

@end
