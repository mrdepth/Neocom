//
//  NCFittingDamagePatternsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 04.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingDamagePatternsViewController.h"
#import "NCFittingDamagePatternCell.h"
#import "NCStorage.h"

@interface NCFittingDamagePatternsViewController ()
@property (nonatomic, strong) NSArray* customDamagePatterns;
@property (nonatomic, strong) NSArray* builtInDamagePatterns;
@end

@implementation NCFittingDamagePatternsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	NCStorage* storage = [NCStorage sharedStorage];
	NSMutableArray* builtInDamagePatterns = [NSMutableArray new];
	for (NSDictionary* dic in [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"damagePatterns" ofType:@"plist"]]) {
		NCDamagePattern* damagePattern = [[NCDamagePattern alloc] initWithEntity:[NSEntityDescription entityForName:@"DamagePattern" inManagedObjectContext:storage.managedObjectContext]
												  insertIntoManagedObjectContext:nil];
		damagePattern.name = dic[@"name"];
		damagePattern.em = [dic[@"em"] floatValue];
		damagePattern.kinetic = [dic[@"kinetic"] floatValue];
		damagePattern.thermal = [dic[@"thermal"] floatValue];
		damagePattern.explosive = [dic[@"explosive"] floatValue];
		[builtInDamagePatterns addObject:damagePattern];
	}
	self.builtInDamagePatterns = builtInDamagePatterns;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0)
		return 1;
	else if (section == 1)
		return self.customDamagePatterns.count;
	else
		return self.builtInDamagePatterns.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MenuItem0Cell"];
		return cell;
	}
	else {
		NCDamagePattern* damagePattern = self.builtInDamagePatterns[indexPath.row];
		NCFittingDamagePatternCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
		
		cell.emLabel.text = [NSString stringWithFormat:@"%.2f", damagePattern.em];
		cell.kineticLabel.text = [NSString stringWithFormat:@"%.2f", damagePattern.kinetic];
		cell.thermalLabel.text = [NSString stringWithFormat:@"%.2f", damagePattern.thermal];
		cell.explosiveLabel.text = [NSString stringWithFormat:@"%.2f", damagePattern.explosive];
		
		cell.emLabel.progress = damagePattern.em;
		cell.kineticLabel.progress = damagePattern.kinetic;
		cell.thermalLabel.progress = damagePattern.thermal;
		cell.explosiveLabel.progress = damagePattern.explosive;
		
		cell.titleLabel.text = damagePattern.name;
		return cell;
	}
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return nil;
	else if (section == 1)
		return NSLocalizedString(@"Custom", nil);
	else
		return NSLocalizedString(@"Predefined", nil);
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark -
#pragma mark Table view delegate

/*- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
 NSString* title = [self tableView:tableView titleForHeaderInSection:section];
 if (title) {
 CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
 view.titleLabel.text = title;
 view.collapsImageView.hidden = YES;
 return view;
 }
 else
 return nil;
 }
 
 - (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
 return [self tableView:tableView titleForHeaderInSection:section] ? 22 : 0;
 }*/

/*- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0)
		return 44;
	else {
		UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
		cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
		[cell setNeedsLayout];
		[cell layoutIfNeeded];
		return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
	}
}*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
