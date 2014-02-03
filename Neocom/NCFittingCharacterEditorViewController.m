//
//  NCFittingCharacterEditorViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 31.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingCharacterEditorViewController.h"
#import "NCFitCharacter.h"
#import "EVEDBAPI.h"
#import "NSArray+Neocom.h"
#import "UIActionSheet+Block.h"
#import "NCFittingCharacterEditorCell.h"
#import "UIAlertView+Block.h"

@interface NCFittingCharacterEditorViewController ()
@property (nonatomic, strong) NSArray* sections;
@property (nonatomic, strong) NSDictionary* skills;
@end

@implementation NCFittingCharacterEditorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.refreshControl = nil;
	self.title = self.character.name;

	NSMutableDictionary* skills = [NSMutableDictionary new];
	NSMutableArray* sections = [NSMutableArray new];
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 [[EVEDBDatabase sharedDatabase] execSQLRequest:@"SELECT a.* FROM invTypes as a, invGroups as b where a.groupID=b.groupID and b.categoryID=16 and a.published = 1"
																				resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																					if ([task isCancelled])
																						*needsMore = NO;
																					NCSkillData* skillData = [[NCSkillData alloc] initWithStatement:stmt];
																					skillData.trainedLevel = -1;
																					skills[@(skillData.typeID)] = skillData;
																				}];
											 for (NSArray* array in [[[skills allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]]] arrayGroupedByKey:@"groupID"]) {
												 NSString* title = [[array[0] group] groupName];
												 [sections addObject:@{@"title": title, @"rows": array}];
											 }
											 [self.character.skills enumerateKeysAndObjectsUsingBlock:^(NSNumber* typeID, NSNumber* level, BOOL *stop) {
												 NCSkillData* skillData = skills[typeID];
												 skillData.currentLevel = [level integerValue];
											 }];
											 [sections sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];

										 }
							 completionHandler:^(NCTask *task) {
								 self.skills = skills;
								 self.sections = sections;
								 [self.tableView reloadData];
							 }];
	// Do any additional setup after loading the view.
}

- (void) viewWillDisappear:(BOOL)animated {
	NSMutableDictionary* skills = [NSMutableDictionary new];
	[self.skills enumerateKeysAndObjectsUsingBlock:^(NSNumber* typeID, NCSkillData* skillData, BOOL *stop) {
		skills[typeID] = @(skillData.currentLevel);
	}];
	self.character.skills = skills;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onAction:(id)sender {
	[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackTranslucent
								   title:nil
					   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
				  destructiveButtonTitle:nil
					   otherButtonTitles:@[NSLocalizedString(@"Rename", nil)]
						 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
							 if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
								 UIAlertView* alertView = [UIAlertView alertViewWithTitle:NSLocalizedString(@"Rename", nil)
																				  message:nil
																		cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
																		otherButtonTitles:@[NSLocalizedString(@"Rename", nil)]
																		  completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
																			  if (selectedButtonIndex != alertView.cancelButtonIndex) {
																				  UITextField* textField = [alertView textFieldAtIndex:0];
																				  self.character.name = textField.text;
																				  self.title = self.character.name;
																			  }
																		  } cancelBlock:nil];
								 alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
								 UITextField* textField = [alertView textFieldAtIndex:0];
								 textField.text = self.character.name;
								 [alertView show];
							 }
						 }
							 cancelBlock:nil] showFromBarButtonItem:sender animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.sections[section][@"rows"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	NCFittingCharacterEditorCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	NCSkillData* skill = self.sections[indexPath.section][@"rows"][indexPath.row];
	
	cell.skillNameLabel.text = skill.typeName;
	cell.skillLevelLabel.text = [NSString stringWithFormat:@"%d", skill.currentLevel];
	return cell;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return self.sections[section][@"title"];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NCSkillData* skill = self.sections[indexPath.section][@"rows"][indexPath.row];
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	NSMutableArray* buttons = [NSMutableArray new];
	for (int i = 0; i <=5; i++)
		[buttons addObject:[NSString stringWithFormat:NSLocalizedString(@"Level %d", nil), i]];
	[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackTranslucent
								   title:nil
					   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
				  destructiveButtonTitle:nil
					   otherButtonTitles:buttons
						 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
							 if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
								 skill.currentLevel = selectedButtonIndex;
								 [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
							 }
						 }
							 cancelBlock:^{
								 
							 }] showFromRect:cell.bounds inView:cell animated:YES];
}


#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

@end
