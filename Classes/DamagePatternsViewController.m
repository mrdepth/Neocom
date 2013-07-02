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
#import "CharacterCellView.h"
#import "DamagePatternEditViewController.h"
#import "ItemCellView.h"
#import "FittingNPCGroupsViewController.h"

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
	self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
	
	self.title = NSLocalizedString(@"Damage Patterns", nil);
	[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onClose:)]];
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

- (IBAction) onClose:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
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
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		static NSString *cellIdentifier = @"ItemCellView";
		
		ItemCellView *cell = (ItemCellView*) [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [ItemCellView cellWithNibName:@"ItemCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		cell.titleLabel.text = NSLocalizedString(@"Select NPC Type", nil);
		cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon04_07.png"];
		return cell;
	}
	else if ([[self.sections objectAtIndex:indexPath.section - 1] count] == indexPath.row) {
		NSString *cellIdentifier = @"CharacterCellView";
		
		CharacterCellView *cell = (CharacterCellView*) [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [CharacterCellView cellWithNibName:@"CharacterCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		cell.characterNameLabel.text = NSLocalizedString(@"Add Damage Pattern", nil);
		return cell;
	}
	else {
		static NSString *cellIdentifier = @"DamagePatternCellView";
		DamagePatternCellView *cell = (DamagePatternCellView*) [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [DamagePatternCellView cellWithNibName:@"DamagePatternCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		DamagePattern* damagePattern = [[self.sections objectAtIndex:indexPath.section - 1] objectAtIndex:indexPath.row];
		cell.titleLabel.text = damagePattern.patternName;
		cell.emLabel.progress = damagePattern.emAmount;
		cell.thermalLabel.progress = damagePattern.thermalAmount;
		cell.kineticLabel.progress = damagePattern.kineticAmount;
		cell.explosiveLabel.progress = damagePattern.explosiveAmount;
		cell.emLabel.text = [NSString stringWithFormat:@"%d%%", (int) (damagePattern.emAmount * 100)];
		cell.thermalLabel.text = [NSString stringWithFormat:@"%d%%", (int) (damagePattern.thermalAmount * 100)];
		cell.kineticLabel.text = [NSString stringWithFormat:@"%d%%", (int) (damagePattern.kineticAmount * 100)];
		cell.explosiveLabel.text = [NSString stringWithFormat:@"%d%%", (int) (damagePattern.explosiveAmount * 100)];
		cell.checkmarkImageView.image = [damagePattern isEqual:self.currentDamagePattern] ? [UIImage imageNamed:@"checkmark.png"] : nil;
		return cell;
	}
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

- (UIView *)tableView:(UITableView *)aTableView viewForHeaderInSection:(NSInteger)section {
	NSString *s = [self tableView:aTableView titleForHeaderInSection:section];
	UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)];
	header.opaque = NO;
	header.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9];
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 300, 22)];
	label.opaque = NO;
	label.backgroundColor = [UIColor clearColor];
	label.text = s;
	label.textColor = [UIColor whiteColor];
	label.font = [label.font fontWithSize:12];
	label.shadowColor = [UIColor blackColor];
	label.shadowOffset = CGSizeMake(1, 1);
	[header addSubview:label];
	return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section == 0 ? 36 : 44;
}

- (void)tableView:(UITableView*) tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.section == 0) {
		FittingNPCGroupsViewController *controller = [[FittingNPCGroupsViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"NPCGroupsViewControllerModal" : @"NPCGroupsViewController")
																					bundle:nil];
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

#pragma mark UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	popoverController.popoverContentSize = CGSizeMake(320, 1100);
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
