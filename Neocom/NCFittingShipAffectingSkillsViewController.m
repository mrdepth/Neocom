//
//  NCFittingShipAffectingSkillsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 10.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingShipAffectingSkillsViewController.h"
#import "NSArray+Neocom.h"
#import "NCFittingCharacterEditorCell.h"
#import "UIActionSheet+Block.h"
#import "NCStorage.h"
#import "NCDatabaseTypeInfoViewController.h"

@interface NCFittingShipAffectingSkillsViewController ()
@property (nonatomic, strong) NSArray* sections;
@property (nonatomic, strong) NSDictionary* skills;

@end

@implementation NCFittingShipAffectingSkillsViewController

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
	self.refreshControl = nil;
	self.title = self.character.name;
	
	NSMutableDictionary* skills = [NSMutableDictionary new];
	NSMutableArray* sections = [NSMutableArray new];
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NCDatabase* database = [NCDatabase sharedDatabase];
											 [database.backgroundManagedObjectContext performBlockAndWait:^{
												 NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
												 request.predicate = [NSPredicate predicateWithFormat:@"published == TRUE AND typeID IN %@", self.affectingSkillsTypeIDs];
												 request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"group.groupName" ascending:YES],
																			 [NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];
												 NSFetchedResultsController* result = [[NSFetchedResultsController alloc] initWithFetchRequest:request
																														  managedObjectContext:database.backgroundManagedObjectContext
																															sectionNameKeyPath:@"group.groupName"
																																	 cacheName:nil];
												 [result performFetch:nil];
												 for (id<NSFetchedResultsSectionInfo> sectionInfo in result.sections) {
													 NSMutableArray* rows = [NSMutableArray new];
													 NCDBInvGroup* group = nil;
													 for (NCDBInvType* type in sectionInfo.objects) {
														 if (!group)
															 group = type.group;
														 NCSkillData* skillData = [[NCSkillData alloc] initWithInvType:type];
														 skillData.currentLevel = [self.character.skills[@(type.typeID)] integerValue];
														 [rows addObject:skillData];
														 skills[@(type.typeID)] = skillData;
													 }
													 [sections addObject:@{@"title": sectionInfo.name, @"rows": rows, @"sectionID": @(group.groupID)}];
												 }
											 }];
										 }
							 completionHandler:^(NCTask *task) {
								 self.skills = skills;
								 self.sections = sections;
								 [self update];
							 }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if (self.modified) {
		NSMutableDictionary* skills = self.character.skills ? [self.character.skills mutableCopy] : [NSMutableDictionary new];
		[self.skills enumerateKeysAndObjectsUsingBlock:^(NSNumber* typeID, NCSkillData* skillData, BOOL *stop) {
			skills[typeID] = @(skillData.currentLevel);
		}];
		self.character.skills = skills;
		if (!self.character.managedObjectContext) {
			NCStorage* storage = [NCStorage sharedStorage];
			[storage.managedObjectContext insertObject:self.character];
			[storage saveContext];
		}
	}
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		controller.type = [sender skillData];
	}
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.sections[section][@"rows"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCFittingCharacterEditorCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	return cell;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return self.sections[section][@"title"];
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 41;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	
	UITableViewCell* cell = [self tableView:tableView offscreenCellWithIdentifier:@"Cell"];
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell layoutIfNeeded];
	return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NCSkillData* skill = self.sections[indexPath.section][@"rows"][indexPath.row];
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	NSMutableArray* buttons = [NSMutableArray new];
	for (int32_t i = 0; i <=5; i++)
		[buttons addObject:[NSString stringWithFormat:NSLocalizedString(@"Level %d", nil), i]];
	[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackTranslucent
								   title:nil
					   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
				  destructiveButtonTitle:nil
					   otherButtonTitles:buttons
						 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
							 if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
								 skill.currentLevel = (int32_t) selectedButtonIndex;
								 [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
								 self.modified = YES;
							 }
						 }
							 cancelBlock:^{
								 
							 }] showFromRect:cell.bounds inView:cell animated:YES];
}


#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (id) identifierForSection:(NSInteger)section {
	return self.sections[section][@"sectionID"];
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCFittingCharacterEditorCell* cell = (NCFittingCharacterEditorCell*) tableViewCell;
	NCSkillData* skill = self.sections[indexPath.section][@"rows"][indexPath.row];
	
	cell.skillNameLabel.text = skill.type.typeName;
	cell.skillLevelLabel.text = [NSString stringWithFormat:@"%d", skill.currentLevel];
	cell.skillData = skill;
}

@end
