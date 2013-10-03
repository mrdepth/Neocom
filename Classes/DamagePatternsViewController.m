//
//  DamagePatternsViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DamagePatternsViewController.h"
#import "EVEDBAPI.h"
#import "DamagePatternCellView.h"
#import "UITableViewCell+Nib.h"
#import "Globals.h"
#import "ItemViewController.h"
#import "GroupedCell.h"
#import "DamagePatternEditViewController.h"
#import "FittingNPCGroupsViewController.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"
#import "UIViewController+Neocom.h"
#import "appearance.h"

@interface DamagePatternsViewController()
@property (nonatomic, strong) NSMutableArray *sections;

- (void) reload;
- (void) save;
@end

@implementation DamagePatternsViewController


// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
 if (self) {
 // Custom initialization.
 }
 return self;
 }
 */


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	
	self.title = NSLocalizedString(@"Damage Patterns", nil);
	[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)]];
	[self.navigationItem setRightBarButtonItem:self.editButtonItem];
	[self reload];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.sections = nil;
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.tableView reloadData];
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	[self.tableView setEditing:editing animated:animated];
	
	NSIndexPath* indexPath = [NSIndexPath indexPathForRow:[[self.sections objectAtIndex:1] count] inSection:2];
	NSArray* array = [NSArray arrayWithObject:indexPath];
	if (editing)
		[self.tableView insertRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationFade];
	else {
		[self.tableView deleteRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationFade];
		[self save];
	}
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    // Return the number of sections.
	return self.sections.count + 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0)
		return 1;
	NSInteger count = [[self.sections objectAtIndex:section - 1] count];
	if (section == 1 || !self.editing)
		return count;
	else
		return count + 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	GroupedCell *cell;
	if (indexPath.section == 0) {
		static NSString *cellIdentifier = @"Cell";
		
		cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		}
		cell.textLabel.text = NSLocalizedString(@"Select NPC Type", nil);
		cell.imageView.image = [UIImage imageNamed:@"Icons/icon04_07.png"];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	else if ([self.sections[indexPath.section - 1] count] == indexPath.row) {
		static NSString *cellIdentifier = @"Cell";
		
		cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		}
		cell.textLabel.text = NSLocalizedString(@"Add Damage Pattern", nil);
		cell.imageView.image = nil;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	else {
		static NSString *cellIdentifier = @"DamagePatternCellView";
		DamagePatternCellView *damagePatternCell = (DamagePatternCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (damagePatternCell == nil) {
			damagePatternCell = [DamagePatternCellView cellWithNibName:@"DamagePatternCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		DamagePattern* damagePattern = self.sections[indexPath.section - 1][indexPath.row];
		damagePatternCell.titleLabel.text = damagePattern.patternName;
		damagePatternCell.emLabel.progress = damagePattern.emAmount;
		damagePatternCell.thermalLabel.progress = damagePattern.thermalAmount;
		damagePatternCell.kineticLabel.progress = damagePattern.kineticAmount;
		damagePatternCell.explosiveLabel.progress = damagePattern.explosiveAmount;
		damagePatternCell.emLabel.text = [NSString stringWithFormat:@"%d%%", (int) (damagePattern.emAmount * 100)];
		damagePatternCell.thermalLabel.text = [NSString stringWithFormat:@"%d%%", (int) (damagePattern.thermalAmount * 100)];
		damagePatternCell.kineticLabel.text = [NSString stringWithFormat:@"%d%%", (int) (damagePattern.kineticAmount * 100)];
		damagePatternCell.explosiveLabel.text = [NSString stringWithFormat:@"%d%%", (int) (damagePattern.explosiveAmount * 100)];
		damagePatternCell.accessoryView = [damagePattern isEqual:self.currentDamagePattern] ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]] : nil;
		damagePatternCell.editingAccessoryType = indexPath.section == 2 ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
		cell = damagePatternCell;
	}
	
	GroupedCellGroupStyle groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = groupStyle;
	return cell;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return nil;
	else if (section == 1)
		return NSLocalizedString(@"Predefined", nil);
	else
		return NSLocalizedString(@"Custom", nil);
}

- (void)tableView:(UITableView *)aTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		[[self.sections objectAtIndex:indexPath.section - 1] removeObjectAtIndex:indexPath.row];
		[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		[self save];
	}
	else if (editingStyle == UITableViewCellEditingStyleInsert) {
		DamagePattern* damagePattern = [[DamagePattern alloc] init];
		[[self.sections objectAtIndex:indexPath.section - 1] addObject:damagePattern];
		[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];

		DamagePatternEditViewController* controller = [[DamagePatternEditViewController alloc] initWithNibName:@"DamagePatternEditViewController" bundle:nil];
		controller.damagePattern = damagePattern;
		[self.navigationController pushViewController:controller animated:YES];
	}
}

#pragma mark -
#pragma mark Table view delegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0 || indexPath.section == 1)
		return UITableViewCellEditingStyleNone;
	else
		return indexPath.row == [[self.sections objectAtIndex:indexPath.section - 1] count] ? UITableViewCellEditingStyleInsert : UITableViewCellEditingStyleDelete;
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section == 0 || [self.sections[indexPath.section - 1] count] == indexPath.row ? 40 : 44;
}

- (void)tableView:(UITableView*) tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.section == 0) {
		FittingNPCGroupsViewController *controller = [[FittingNPCGroupsViewController alloc] initWithNibName:@"NPCGroupsViewController"	bundle:nil];
		controller.modalMode = YES;
		controller.damagePatternsViewController = self;
		[self.navigationController pushViewController:controller animated:YES];
	}
	else if (indexPath.row == [[self.sections objectAtIndex:indexPath.section - 1] count]) {
		[self tableView:self.tableView commitEditingStyle:UITableViewCellEditingStyleInsert forRowAtIndexPath:indexPath];
	}
	else {
		if (self.editing) {
			if (indexPath.section == 2) {
				DamagePatternEditViewController* controller = [[DamagePatternEditViewController alloc] initWithNibName:@"DamagePatternEditViewController" bundle:nil];
				controller.damagePattern = [[self.sections objectAtIndex:indexPath.section - 1] objectAtIndex:indexPath.row];
				[self.navigationController pushViewController:controller animated:YES];
			}
		}
		else {
			[self.delegate damagePatternsViewController:self didSelectDamagePattern:[[self.sections objectAtIndex:indexPath.section - 1] objectAtIndex:indexPath.row]];
		}
	}
}

#pragma mark - Private

- (void) reload {
	self.sections = [[NSMutableArray alloc] init];
	[self.sections addObject:[NSArray arrayWithObject:[DamagePattern uniformDamagePattern]]];
	
	NSMutableArray* array = nil;
	NSString* path = [[Globals documentsDirectory] stringByAppendingPathComponent:@"damagePatterns.plist"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:path])
		path = [[NSBundle mainBundle] pathForResource:@"damagePatterns" ofType:@"plist"];

	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		NSData* data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:path]];
		if (data) {
			NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
			NSObject* object = [unarchiver decodeObject];
			if ([object isKindOfClass:[NSArray class]])
				array = [NSMutableArray arrayWithArray:(NSArray*) object];
		}
	}

	[self.sections addObject:array ? array : [NSMutableArray array]];
}

- (void) save {
	NSMutableData* data = [NSMutableData data];
	NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	[archiver encodeObject:[self.sections objectAtIndex:1]];
	[archiver finishEncoding];
	
	NSString* path = [[Globals documentsDirectory] stringByAppendingPathComponent:@"damagePatterns.plist"];
	[data writeToURL:[NSURL fileURLWithPath:path] atomically:YES];
}

@end
