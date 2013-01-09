//
//  CharacterSkillsEditorViewController.m
//  EVEUniverse
//
//  Created by mr_depth on 27.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CharacterSkillsEditorViewController.h"
#import "EUOperationQueue.h"
#import "SkillEditingCellView.h"
#import "UITableViewCell+Nib.h"
#import "Character.h"
#import "CharacterEqualSkills.h"
#import "CharacterEVE.h"
#import "CharacterCustom.h"
#import "EVEDBAPI.h"
#import "UIImageView+GIF.h"
#import "ItemViewController.h"

#define ActionButtonDuplicate NSLocalizedString(@"Duplicate", nil)
#define ActionButtonRename NSLocalizedString(@"Rename", nil)
#define ActionButtonDelete NSLocalizedString(@"Delete", nil)
#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)


@interface CharacterSkillsEditorViewController(Private)
- (void) didReceiveRecord: (NSDictionary*) record;
- (void) keyboardWillShow: (NSNotification*) notification;
- (void) keyboardWillHide: (NSNotification*) notification;
@end

@implementation CharacterSkillsEditorViewController
@synthesize skillsTableView;
@synthesize modalController;
@synthesize shadowView;
@synthesize characterNameToolbar;
@synthesize characterNameTextField;
@synthesize popoverController;
@synthesize character;

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
	self.title = character.name;
	[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Options", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onOptions:)] autorelease]];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.popoverController = [[[UIPopoverController alloc] initWithContentViewController:modalController] autorelease];
	}
	
	__block NSArray* sectionsTmp = nil;
	groups = [[NSMutableDictionary alloc] init];
	EUOperation* operation = [EUOperation operationWithIdentifier:@"CharacterSkillsEditorViewController+load" name:NSLocalizedString(@"Loading Skills", nil)];
	[operation addExecutionBlock:^{
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		EVEDBDatabase *database = [EVEDBDatabase sharedDatabase];
		if (database) {
			NSError *error = [database execWithSQLRequest:@"SELECT invTypes.* FROM invTypes, invGroups WHERE invTypes.groupID=invGroups.groupID and invGroups.categoryID=16 AND invTypes.published=1;"
												   target:self
												   action:@selector(didReceiveRecord:)];
			operation.progress = 0.5;
			if (!error) {
				sectionsTmp = [[[groups allValues] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
					return [[[[obj1 objectAtIndex:0] group] groupName] compare:[[[obj2 objectAtIndex:0] group] groupName]];
				}] retain];
				float n = sectionsTmp.count;
				float i = 0;
				for (NSMutableArray* array in sectionsTmp) {
					[array sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]]];
					operation.progress = 0.5 + i++ / n / 2;
				}
			}
		}
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^{
		[sections release];
		sections = sectionsTmp;
		[groups release];
		groups = nil;
		[skillsTableView reloadData];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)viewDidUnload
{
    [self setShadowView:nil];
    [self setCharacterNameToolbar:nil];
    [self setCharacterNameTextField:nil];
    [super viewDidUnload];
	self.skillsTableView = nil;
	self.modalController = nil;
	self.popoverController = nil;

	[sections release];
	sections = nil;
	[groups release];
	groups = nil;
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)dealloc {
	[skillsTableView release];
	[modalController release];
	[popoverController release];
	[character release];
	[sections release];
	[modifiedIndexPath release];
    [shadowView release];
    [characterNameToolbar release];
    [characterNameTextField release];
	[super dealloc];
}

- (IBAction) didCloseModalViewController:(id) sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction) onOptions:(id) sender {
	UIActionSheet* actionSheet = [[[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil] autorelease];
	int cancelID = 1;
	[actionSheet addButtonWithTitle:ActionButtonDuplicate];
	if ([character isKindOfClass:[CharacterCustom class]]) {
		[actionSheet addButtonWithTitle:ActionButtonRename];
		cancelID++;
	}
	if (![character isKindOfClass:[CharacterEqualSkills class]]) {
		[actionSheet addButtonWithTitle:ActionButtonDelete];
		[actionSheet setDestructiveButtonIndex:cancelID];
		cancelID++;
	}
	[actionSheet addButtonWithTitle:ActionButtonCancel];
	[actionSheet setCancelButtonIndex:cancelID];
	[actionSheet showFromBarButtonItem:sender animated:YES];
}

- (IBAction) onDone:(id)sender {
	self.character.name = characterNameTextField.text;
	[character save];
	[characterNameTextField resignFirstResponder];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[sections objectAtIndex:section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [[[[sections objectAtIndex:section] objectAtIndex:0] group] groupName];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *cellIdentifier = @"SkillEditingCellView";
	
    SkillEditingCellView *cell = (SkillEditingCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [SkillEditingCellView cellWithNibName:@"SkillEditingCellView" bundle:nil reuseIdentifier:cellIdentifier];
    }
	EVEDBInvType* skill = [[sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	NSInteger level = [[character.skills valueForKey:[NSString stringWithFormat:@"%d", skill.typeID]] integerValue];
	cell.skillLabel.text = skill.typeName;
	cell.iconImageView.image = [UIImage imageNamed:level == 5 ? @"Icons/icon50_14.png" : @"Icons/icon50_13.png"];
	
	NSString* levelImageName = [NSString stringWithFormat:@"level_%d00.gif", level];
	[cell.levelImageView setGIFImageWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:levelImageName ofType:nil]]];
	
	//(item.level == 5 ? @"Icons/icon50_14.png" : @"Icons/icon50_13.png")
	//skill.levelImageName = [NSString stringWithFormat:@"level_%d%d%d.gif", item.level, targetLevel, isActive];
	//[cell.levelImageView setGIFImageWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:skill.levelImageName ofType:nil]]];

	//cell.characterNameLabel.text = [[[sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] name];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section == 0 || indexPath.section == 1;
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)] autorelease];
	header.opaque = NO;
	header.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9];
	
	UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, 0, 300, 22)] autorelease];
	label.opaque = NO;
	label.backgroundColor = [UIColor clearColor];
	label.text = [self tableView:tableView titleForHeaderInSection:section];
	label.textColor = [UIColor whiteColor];
	label.font = [label.font fontWithSize:12];
	label.shadowColor = [UIColor blackColor];
	label.shadowOffset = CGSizeMake(1, 1);
	[header addSubview:label];
	return header;
}

