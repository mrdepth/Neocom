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

@interface POSViewController(Private)
- (void) loadData;
@end

@implementation POSViewController
@synthesize posTableView;
@synthesize controlTowerType;
@synthesize solarSystem;
@synthesize location;
@synthesize posID;
@synthesize sovereigntyBonus;

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
	self.title = location;
	[self loadData];
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.posTableView = nil;
	[sections release];
	sections = nil;
}


- (void)dealloc {
	[posTableView release];
	[controlTowerType release];
	[solarSystem release];
	[location release];

	[sections release];
    [super dealloc];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [sections count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[[sections objectAtIndex:section] valueForKey:@"rows"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [[sections objectAtIndex:section] valueForKey:@"title"];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"POSFuelCellView";
	
    POSFuelCellView *cell = (POSFuelCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [POSFuelCellView cellWithNibName:@"POSFuelCellView" bundle:nil reuseIdentifier:cellIdentifier];
    }
	NSDictionary *row = [[[sections objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
	EVEDBInvType *resourceType = [row valueForKey:@"type"];
	cell.typeNameLabel.text = resourceType.typeName;
	cell.remainsLabel.text = [row valueForKey:@"remains"];
	cell.consumptionLabel.text = [row valueForKey:@"consumption"];
	cell.remainsLabel.textColor = [row valueForKey:@"remainsColor"];
	cell.iconImageView.image = [UIImage imageNamed:[resourceType typeSmallImageName]];
	
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 36;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *row = [[[sections objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
	EVEDBInvType *resourceType = [row valueForKey:@"type"];

	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"ItemViewController-iPad" : @"ItemViewController")
																		  bundle:nil];
	controller.type = resourceType;
	[controller setActivePage:ItemViewControllerActivePageInfo];
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];

}

@end

@implementation POSViewController(Private)

- (void) loadData {
	NSMutableArray *sectionsTmp = [NSMutableArray array];
	EVEAccount *account = [EVEAccount currentAccount];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"POSViewController+Load" name:@"Loading POS Details"];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSError *error = nil;
		//EVEStarbaseDetail *starbaseDetail = [EVEStarbaseDetail starbaseDetailWithUserID:character.userID apiKey:character.apiKey characterID:character.characterID itemID:posID error:&error];
		EVEStarbaseDetail *starbaseDetail = [EVEStarbaseDetail starbaseDetailWithKeyID:account.corpKeyID vCode:account.corpVCode characterID:account.characterID itemID:posID error:&error];

		if (error) {
			[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
		}
		else {
			NSMutableDictionary *sectionsDictionary = [NSMutableDictionary dictionary];;
			float hours = [[starbaseDetail serverTimeWithLocalTime:[NSDate date]] timeIntervalSinceDate:starbaseDetail.currentTime] / 3600.0;
			if (hours < 0)
				hours = 0;
			float n = [[controlTowerType resources] count];
			float i = 0;
			for (EVEDBInvControlTowerResource *resource in [controlTowerType resources]) {
				operation.progress = i++ / n;
				if ((resource.minSecurityLevel > 0 && solarSystem.security < resource.minSecurityLevel) ||
					(resource.factionID > 0 && solarSystem.region.factionID != resource.factionID))
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
						quantity = item.quantity - hours * round(resource.quantity * sovereigntyBonus);
						break;
					}
				}
				
				UIColor *remainsColor;
				NSMutableString *remains = [NSMutableString stringWithString:[NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:quantity] numberStyle:NSNumberFormatterDecimalStyle]];
				if (quantity > 0) {
					if (resource.purposeID != 2 && resource.purposeID != 3) {
						NSTimeInterval remainsTime = quantity / round(resource.quantity * sovereigntyBonus) * 3600;
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
					consumption = @"n/a";
				else
					consumption = [NSString stringWithFormat:@"%@/h", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:round(resource.quantity * sovereigntyBonus)] numberStyle:NSNumberFormatterDecimalStyle]];
				
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
		
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		[sections release];
		sections = [sectionsTmp retain];
		[posTableView reloadData];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end
