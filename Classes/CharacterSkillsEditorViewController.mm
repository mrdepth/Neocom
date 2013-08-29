//
//  CharacterSkillsEditorViewController.m
//  EVEUniverse
//
//  Created by mr_depth on 27.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CharacterSkillsEditorViewController.h"
#import "EUOperationQueue.h"
#import "Character.h"
#import "CharacterEqualSkills.h"
#import "EVEDBAPI.h"
#import "GroupedCell.h"
#import "ItemViewController.h"
#import "appearance.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"
#import "FitCharacter.h"
#import "EUStorage.h"
#import "UIActionSheet+Block.h"
#import "UIViewController+Neocom.h"

#define ActionButtonDuplicate NSLocalizedString(@"Duplicate", nil)
#define ActionButtonRename NSLocalizedString(@"Rename", nil)
#define ActionButtonDelete NSLocalizedString(@"Delete", nil)
#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)


@interface CharacterSkillsEditorViewController()
@property(nonatomic, strong) NSArray *sections;
@property(nonatomic, strong) NSMutableDictionary* groups;
@property(nonatomic, strong) NSIndexPath *modifiedIndexPath;
@property(nonatomic, strong) UIActionSheet* actionSheet;

@end

@implementation CharacterSkillsEditorViewController

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
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	self.title = self.character.name;
	[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(onOptions:)]];
	
	__block NSArray* sectionsTmp = nil;
	self.groups = [[NSMutableDictionary alloc] init];
	EUOperation* operation = [EUOperation operationWithIdentifier:@"CharacterSkillsEditorViewController+load" name:NSLocalizedString(@"Loading Skills", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^{
		EVEDBDatabase *database = [EVEDBDatabase sharedDatabase];
		if (database) {
			NSError* error = [database execSQLRequest:@"SELECT invTypes.* FROM invTypes, invGroups WHERE invTypes.groupID=invGroups.groupID and invGroups.categoryID=16 AND invTypes.published=1;"
										  resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
											  EVEDBInvType* skill = [[EVEDBInvType alloc] initWithStatement:stmt];
											  NSNumber* key = @(skill.groupID);
											  
											  NSMutableArray* skills = self.groups[key];
											  if (!skills) {
												  skills = [NSMutableArray array];
												  self.groups[key] = skills;
											  }
											  
											  [skills addObject:skill];
										  }];
			weakOperation.progress = 0.5;
			if (!error) {
				sectionsTmp = [[self.groups allValues] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
					return [[[obj1[0] group] groupName] compare:[[obj2[0] group] groupName]];
				}];
				float n = sectionsTmp.count;
				float i = 0;
				for (NSMutableArray* array in sectionsTmp) {
					[array sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]]];
					weakOperation.progress = 0.5 + i++ / n / 2;
				}
			}
		}
	}];
	
	[operation setCompletionBlockInMainThread:^{
		self.sections = sectionsTmp;
		self.groups = nil;
		[self.tableView reloadData];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (IBAction) onOptions:(id) sender {
	NSMutableArray* buttons = [NSMutableArray new];
	NSMutableArray* actions = [NSMutableArray new];
	
	void (^deleteCharacter)() = ^() {
		FitCharacter* character = (FitCharacter*) self.character;
		[character.managedObjectContext deleteObject:character];
		[[EUStorage sharedStorage] saveContext];
		[self.navigationController popViewControllerAnimated:YES];
	};

	void (^rename)() = ^() {
		self.characterNameTextField.text = self.character.name;
		self.navigationItem.titleView = self.characterNameTextField;
		[self.characterNameTextField becomeFirstResponder];
	};
	
	void (^duplicate)() = ^() {
		NSManagedObjectContext* context = [[EUStorage sharedStorage] managedObjectContext];
		FitCharacter* character = [[FitCharacter alloc] initWithEntity:[NSEntityDescription entityForName:@"FitCharacter" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
		character.name = [self.character.name stringByAppendingString:NSLocalizedString(@" Copy", nil)];
		character.skillsDictionary = self.character.skillsDictionary;
		self.title = character.name;
		self.character = character;
	};
	
	if (!self.character.readonly) {
		[actions addObject:deleteCharacter];
		[actions addObject:rename];
		[buttons addObject:ActionButtonRename];
	}
	else {
	}
	[actions addObject:duplicate];
	[buttons addObject:ActionButtonDuplicate];
	
	if (self.actionSheet) {
		[self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:YES];
		self.actionSheet = nil;
	}
	
	
	self.actionSheet = [UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackOpaque
													 title:nil
										 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
									destructiveButtonTitle:!self.character.readonly ? NSLocalizedString(@"Delete", nil) : nil
										 otherButtonTitles:buttons
										   completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
											   if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
												   void (^action)() = actions[selectedButtonIndex];
												   action();
											   }
											   self.actionSheet = nil;
										   } cancelBlock:nil];
	[self.actionSheet showFromBarButtonItem:sender animated:YES];
}

- (IBAction) onDone:(id)sender {
	self.character.name = self.characterNameTextField.text;
//	[self.character save];
	[self.characterNameTextField resignFirstResponder];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.sections[section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [[self.sections[section][0] group] groupName];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *cellIdentifier = @"Cell";
	
    GroupedCell *cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
	EVEDBInvType* skill = self.sections[indexPath.section][indexPath.row];
	NSInteger level = [self.character.skillsDictionary[@(skill.typeID)] integerValue];
	cell.textLabel.text = skill.typeName;
	cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Level %d", nil), level];
	cell.imageView.image = [UIImage imageNamed:level == 5 ? @"Icons/icon50_14.png" : @"Icons/icon50_13.png"];
	
	int groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = static_cast<GroupedCellGroupStyle>(groupStyle);
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	if (title) {
		CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
		view.titleLabel.text = title;
		return view;
	}
	else
		return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return [self tableView:tableView titleForHeaderInSection:section] ? 22 : 0;
}

- (void)tableView:(UITableView*) tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	EVEDBInvType* skill = self.sections[indexPath.section][indexPath.row];

	SkillLevelsViewController* controller = [[SkillLevelsViewController alloc] initWithNibName:@"SkillLevelsViewController" bundle:nil];
	controller.currentLevel = [self.character.skillsDictionary[@(skill.typeID)] integerValue];
	controller.title = skill.typeName;
	controller.completionHandler = ^(NSInteger level) {
		if ([self.character isReadonly]) {
			NSManagedObjectContext* context = [[EUStorage sharedStorage] managedObjectContext];
			FitCharacter* character = [[FitCharacter alloc] initWithEntity:[NSEntityDescription entityForName:@"FitCharacter" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
			character.name = [self.character.name stringByAppendingString:NSLocalizedString(@" Copy", nil)];
			character.skillsDictionary = self.character.skillsDictionary;
			self.title = character.name;
			self.character = character;
		}
		self.character.skillsDictionary[@(skill.typeID)] = @(level);
		[(FitCharacter*) self.character save];
		[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
		[self dismiss];
	};
	
	UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self presentViewControllerInPopover:navigationController
									fromRect:[tableView rectForRowAtIndexPath:indexPath]
									  inView:tableView
					permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	else
		[self presentViewController:navigationController animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	ItemViewController *itemViewController = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	
	itemViewController.type = [[self.sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	[itemViewController setActivePage:ItemViewControllerActivePageInfo];
	[self.navigationController pushViewController:itemViewController animated:YES];
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *button = [actionSheet buttonTitleAtIndex:buttonIndex];
	
	if ([button isEqualToString:ActionButtonDuplicate]) {
		//self.character = [CharacterCustom characterWithCharacter:self.character];
		self.character.name = [self.character.name stringByAppendingString:NSLocalizedString(@" Copy", nil)];
		self.title = self.character.name;
		//[self.character save];
	}
	else if ([button isEqualToString:ActionButtonRename]) {
		self.characterNameTextField.text = self.character.name;
		[self.characterNameTextField becomeFirstResponder];
	}
	else if ([button isEqualToString:ActionButtonDelete]) {
		//NSString* path = [[[Character charactersDirectory] stringByAppendingPathComponent:self.character.guid] stringByAppendingPathExtension:@"plist"];
		//[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
		[self.navigationController popViewControllerAnimated:YES];
	}
}

#pragma mark SkillLevelsViewControllerDelegate

- (void) skillLevelsViewController:(SkillLevelsViewController*) controller didSelectLevel:(NSInteger) level {
	/*if ([self.character isKindOfClass:[CharacterEVE class]]) {
		self.character = [CharacterCustom characterWithCharacter:self.character];
		self.character.name = [self.character.name stringByAppendingString:NSLocalizedString(@" Copy", nil)];
		self.title = self.character.name;
	}
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[popoverController dismissPopoverAnimated:YES];
	else 
		[self dismissModalViewControllerAnimated:YES];
	EVEDBInvType* skill = [[self.sections objectAtIndex:self.modifiedIndexPath.section] objectAtIndex:self.modifiedIndexPath.row];
	NSString* key = [NSString stringWithFormat:@"%d", skill.typeID];
	[self.character.skills setValue:[NSNumber numberWithInteger:level] forKey:key];
	[self.character save];
	[self.skillsTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:self.modifiedIndexPath] withRowAnimation:UITableViewRowAnimationFade];*/
}

#pragma mark UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
	self.character.name = self.characterNameTextField.text;
	self.navigationItem.titleView = nil;
	self.navigationItem.title = self.characterNameTextField.text;
	[[EUStorage sharedStorage] saveContext];
	[textField resignFirstResponder];
	return YES;
}

@end
