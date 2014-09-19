//
//  NCContractsViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 19.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCContractsViewController.h"
#import "EVEContractsItem+Neocom.h"
#import "NCContractsCell.h"
#import "NSNumberFormatter+Neocom.h"
#import "NSString+Neocom.h"
#import "NCContractsDetailsViewController.h"


@interface NCContractsViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* activeContracts;
@property (nonatomic, strong) NSArray* finishedContracts;
@property (nonatomic, strong) NSDate* currentTime;
@property (nonatomic, strong) NSDate* cacheDate;
@end

@implementation NCContractsViewControllerData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.activeContracts = [aDecoder decodeObjectForKey:@"activeContracts"];
		self.finishedContracts = [aDecoder decodeObjectForKey:@"finishedContracts"];
		if (!self.activeContracts)
			self.activeContracts = @[];
		if (!self.finishedContracts)
			self.finishedContracts = @[];
		
		self.currentTime = [aDecoder decodeObjectForKey:@"currentTime"];
		self.cacheDate = [aDecoder decodeObjectForKey:@"cacheDate"];
		
		NSDictionary* locations = [aDecoder decodeObjectForKey:@"locations"];
		NSDictionary* names = [aDecoder decodeObjectForKey:@"names"];
		
		for (NSArray* array in @[self.activeContracts, self.finishedContracts]) {
			for (EVEContractsItem* contract in array) {
				contract.startStation = locations[@(contract.startStationID)];
				contract.endStation = locations[@(contract.endStationID)];
				contract.issuerName = names[@(contract.issuerID)];
				contract.issuerCorpName = names[@(contract.issuerCorpID)];
				contract.assigneeName = names[@(contract.assigneeID)];
				contract.acceptorName = names[@(contract.acceptorID)];
				contract.forCorpName = names[@(contract.forCorp)];
			}
		}
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.activeContracts)
		[aCoder encodeObject:self.activeContracts forKey:@"activeContracts"];
	else
		self.activeContracts = @[];
	
	if (self.finishedContracts)
		[aCoder encodeObject:self.finishedContracts forKey:@"finishedContracts"];
	else
		self.finishedContracts = @[];
	
	if (self.currentTime)
		[aCoder encodeObject:self.currentTime forKey:@"currentTime"];
	if (self.cacheDate)
		[aCoder encodeObject:self.cacheDate forKey:@"cacheDate"];
	
	NSMutableDictionary* locations = [NSMutableDictionary new];
	NSMutableDictionary* names = [NSMutableDictionary new];
	
	for (NSArray* array in @[self.activeContracts, self.finishedContracts]) {
		for (EVEContractsItem* contract in array) {
			if (contract.startStation)
				locations[@(contract.startStationID)] = contract.startStation;
			if (contract.endStation)
				locations[@(contract.endStationID)] = contract.endStation;
			
			if (contract.issuerName)
				names[@(contract.issuerID)] = contract.issuerName;
			if (contract.issuerCorpName)
				names[@(contract.issuerCorpID)] = contract.issuerCorpName;
			if (contract.assigneeName)
				names[@(contract.assigneeID)] = contract.assigneeName;
			if (contract.acceptorName)
				names[@(contract.acceptorID)] = contract.acceptorName;
			if (contract.forCorpName)
				names[@(contract.forCorp)] = contract.forCorpName;
		}
	}
	[aCoder encodeObject:locations forKey:@"locations"];
	[aCoder encodeObject:names forKey:@"names"];

	
}

@end

@interface NCContractsViewController ()
@property (nonatomic, strong) NSDate* currentDate;
@property (nonatomic, strong) NSDateFormatter* dateFormatter;
@end

