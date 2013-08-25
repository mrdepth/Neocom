//
//  POSViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 3/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "POSViewController.h"
#import "EVEDBAPI.h"
#import "EVEOnlineAPI.h"
#import "POSFuelCellView.h"
#import "UITableViewCell+Nib.h"
#import "Globals.h"
#import "EVEAccount.h"
#import "UIAlertView+Error.h"
#import "ItemViewController.h"
#import "NSString+TimeLeft.h"
#import "appearance.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"

@interface POSViewController()
@property (nonatomic, strong) NSArray *sections;

- (void) loadData;
@end

@implementation POSViewController


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
	self.title = self.location;
	[self loadData];
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


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [self.sections count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[[self.sections objectAtIndex:section] valueForKey:@"rows"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [[self.sections objectAtIndex:section] valueForKey:@"title"];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"POSFuelCellView";
	
    POSFuelCellView *cell = (POSFuelCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [POSFuelCellView cellWithNibName:@"POSFuelCellView" bundle:nil reuseIdentifier:cellIdentifier];
    }
	NSDictionary *row = [[[self.sections objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
	EVEDBInvType *resourceType = [row valueForKey:@"type"];
	cell.typeNameLabel.text = resourceType.typeName;
	cell.remainsLabel.text = [row valueForKey:@"remains"];
	cell.consumptionLabel.text = [row valueForKey:@"consumption"];
	cell.remainsLabel.textColor = [row valueForKey:@"remainsColor"];
	cell.iconImageView.image = [UIImage imageNamed:[resourceType typeSmallImageName]];
	
	GroupedCellGroupStyle groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = groupStyle;
	return cell;
}


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */


/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source.
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
 }   
 }
 */


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */


/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */


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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *row = [[[self.sections objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
	EVEDBInvType *resourceType = [row valueForKey:@"type"];

	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	controller.type = resourceType;
	[controller setActivePage:ItemViewControllerActivePageInfo];
	[self.navigationController pushViewController:controller animated:YES];

}

#pragma mark - Private

- (void) loadData {
	NSMutableArray *sectionsTmp = [NSMutableArray array];
	EVEAccount *account = [EVEAccount currentAccount];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"POSViewController+Load" name:NSLocalizedString(@"Loading POS Details", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		NSError *error = nil;
		EVEStarbaseDetail *starbaseDetail = [EVEStarbaseDetail starbaseDetailWithKeyID:account.corpAPIKey.keyID vCode:account.corpAPIKey.vCode characterID:account.character.characterID itemID:self.posID error:&error progressHandler:nil];

		if (error) {
			[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
		}
		else {
			NSMutableDictionary *sectionsDictionary = [NSMutableDictionary dictionary];;
			float hours = [[starbaseDetail serverTimeWithLocalTime:[NSDate date]] timeIntervalSinceDate:starbaseDetail.currentTime] / 3600.0;
			if (hours < 0)
				hours = 0;
			float n = [[self.controlTowerType resources] count];
			float i = 0;
			for (EVEDBInvControlTowerResource *resource in [self.controlTowerType resources]) {
				weakOperation.progress = i++ / n;
				if ((resource.minSecurityLevel > 0 && self.solarSystem.security < resource.minSecurityLevel) ||
					(resource.factionID > 0 && self.solarSystem.region.factionID != resource.factionID))
					continue;
				NSMutableDictionary *section = [sectionsDictionary valueForKey:[NSString stringWithFormat:@"%d", resource.purposeID]];
				if (!section) {
					section = [NSMutableDictionary dictionaryWithObjectsAndKeys:
							   [NSMutableArray array], @"rows",
							   resource.purpose.purposeText, @"title",
							   [NSString stringWithFormat:@"%d", resource.purposeID], @"purposeID",
							   nil];
					[sectionsDictionary setValue:section forKey:[NSString stringWithFormat:@"%d", resource.purposeID]];
				}
				NSMutableArray *rows = [section valueForKey:@"rows"];
				
				int quantity = 0;
				for (EVEStarbaseDetailFuelItem *item in starbaseDetail.fuel) {
					if (item.typeID == resource.resourceTypeID) {
						quantity = item.quantity - hours * round(resource.quantity * self.sovereigntyBonus);
						break;
					}
				}
				
				UIColor *remainsColor;
				NSMutableString *remains = [NSMutableString stringWithString:[NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:quantity] numberStyle:NSNumberFormatterDecimalStyle]];
				if (quantity > 0) {
					if (resource.purposeID != 2 && resource.purposeID != 3) {
						NSTimeInterval remainsTime = quantity / round(resource.quantity * self.sovereigntyBonus) * 3600;
						if (remainsTime > 3600 * 24)
							remainsColor = [UIColor greenColor];
						else if (remainsTime > 3600)
							remainsColor = [UIColor yellowColor];
						else
							remainsColor = [UIColor redColor];
						[remains appendFormat:@" (%@)", [NSString stringWithTimeLeft:remainsTime]];
					}
					else
						remainsColor = [UIColor greenColor];
				}
				else {
					remainsColor = [UIColor redColor];
					[remains appendFormat:@" (0s)"];
				}
				
				NSString *consumption;
				if (resource.purposeID == 2 || resource.purposeID == 3)
					consumption = NSLocalizedString(@"n/a", nil);
				else
					consumption = [NSString stringWithFormat:NSLocalizedString(@"%@/h", nil), [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:round(resource.quantity * self.sovereigntyBonus)] numberStyle:NSNumberFormatterDecimalStyle]];
				
				NSDictionary *row = [NSDictionary dictionaryWithObjectsAndKeys:
									 resource.resourceType, @"type",
									 remains, @"remains",
									 remainsColor, @"remainsColor",
									 consumption, @"consumption",
									 nil];
				[rows addObject:row];
			}
			[sectionsTmp addObjectsFromArray:[[sectionsDictionary allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"purposeID" ascending:YES]]]];
		}
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		self.sections = sectionsTmp;
		[self.tableView reloadData];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end
