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
#import "NSString+Neocom.h"

@interface NCSkillPlansViewControllerRow : NSObject
@property (nonatomic, strong) NCSkillPlan* skillPlan;
@property (nonatomic, strong) NCTrainingQueue* trainingQueue;
@property (nonatomic, strong) NSString* skillPlanName;
@property (nonatomic, assign) BOOL active;
@end

@implementation NCSkillPlansViewControllerRow
@end

@interface NCSkillPlansViewController ()
@property (nonatomic, strong) NSArray* rows;
@property (nonatomic, strong) NCAccount* account;
- (void) renameSkillPlanAtIndexPath:(NSIndexPath*) indexPath;
- (void) reload;
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
	self.account = [NCAccount currentAccount];
	[self reload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self.account.managedObjectContext performBlock:^{
		if ([self.account.managedObjectContext hasChanges])
			[self.account.managedObjectContext save:nil];
	}];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.rows.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row < self.rows.count) {
		NCDefaultTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
		NCSkillPlansViewControllerRow* row = self.rows[indexPath.row];
		cell.object = row;
		cell.titleLabel.text = row.skillPlanName.length > 0 ? row.skillPlanName : NSLocalizedString(@"Unnamed", nil);
		cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ (%d skills)", nil), [NSString stringWithTimeLeft:row.trainingQueue.trainingTime], (int32_t) row.trainingQueue.skills.count];
		cell.accessoryView = row.active ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]] : nil;
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
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		NSMutableArray* rows = [self.rows mutableCopy];
		NCSkillPlansViewControllerRow* row = rows[indexPath.row];
		BOOL active = row.active;
		
		NSManagedObjectContext* context = row.skillPlan.managedObjectContext;
		[context performBlock:^{
			[context deleteObject:row.skillPlan];
			[context save:nil];
		}];
		
		[rows removeObjectAtIndex:indexPath.row];
		self.rows = rows;
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
		if (active) {
			if (self.rows.count > 0) {
				[self.rows[0] setActive:YES];
				[context performBlock:^{
					[[NCAccount currentAccount] setActiveSkillPlan:[self.rows[0] skillPlan]];
				}];
			}
			else {
				[context performBlock:^{
					NCSkillPlan* skillPlan = [[NCSkillPlan alloc] initWithEntity:[NSEntityDescription entityForName:@"SkillPlan" inManagedObjectContext:context]
												  insertIntoManagedObjectContext:context];
					skillPlan.active = YES;
					skillPlan.account = self.account;
					skillPlan.name = NSLocalizedString(@"Default Skill Plan", nil);
					
					[self.account setActiveSkillPlan:skillPlan];
				}];
			}
		}
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
		NSMutableArray* rows = [self.rows mutableCopy];
		NSManagedObjectContext* context = self.account.managedObjectContext;
		[context performBlock:^{
			NCSkillPlan* skillPlan = [[NCSkillPlan alloc] initWithEntity:[NSEntityDescription entityForName:@"SkillPlan" inManagedObjectContext:context]
										  insertIntoManagedObjectContext:context];
			skillPlan.name = NSLocalizedString(@"Skill Plan", nil);
			skillPlan.account = [NCAccount currentAccount];
			
			NCSkillPlansViewControllerRow* row = [NCSkillPlansViewControllerRow new];
			[rows addObject:row];
			row.skillPlan = skillPlan;
			row.skillPlanName = skillPlan.name;
			row.active = skillPlan.active;
			dispatch_async(dispatch_get_main_queue(), ^{
				self.rows = rows;
				[tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
				[self renameSkillPlanAtIndexPath:indexPath];
			});
		}];
    }
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == self.rows.count)
		return 37;
	else
		return 42;
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.row < self.rows.count ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleInsert;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == self.rows.count) {
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		[self tableView:tableView commitEditingStyle:UITableViewCellEditingStyleInsert forRowAtIndexPath:indexPath];
	}
	else {
		NCTableViewCell* cell = (NCTableViewCell*) [tableView cellForRowAtIndexPath:indexPath];
		UIAlertController* controller = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
		[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
			[tableView deselectRowAtIndexPath:indexPath animated:YES];
			[self tableView:tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:indexPath];
		}]];
		[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Rename", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[tableView deselectRowAtIndexPath:indexPath animated:YES];
			[self renameSkillPlanAtIndexPath:indexPath];
		}]];
		[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Switch", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[tableView deselectRowAtIndexPath:indexPath animated:YES];
			[self.rows setValue:@(NO) forKey:@"active"];
			[cell.object setActive:YES];
			[self.account.managedObjectContext performBlock:^{
				[self.account setActiveSkillPlan:[cell.object skillPlan]];
			}];
			[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
		}]];
		
		[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
			[tableView deselectRowAtIndexPath:indexPath animated:YES];
		}]];
		
		[self presentViewController:controller animated:YES completion:nil];
	}
}

#pragma mark - NCTableViewController


- (void) didChangeAccount:(NSNotification *)notification {
	[super didChangeAccount:notification];
	self.account = [NCAccount currentAccount];
	[self reload];
}

#pragma mark - Private

- (void) renameSkillPlanAtIndexPath:(NSIndexPath*) indexPath {
	NCTableViewCell* cell = (NCTableViewCell*) [self.tableView cellForRowAtIndexPath:indexPath];
	NCSkillPlansViewControllerRow* row = cell.object;

	UIAlertController* controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enter skill plan name", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
	__block UITextField* nameTextField;
	[controller addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
		nameTextField = textField;
		textField.clearButtonMode = UITextFieldViewModeAlways;
		textField.text = row.skillPlanName;
	}];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Rename", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		row.skillPlanName = nameTextField.text;
		[row.skillPlan.managedObjectContext performBlock:^{
			row.skillPlan.name = row.skillPlanName;
		}];
		[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}]];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
	}]];
	[self presentViewController:controller animated:YES completion:nil];
}

- (void) reload {
	if (self.account) {
		[self.account.managedObjectContext performBlock:^{
			NSArray* skillPlans = [self.account.skillPlans sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
			NSMutableArray* rows = [NSMutableArray new];
			
			dispatch_group_t finishDispatchGroup = dispatch_group_create();
			for (NCSkillPlan* skillPlan in skillPlans) {
				dispatch_group_enter(finishDispatchGroup);
				NCSkillPlansViewControllerRow* row = [NCSkillPlansViewControllerRow new];
				[rows addObject:row];
				row.skillPlan = skillPlan;
				row.skillPlanName = skillPlan.name;
				row.active = skillPlan.active;
				[skillPlan loadTrainingQueueWithCompletionBlock:^(NCTrainingQueue *trainingQueue) {
					row.trainingQueue = trainingQueue;
					dispatch_group_leave(finishDispatchGroup);
				}];
			}
			
			dispatch_group_notify(finishDispatchGroup, dispatch_get_main_queue(), ^{
				self.rows = rows;
				[self.tableView reloadData];
			});
		}];
	}
}

@end
