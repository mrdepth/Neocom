//
//  ContractsViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ContractViewController.h"
#import "EVEDBAPI.h"
#import "EVEOnlineAPI.h"
#import "POSFuelCellView.h"
#import "UITableViewCell+Nib.h"
#import "Globals.h"
#import "EVEAccount.h"
#import "UIAlertView+Error.h"
#import "ItemViewController.h"
#import "NSString+TimeLeft.h"
#import "ItemCellView.h"
#import "ContractInfoCellView.h"
#import "BidCellView.h"

@interface ContractViewController()
@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSMutableDictionary *conquerableStations;

- (void) loadData;
- (NSString*) stationNameWithID:(NSInteger) stationID;

@end

@implementation ContractViewController

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
	[self.tableView setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]]];
	self.title = NSLocalizedString(@"Contract", nil);
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
	self.conquerableStations = nil;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [self.sections count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[self.sections objectAtIndex:section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//	if ([self tableView:tableView numberOfRowsInSection:section] == 0)
//		return nil;

	switch (section) {
		case 0:
			return NSLocalizedString(@"Contract Details", nil);
			break;
		case 1:
			return NSLocalizedString(@"Buyer will get", nil);
			break;
		case 2:
			return NSLocalizedString(@"Buyer will pay", nil);
			break;
		case 3:
			return NSLocalizedString(@"Bids", nil);
			break;
		default:
			break;
	}
	return nil;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *row = [[self.sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	if (indexPath.section == 0) {
		NSString *cellIdentifier = @"ContractInfoCellView";
		
		ContractInfoCellView *cell = (ContractInfoCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [ContractInfoCellView cellWithNibName:@"ContractInfoCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		
		cell.titleLabel.text = [row valueForKey:@"title"];
		cell.valueLabel.text = [row valueForKey:@"value"];
		return cell;
	}
	else if (indexPath.section == 3) {
		NSString *cellIdentifier = @"BidCellView";
		
		BidCellView *cell = (BidCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [BidCellView cellWithNibName:@"BidCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		
		cell.amountLabel.text = [row valueForKey:@"amount"];
		cell.dateLabel.text = [row valueForKey:@"date"];
		cell.characterNameLabel.text = [row valueForKey:@"bidderName"];
		return cell;
	}
	else {
		NSString *cellIdentifier = @"ItemCellView";
		
		ItemCellView *cell = (ItemCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [ItemCellView cellWithNibName:@"ItemCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		EVEDBInvType *type = [row valueForKey:@"type"];
		cell.titleLabel.text = [NSString stringWithFormat:@"%@ (x%@)", type.typeName, [row valueForKey:@"quantity"]];;
		cell.iconImageView.image = [UIImage imageNamed:[type typeSmallImageName]];
		if (cell.iconImageView.image.size.width < cell.iconImageView.frame.size.width)
			cell.iconImageView.contentMode = UIViewContentModeCenter;
		else
			cell.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
		
		return cell;
	}
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
	UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)];
	header.opaque = NO;
	header.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9];
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 300, 22)];
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
	return indexPath.section == 0 ? 20 : 36;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.section == 1 || indexPath.section == 2) {
		NSDictionary *row = [[self.sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
		EVEDBInvType *resourceType = [row valueForKey:@"type"];
		
		ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		controller.type = resourceType;
		[controller setActivePage:ItemViewControllerActivePageInfo];
		
/*		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentModalViewController:navController animated:YES];
			[navController release];
		}
		else*/
			[self.navigationController pushViewController:controller animated:YES];
	}
	
}

#pragma mark - Private

- (void) loadData {
	NSMutableArray *sectionsTmp = [NSMutableArray array];
	EVEAccount *account = [EVEAccount currentAccount];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"ContractViewController+Load" name:NSLocalizedString(@"Loading Contract Details", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		NSError *error = nil;
		
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
		[dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm:ss"];

		NSMutableArray *rows = [NSMutableArray array];

		if (self.contract.title.length > 0)
			[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Title:", nil), @"title", self.contract.title, @"value", nil]];
		[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Status:", nil), @"title", [self.contract localizedStatusString], @"value", nil]];
		[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Type:", nil), @"title", [self.contract localizedTypeString], @"value", nil]];

		if (self.contract.startStationID)
			[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Start Station:", nil), @"title", [self stationNameWithID:self.contract.startStationID], @"value", nil]];
		if (self.contract.endStationID)
			[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"End Station:", nil), @"title", [self stationNameWithID:self.contract.endStationID], @"value", nil]];
		if (self.contract.dateIssued)
			[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Issued:", nil), @"title", [dateFormatter stringFromDate:self.contract.dateIssued], @"value", nil]];
		if (self.contract.dateAccepted)
			[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Accepted:", nil), @"title", [dateFormatter stringFromDate:self.contract.dateAccepted], @"value", nil]];
		if (self.contract.dateCompleted)
			[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Completed:", nil), @"title", [dateFormatter stringFromDate:self.contract.dateCompleted], @"value", nil]];
		if (self.contract.dateExpired)
			[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Expired:", nil), @"title", [dateFormatter stringFromDate:self.contract.dateExpired], @"value", nil]];
		
		NSMutableSet *charIDs = [NSMutableSet set];
		if (self.contract.issuerID) {
			NSString *key = [NSString stringWithFormat:@"%d", self.contract.issuerID];
			[charIDs addObject:key];
		}
		if (self.contract.acceptorID) {
			NSString *key = [NSString stringWithFormat:@"%d", self.contract.acceptorID];
			[charIDs addObject:key];
		}
		if (self.contract.assigneeID) {
			NSString *key = [NSString stringWithFormat:@"%d", self.contract.assigneeID];
			[charIDs addObject:key];
		}
		
		if (charIDs.count > 0) {
			NSError *error = nil;
			EVECharacterName *characterNames = [EVECharacterName characterNameWithIDs:[charIDs allObjects] error:&error progressHandler:nil];
			if (!error) {
				if (self.contract.issuerID)
					[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Issued By:", nil), @"title", [characterNames.characters valueForKey:[NSString stringWithFormat:@"%d", self.contract.issuerID]], @"value", nil]];
				if (self.contract.acceptorID)
					[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Accepted By:", nil), @"title", [characterNames.characters valueForKey:[NSString stringWithFormat:@"%d", self.contract.acceptorID]], @"value", nil]];
				if (self.contract.assigneeID)
					[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Assigned To:", nil), @"title", [characterNames.characters valueForKey:[NSString stringWithFormat:@"%d", self.contract.assigneeID]], @"value", nil]];
			}
		}
			
		if (self.contract.price > 0)
			[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Price:", nil), @"title", [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:self.contract.price] numberStyle:NSNumberFormatterDecimalStyle]], @"value", nil]];
		if (self.contract.reward > 0)
			[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Reward:", nil), @"title", [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:self.contract.reward] numberStyle:NSNumberFormatterDecimalStyle]], @"value", nil]];
		if (self.contract.buyout > 0)
			[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Buyout:", nil), @"title", [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:self.contract.buyout] numberStyle:NSNumberFormatterDecimalStyle]], @"value", nil]];
		if (self.contract.volume > 0)
			[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Volume:", nil), @"title", [NSString stringWithFormat:NSLocalizedString(@"%@ m3", nil), [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:self.contract.volume] numberStyle:NSNumberFormatterDecimalStyle]], @"value", nil]];

		[sectionsTmp addObject:rows];
		
		EVEContractItems *contractItems;
		if (self.corporate)
			contractItems = [EVEContractItems contractItemsWithKeyID:account.corpAPIKey.keyID vCode:account.corpAPIKey.vCode characterID:account.character.characterID contractID:self.contract.contractID corporate:self.contract error:&error progressHandler:nil];
		else
			contractItems = [EVEContractItems contractItemsWithKeyID:account.charAPIKey.keyID vCode:account.charAPIKey.vCode characterID:account.character.characterID contractID:self.contract.contractID corporate:self.contract error:&error progressHandler:nil];

		weakOperation.progress = 0.5;
		
		if (error) {
			[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
		}
		else {
			NSMutableArray *sell = [NSMutableArray array];
			NSMutableArray *buy = [NSMutableArray array];
			for (EVEContractItemsItem *item in contractItems.itemList) {
				EVEDBInvType *type = [EVEDBInvType invTypeWithTypeID:item.typeID error:nil];
				if (type) {
					NSInteger quantity = item.rawQuantity > 0 ? item.rawQuantity : item.quantity;
					NSDictionary *row = [NSDictionary dictionaryWithObjectsAndKeys:
										 type, @"type",
										 [NSString stringWithFormat:@"%@", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:quantity] numberStyle:NSNumberFormatterDecimalStyle]], @"quantity",
										 nil];
					if (item.included)
						[sell addObject:row];
					else
						[buy addObject:row];
				}
			}
			[sectionsTmp addObject:sell];
			[sectionsTmp addObject:buy];
			
			weakOperation.progress = 0.75;

			EVEContractBids *contractBids;
			if (self.corporate)
				contractBids = [EVEContractBids contractBidsWithKeyID:account.corpAPIKey.keyID vCode:account.corpAPIKey.vCode characterID:account.character.characterID corporate:self.contract error:&error progressHandler:nil];
			else
				contractBids = [EVEContractBids contractBidsWithKeyID:account.charAPIKey.keyID vCode:account.charAPIKey.vCode characterID:account.character.characterID corporate:self.contract error:&error progressHandler:nil];

			if (error) {
				[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
			}
			else {
				NSMutableSet *charIDs = [NSMutableSet set];
				NSMutableArray *rows = [NSMutableArray array];
				for (EVEContractBidsItem *item in contractBids.bidList) {
					if (item.contractID != self.contract.contractID)
						continue;
					NSString *bidderID = [NSString stringWithFormat:@"%d", item.bidderID];
					[charIDs addObject:bidderID];
						
					NSMutableDictionary *row = [NSMutableDictionary dictionaryWithObjectsAndKeys:
												bidderID, @"bidderID",
												@"", @"bidderName",
												[NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:item.amount] numberStyle:NSNumberFormatterDecimalStyle]], @"amount",
												[dateFormatter stringFromDate:item.dateBid], @"date",
												nil];
					[rows addObject:row];
				}
				
				if (charIDs.count > 0) {
					NSError *error = nil;
					EVECharacterName *characterNames = [EVECharacterName characterNameWithIDs:[charIDs allObjects] error:&error progressHandler:nil];
					if (!error) {
						for (NSMutableDictionary *row in rows) {
							NSString *bidderID = [row valueForKey:@"bidderID"];
							NSString *charName = [characterNames.characters valueForKey:bidderID];
							if (!charName)
								charName = @"";
							[row setValue:charName forKey:@"bidderName"];
						}
					}
				}

				
				[sectionsTmp addObject:rows];
			}
			weakOperation.progress = 1.0;
		}
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		self.sections = sectionsTmp;
		[self.tableView reloadData];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (NSString*) stationNameWithID:(NSInteger) stationID {
	EVEDBStaStation *station = [EVEDBStaStation staStationWithStationID:self.contract.startStationID error:nil];
	NSString *stationName = nil;
	
	if (!station) {
		EVEConquerableStationListItem *conquerableStation = self.conquerableStations[@(self.contract.startStationID)];
		if (conquerableStation) {
			EVEDBMapSolarSystem *solarSystem = [EVEDBMapSolarSystem mapSolarSystemWithSolarSystemID:conquerableStation.solarSystemID error:nil];
			if (solarSystem)
				stationName = [NSString stringWithFormat:@"%@ / %@", conquerableStation.stationName, solarSystem.solarSystemName];
			else
				stationName = conquerableStation.stationName;
		}
		else
			stationName = NSLocalizedString(@"Unknown Location", nil);
	}
	else
		stationName = [NSString stringWithFormat:@"%@ / %@", station.stationName, station.solarSystem.solarSystemName];
	return stationName;
}

- (NSMutableDictionary*) conquerableStations {
	if (!_conquerableStations) {
		@autoreleasepool {
			_conquerableStations = [[NSMutableDictionary alloc] init];
			
			NSError *error = nil;
			EVEConquerableStationList *stationsList = [EVEConquerableStationList conquerableStationListWithError:&error progressHandler:nil];
			
			if (!error) {
				for (EVEConquerableStationListItem *station in stationsList.outposts)
					_conquerableStations[@(station.stationID)] = station;
			}
		}
	}
	return _conquerableStations;
}

@end