@implementation NCContractsViewController

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
	self.dateFormatter = [[NSDateFormatter alloc] init];
	[self.dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm"];
	[self.dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCContractsDetailsViewController"]) {
		NCContractsDetailsViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		controller.contract = [sender object];
		controller.currentDate = self.currentDate;
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NCContractsViewControllerData* data = self.data;
	return data.activeContracts.count + data.finishedContracts.count > 0 ? 2 : 0;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NCContractsViewControllerData* data = self.data;
	return section == 0 ? data.activeContracts.count : data.finishedContracts.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCContractsCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 165;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [self tableView:tableView offscreenCellWithIdentifier:@"Cell"];
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell layoutIfNeeded];
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1)
		return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
	else
		return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize withHorizontalFittingPriority:1000 verticalFittingPriority:1].height + 1.0;
}



#pragma mark - NCTableViewController

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	__block NSError* error = nil;
	NCAccount* account = [NCAccount currentAccount];
	if (!account) {
		[self didFinishLoadData:nil withCacheDate:nil expireDate:nil];
		return;
	}
	
	NCContractsViewControllerData* data = [NCContractsViewControllerData new];
	__block NSDate* cacheExpireDate = [NSDate dateWithTimeIntervalSinceNow:[self defaultCacheExpireTime]];
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 BOOL corporate = account.accountType == NCAccountTypeCorporate;
											 
											 EVEContracts* contracts = [EVEContracts contractsWithKeyID:account.apiKey.keyID
																								  vCode:account.apiKey.vCode
																							cachePolicy:cachePolicy
																							characterID:account.characterID
																							  corporate:corporate
																								  error:&error
																						progressHandler:^(CGFloat progress, BOOL *stop) {
																							task.progress = progress;
																						}];
											 if (contracts) {
												 cacheExpireDate = contracts.cacheExpireDate;
												 
												 NSMutableSet* locationsIDs = [NSMutableSet new];
												 NSMutableSet* characterIDs = [NSMutableSet new];
												 
												 NSMutableArray* activeContracts = [NSMutableArray new];
												 NSMutableArray* finishedContracts = [NSMutableArray new];

												 for (EVEContractsItem* contract in contracts.contractList) {
													 if (contract.startStationID)
														 [locationsIDs addObject:@(contract.startStationID)];
													 if (contract.endStationID)
														 [locationsIDs addObject:@(contract.endStationID)];
													 if (contract.issuerID)
														 [characterIDs addObject:@(contract.issuerID)];
													 if (contract.issuerCorpID)
														 [characterIDs addObject:@(contract.issuerCorpID)];
													 if (contract.acceptorID)
														 [characterIDs addObject:@(contract.acceptorID)];
													 if (contract.assigneeID)
														 [characterIDs addObject:@(contract.assigneeID)];
													 if (contract.forCorp)
														 [characterIDs addObject:@(contract.forCorp)];
													 if (contract.status <= EVEContractStatusCompletedByContractor || contract.status >= EVEContractStatusCancelled)
														 [finishedContracts addObject:contract];
													 else
														 [activeContracts addObject:contract];

												 }
												 
												 NSDictionary* locationNames = nil;
												 if (locationsIDs.count > 0)
													 locationNames = [[NCLocationsManager defaultManager] locationsNamesWithIDs:[locationsIDs allObjects]];
												 
												 EVECharacterName* characterName = nil;
												 if (characterIDs.count > 0)
													 characterName = [EVECharacterName characterNameWithIDs:[characterIDs sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES selector:@selector(compare:)]]]
																								cachePolicy:NSURLRequestUseProtocolCachePolicy
																									  error:nil
																							progressHandler:nil];
												 
												 for (EVEContractsItem* contract in contracts.contractList) {
													 contract.startStation = locationNames[@(contract.startStationID)];
													 contract.endStation = locationNames[@(contract.endStationID)];
													 contract.issuerName = characterName.characters[@(contract.issuerID)];
													 contract.issuerCorpName = characterName.characters[@(contract.issuerCorpID)];
													 contract.acceptorName = characterName.characters[@(contract.acceptorID)];
													 contract.assigneeName = characterName.characters[@(contract.assigneeID)];
													 contract.forCorpName = characterName.characters[@(contract.forCorp)];
													 
													 
												 }
												 [activeContracts sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"dateExpired" ascending:YES]]];
												 [finishedContracts sortUsingComparator:^NSComparisonResult(EVEContractsItem* obj1, EVEContractsItem* obj2) {
													 NSDate* a = obj1.dateCompleted ? obj1.dateCompleted : obj1.dateExpired;
													 NSDate* b = obj2.dateCompleted ? obj2.dateCompleted : obj2.dateExpired;
													 return [b compare:a];
												 }];
												 
												 data.activeContracts = activeContracts;
												 data.finishedContracts = finishedContracts;
												 data.currentTime = contracts.currentTime;
												 data.cacheDate = contracts.cacheDate;
											 }
										 }
							 completionHandler:^(NCTask *task) {
								 if (!task.isCancelled) {
									 if (error) {
										 [self didFailLoadDataWithError:error];
									 }
									 else {
										 [self didFinishLoadData:data withCacheDate:[NSDate date] expireDate:cacheExpireDate];
									 }
								 }
							 }];
}

