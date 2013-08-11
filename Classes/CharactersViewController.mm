//
//  CharactersViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CharactersViewController.h"
#import "CharacterEqualSkills.h"
#import "FitCharacter.h"
#import "EVEAccountsManager.h"
#import "EUOperationQueue.h"
#import "GroupedCell.h"
#import "CharacterSkillsEditorViewController.h"
#import "appearance.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"
#import "EUStorage.h"

@interface CharactersViewController()
@property(nonatomic, strong) NSMutableArray *sections;

- (void) reload;
@end

@implementation CharactersViewController

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
	self.title = NSLocalizedString(@"Characters", nil);
	[self.navigationItem setRightBarButtonItem:self.editButtonItem];
	[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onClose:)]];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self reload];
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	[self.tableView setEditing:editing animated:animated];

	NSIndexPath* indexPath = [NSIndexPath indexPathForRow:[[self.sections objectAtIndex:1] count] inSection:1];
	NSArray* array = [NSArray arrayWithObject:indexPath];
	if (editing)
		[self.tableView insertRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationFade];
	else
		[self.tableView deleteRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationFade];
}

- (IBAction) onClose:(id) sender {
	self.completionHandler = nil;
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (self.editing) {
		NSInteger number = [[self.sections objectAtIndex:section] count];
		if (section == 1)
			return number + 1;
		else
			return number;
	}
	else
		return [[self.sections objectAtIndex:section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return NSLocalizedString(@"EVE Charaters", nil);
	else if (section == 1)
		return NSLocalizedString(@"Custom Characters", nil);
	else
		return NSLocalizedString(@"Static Characters", nil);
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *cellIdentifier = @"Cell";
	
    GroupedCell *cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
	if (indexPath.row == [[self.sections objectAtIndex:indexPath.section] count])
		cell.textLabel.text = NSLocalizedString(@"Add Character", nil);
	else
		cell.textLabel.text = [self.sections[indexPath.section][indexPath.row] name];
	
	int groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = static_cast<GroupedCellGroupStyle>(groupStyle);
	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		FitCharacter* character = self.sections[indexPath.section][indexPath.row];
		[character.managedObjectContext deleteObject:character];

		[[self.sections objectAtIndex:indexPath.section] removeObjectAtIndex:indexPath.row];
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}
	else if (editingStyle == UITableViewCellEditingStyleInsert) {
		NSManagedObjectContext* context = [[EUStorage sharedStorage] managedObjectContext];
		FitCharacter* character = [[FitCharacter alloc] initWithEntity:[NSEntityDescription entityForName:@"FitCharacter" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
		character.name = NSLocalizedString(@"Custom Character", nil);
		[character save];

		[[self.sections objectAtIndex:1] addObject:character];
		[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		
		CharacterSkillsEditorViewController* controller = [[CharacterSkillsEditorViewController alloc] initWithNibName:@"CharacterSkillsEditorViewController" bundle:nil];
		//controller.character = character;
		[self.navigationController pushViewController:controller animated:YES];
	}
	[[EUStorage sharedStorage] saveContext];
}

#pragma mark -
#pragma mark Table view delegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == [[self.sections objectAtIndex:indexPath.section] count])
		return UITableViewCellEditingStyleInsert;
	else
		return indexPath.section == 1 ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

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
	if (indexPath.row == [[self.sections objectAtIndex:indexPath.section] count]) {
		[self tableView:tableView commitEditingStyle:UITableViewCellEditingStyleInsert forRowAtIndexPath:indexPath];
	}
	else {
		id<Character> character = self.sections[indexPath.section][indexPath.row];
		
		__block EUOperation* operation = [EUOperation operationWithIdentifier:@"CharactersViewController+LoadSkills" name:NSLocalizedString(@"Loading Skills", nil)];
		__weak EUOperation* weakOperation = operation;
		[operation addExecutionBlock:^{
			[character skillsDictionary];
		}];
		
		[operation setCompletionBlockInMainThread:^{
			if (![weakOperation isCancelled]) {
				if (self.editing) {
					CharacterSkillsEditorViewController* controller = [[CharacterSkillsEditorViewController alloc] initWithNibName:@"CharacterSkillsEditorViewController" bundle:nil];
					controller.character = character;
					[self.navigationController pushViewController:controller animated:YES];
				}
				else {
					self.completionHandler(character);
					self.completionHandler = nil;
					[self dismissViewControllerAnimated:YES completion:nil];
				}
			}
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
}

#pragma mark - Private

- (void) reload {
	NSMutableArray* sectionsTmp = [NSMutableArray array];
	EUOperation* operation = [EUOperation operationWithIdentifier:@"CharactersViewController+reload" name:NSLocalizedString(@"Loading Characters", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^{
		NSMutableArray* staticCharacters = [NSMutableArray new];
		for (int i = 0; i <= 5; i++)
			[staticCharacters addObject:[CharacterEqualSkills characterWithSkillsLevel:i]];
		weakOperation.progress = 0.5;
		
		NSMutableArray* customCharacters = [[NSMutableArray alloc] initWithArray:[FitCharacter allCustomCharacters]];

		NSMutableArray* eveCharacters = [NSMutableArray new];
		
		for (EVEAccount* account in [[EVEAccountsManager sharedManager] allAccounts]) {
			FitCharacter* character = [FitCharacter fitCharacterWithAccount:account];
			[eveCharacters addObject:character];
		}
		[eveCharacters sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
		weakOperation.progress = 0.9;

		[sectionsTmp addObject:eveCharacters];
		[sectionsTmp addObject:customCharacters];
		[sectionsTmp addObject:staticCharacters];
		weakOperation.progress = 1.0;
	}];
	
	[operation setCompletionBlockInMainThread:^{
		self.sections = sectionsTmp;
		[self.tableView reloadData];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end
