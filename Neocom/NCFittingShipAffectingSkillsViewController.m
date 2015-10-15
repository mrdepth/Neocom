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

@interface NCFittingShipAffectingSkillsViewControllerSection : NSObject
@property (nonatomic, strong) NSArray* rows;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, assign) int32_t groupID;
@end

@implementation NCFittingShipAffectingSkillsViewControllerSection
@end

@interface NCFittingShipAffectingSkillsViewController ()
@property (nonatomic, strong) NSFetchedResultsController* result;
@property (nonatomic, strong) NSMutableDictionary* skills;

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
	self.skills = [self.character.skills mutableCopy] ?: [NSMutableDictionary new];
	
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
	request.predicate = [NSPredicate predicateWithFormat:@"published == TRUE AND typeID IN %@", self.affectingSkillsTypeIDs];
	request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"group.groupName" ascending:YES],
								[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];
	self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request
													  managedObjectContext:self.databaseManagedObjectContext
														sectionNameKeyPath:@"group.groupName"
																 cacheName:nil];
	[self.result performFetch:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if (self.modified) {
		self.character.skills = self.skills;
	}
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		controller.typeID = [[sender object] objectID];
	}
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.result.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.result.sections[section] numberOfObjects];
}


- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [self.result.sections[section] name];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
/*
	NCDBInvType* type = [self.result objectAtIndexPath:indexPath];
	UIAlertController* controller = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	for (int i = 0; i <= 5; i++)
		[controller addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Level %d", nil), i] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			self.skills[@(type.typeID)] = @(i);
			self.modified = YES;
			[tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
		}]];
	
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
	}]];
	[self presentViewController:controller animated:YES completion:nil];*/
}


#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCFittingCharacterEditorCell* cell = (NCFittingCharacterEditorCell*) tableViewCell;
	NCDBInvType* skill = [self.result objectAtIndexPath:indexPath];
	
	cell.skillNameLabel.text = skill.typeName;
	cell.skillLevelLabel.text = [NSString stringWithFormat:@"%d", [self.skills[@(skill.typeID)] intValue]];
	cell.object = skill;
}

@end