- (void) update {
	[super update];
	NCContractsViewControllerData* data = self.data;
	self.currentDate = [NSDate dateWithTimeInterval:[data.currentTime timeIntervalSinceDate:data.cacheDate] sinceDate:[NSDate date]];
}

- (void) didChangeAccount:(NCAccount *)account {
	[super didChangeAccount:account];
	if ([self isViewLoaded])
		[self reloadFromCache];
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCContractsViewControllerData* data = self.data;
	EVEContractsItem* row = indexPath.section == 0 ? data.activeContracts[indexPath.row] : data.finishedContracts[indexPath.row];
	NCContractsCell* cell = (NCContractsCell*) tableViewCell;
	
	cell.object = row;
	cell.titleLabel.text = row.title;
	cell.typeLabel.text = [row localizedTypeString];
	cell.locationLabel.text = row.startStation.name;

	if (row.price > 0) {
		cell.priceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(row.price)]];
		cell.priceTitleLabel.text = NSLocalizedString(@"Price:", nil);
	}
	else {
		cell.priceLabel.text = nil;
		cell.priceTitleLabel.text = nil;
	}
	
	if (row.buyout > 0) {
		cell.buyoutLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(row.buyout)]];
		cell.buyoutTitleLabel.text = NSLocalizedString(@"Buyout:", nil);
	}
	else {
		cell.buyoutLabel.text = nil;
		cell.buyoutTitleLabel.text = nil;
	}

	if (row.reward > 0) {
		cell.rewardLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(row.reward)]];
		cell.rewardTitleLabel.text = NSLocalizedString(@"Reward:", nil);
	}
	else {
		cell.rewardLabel.text = nil;
		cell.rewardTitleLabel.text = nil;
	}

	if (row.collateral > 0) {
		cell.collateralLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(row.collateral)]];
		cell.collateralTitleLabel.text = NSLocalizedString(@"Collateral:", nil);
	}
	else {
		cell.collateralLabel.text = nil;
		cell.collateralTitleLabel.text = nil;
	}
	
	cell.issuerLabel.text = row.issuerName;
	cell.dateLabel.text = [self.dateFormatter stringFromDate:row.dateIssued];
	
	UIColor* color = nil;
	NSString* status = nil;
	if (row.status <= EVEContractStatusCompletedByContractor) {
		status = [NSString stringWithFormat:NSLocalizedString(@"%@: %@", nil), [row localizedStatusString], [self.dateFormatter stringFromDate:row.dateCompleted]];
		color = [UIColor greenColor];
	}
	else if (row.status >= EVEContractStatusCancelled) {
		status = [row localizedStatusString];
		color = [UIColor redColor];
	}
	else {
		NSTimeInterval remainsTime = [row.dateExpired timeIntervalSinceDate:self.currentDate];
		if (remainsTime > 0) {
			status = [NSString stringWithFormat:@"%@: %@", [row localizedStatusString], [NSString stringWithTimeLeft:remainsTime]];
			color = [UIColor yellowColor];
		}
		else {
			status = [row localizedStatusString];
			color = [UIColor greenColor];
		}
	}
	cell.statusLabel.text = status;
	cell.statusLabel.textColor = color;
}

@end