- (void)tableView:(UITableView*) tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	EVEDBInvType* skill = [[sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	NSString* key = [NSString stringWithFormat:@"%d", skill.typeID];

	SkillLevelsViewController* controller = (SkillLevelsViewController*) [modalController topViewController];
	controller.currentLevel = [[character.skills valueForKey:key] integerValue];
	controller.title = skill.typeName;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[popoverController presentPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] inView:tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	else
		[self presentModalViewController:modalController animated:YES];

	[modifiedIndexPath release];
	modifiedIndexPath = [indexPath retain];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	ItemViewController *itemViewController = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	
	itemViewController.type = [[sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	[itemViewController setActivePage:ItemViewControllerActivePageInfo];
	[self.navigationController pushViewController:itemViewController animated:YES];
	[itemViewController release];
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *button = [actionSheet buttonTitleAtIndex:buttonIndex];
	
	if ([button isEqualToString:ActionButtonDuplicate]) {
		self.character = [CharacterCustom characterWithCharacter:character];
		self.character.name = [self.character.name stringByAppendingString:NSLocalizedString(@" Copy", nil)];
		self.title = self.character.name;
		[character save];
	}
	else if ([button isEqualToString:ActionButtonRename]) {
		characterNameTextField.text = self.character.name;
		[characterNameTextField becomeFirstResponder];
	}
	else if ([button isEqualToString:ActionButtonDelete]) {
		NSString* path = [[[Character charactersDirectory] stringByAppendingPathComponent:self.character.guid] stringByAppendingPathExtension:@"plist"];
		[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
		[self.navigationController popViewControllerAnimated:YES];
	}
}

#pragma mark SkillLevelsViewControllerDelegate

- (void) skillLevelsViewController:(SkillLevelsViewController*) controller didSelectLevel:(NSInteger) level {
	if ([character isKindOfClass:[CharacterEVE class]]) {
		self.character = [CharacterCustom characterWithCharacter:character];
		self.character.name = [self.character.name stringByAppendingString:NSLocalizedString(@" Copy", nil)];
		self.title = self.character.name;
	}
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[popoverController dismissPopoverAnimated:YES];
	else 
		[self dismissModalViewControllerAnimated:YES];
	EVEDBInvType* skill = [[sections objectAtIndex:modifiedIndexPath.section] objectAtIndex:modifiedIndexPath.row];
	NSString* key = [NSString stringWithFormat:@"%d", skill.typeID];
	[character.skills setValue:[NSNumber numberWithInteger:level] forKey:key];
	[character save];
	[skillsTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:modifiedIndexPath] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
	self.character.name = characterNameTextField.text;
	[character save];
	[textField resignFirstResponder];
	return YES;
}

@end

@implementation CharacterSkillsEditorViewController(Private)

- (void) didReceiveRecord: (NSDictionary*) record {
	EVEDBInvType* skill = [EVEDBInvType invTypeWithDictionary:record];
	NSString* key = [NSString stringWithFormat:@"%d", skill.groupID];

	NSMutableArray* skills = [groups valueForKey:key];
	if (!skills) {
		skills = [NSMutableArray array];
		[groups setValue:skills forKey:key];
	}
	
	[skills addObject:skill];
}

- (void) keyboardWillShow: (NSNotification*) notification {
//	CGRect r = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:[[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]];
	[UIView setAnimationCurve:(UIViewAnimationCurve)[[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue]];
	shadowView.alpha = 1;
	characterNameToolbar.frame = CGRectMake(0, 0, characterNameToolbar.frame.size.width, characterNameToolbar.frame.size.height);
	[UIView commitAnimations];
}

- (void) keyboardWillHide: (NSNotification*) notification {
//	CGRect r = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:[[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]];
	[UIView setAnimationCurve:(UIViewAnimationCurve)[[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue]];
	shadowView.alpha = 0;
	characterNameToolbar.frame = CGRectMake(0, -characterNameToolbar.frame.size.height, characterNameToolbar.frame.size.width, characterNameToolbar.frame.size.height);
	self.title = characterNameTextField.text;
	[UIView commitAnimations];
}

@end
