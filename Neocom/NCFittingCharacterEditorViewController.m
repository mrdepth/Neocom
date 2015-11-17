//
//  NCFittingCharacterEditorViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 31.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingCharacterEditorViewController.h"
#import "NCFitCharacter.h"
#import "NSArray+Neocom.h"
#import "NCFittingCharacterEditorCell.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "NSString+Neocom.h"

@interface NCFittingCharacterEditorViewController ()
@property (nonatomic, strong) NSFetchedResultsController* results;
@property (nonatomic, strong) NSMutableDictionary* skills;
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

	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
	request.predicate = [NSPredicate predicateWithFormat:@"published == TRUE AND group.category.categoryID == 16"];
	request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"group.groupName" ascending:YES],
								[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];
	NSFetchedResultsController* results = [[NSFetchedResultsController alloc] initWithFetchRequest:request
																			 managedObjectContext:self.databaseManagedObjectContext
																			   sectionNameKeyPath:@"group.groupName"
																						cacheName:nil];
	[results performFetch:nil];
	self.results = results;
	self.skills = [self.character.skills mutableCopy] ?: [NSMutableDictionary new];
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	self.character.skills = self.skills;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onAction:(id)sender {
	NCAccount* account = [NCAccount currentAccount];

	void (^performAction)(NCSkillPlan* skillPlan) = ^(NCSkillPlan* skillPlan) {
		UIAlertController* controller = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
		[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Rename", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			UIAlertController* controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Rename", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
			__block UITextField* renameTextField;
			[controller addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
				renameTextField = textField;
				textField.text = self.character.name;
				textField.clearButtonMode = UITextFieldViewModeAlways;
			}];
			[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Rename", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				self.character.name = renameTextField.text;
				self.title = self.character.name;
			}]];
			[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
			}]];
			[self presentViewController:controller animated:YES completion:nil];
		}]];
		
		if (skillPlan) {
			[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Add to active Skill Plan", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				[account loadCharacterSheetWithCompletionBlock:^(EVECharacterSheet *characterSheet, NSError *error) {
					NCTrainingQueue* trainingQueue = [[NCTrainingQueue alloc] initWithCharacterSheet:characterSheet databaseManagedObjectContext:self.databaseManagedObjectContext];
					[self.skills enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
						[trainingQueue addSkill:[self.databaseManagedObjectContext invTypeWithTypeID:[key intValue]] withLevel:[obj intValue]];
					}];
					
					UIAlertController* controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Add to skill plan?", nil)
																						message:[NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:trainingQueue.trainingTime]]
																				 preferredStyle:UIAlertControllerStyleAlert];
					
					[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Add", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
						[skillPlan mergeWithTrainingQueue:trainingQueue completionBlock:^(NCTrainingQueue *trainingQueue) {
						}];
					}]];
					[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
					}]];
					[self presentViewController:controller animated:YES completion:nil];
				}];
			}]];
			
			[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Import from active Skill Plan", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				UIAlertController* controller = [UIAlertController alertControllerWithTitle:nil
																					message:NSLocalizedString(@"Your skill levels will be replaced with values from skill plan", nil)
																			 preferredStyle:UIAlertControllerStyleAlert];
				
				[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Import", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
					[account loadCharacterSheetWithCompletionBlock:^(EVECharacterSheet *characterSheet, NSError *error) {
						[skillPlan loadTrainingQueueWithCompletionBlock:^(NCTrainingQueue *trainingQueue) {
							NSMutableDictionary* skills = [NSMutableDictionary new];
							for (EVECharacterSheetSkill* characterSkill in characterSheet.skills)
								skills[@(characterSkill.typeID)] = @(characterSkill.level);
							
							for (NCSkillData* skillPlanSkill in trainingQueue.skills) {
								int level = [skills[@(skillPlanSkill.typeID)] intValue];
								skills[@(skillPlanSkill.typeID)] = @(MAX(level, skillPlanSkill.targetLevel));
							}
							self.skills = skills;
							[self.tableView reloadData];
						}];
					}];
				}]];
				[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
				}]];
				[self presentViewController:controller animated:YES completion:nil];
			}]];
			
		}
		
		[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
		}]];
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			controller.modalPresentationStyle = UIModalPresentationPopover;
			[self presentViewController:controller animated:YES completion:nil];
			if ([sender isKindOfClass:[UIBarButtonItem class]])
				controller.popoverPresentationController.barButtonItem = sender;
			else {
				controller.popoverPresentationController.sourceView = sender;
				controller.popoverPresentationController.sourceRect = [sender bounds];
			}
		}
		else
			[self presentViewController:controller animated:YES completion:nil];
	};
	
	if (account) {
		[account.managedObjectContext performBlock:^{
			NCSkillPlan* skillPlan = account.activeSkillPlan;
			dispatch_async(dispatch_get_main_queue(), ^{
				performAction(skillPlan);
			});
		}];
	}
	else
		performAction(nil);
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
	return self.results.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
	id<NSFetchedResultsSectionInfo> section = self.results.sections[sectionIndex];
	return [section numberOfObjects];
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
	id<NSFetchedResultsSectionInfo> section = self.results.sections[sectionIndex];
	return section.name;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NCDBInvType* type = [self.results objectAtIndexPath:indexPath];
	UIAlertController* controller = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	for (int i = 0; i <= 5; i++)
		[controller addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Level %d", nil), i] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			self.skills[@(type.typeID)] = @(i);
			[tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
		}]];
	
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
	}]];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		controller.modalPresentationStyle = UIModalPresentationPopover;
		[self presentViewController:controller animated:YES completion:nil];
		UITableViewCell* sender = [tableView cellForRowAtIndexPath:indexPath];
		controller.popoverPresentationController.sourceView = sender;
		controller.popoverPresentationController.sourceRect = [sender bounds];
	}
	else
		[self presentViewController:controller animated:YES completion:nil];
}


#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (id) identifierForSection:(NSInteger)sectionIndex {
	NCDBInvType* type = [self.results objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:sectionIndex]];
	return @(type.group.groupID);
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCFittingCharacterEditorCell* cell = (NCFittingCharacterEditorCell*) tableViewCell;
	NCDBInvType* type = [self.results objectAtIndexPath:indexPath];
	
	cell.skillNameLabel.text = type.typeName;
	cell.skillLevelLabel.text = [NSString stringWithFormat:@"%d", [self.skills[@(type.typeID)] intValue]];
	cell.object = type;
}

@end
