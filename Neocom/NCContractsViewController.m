//
//  NCContractsViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 19.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCContractsViewController.h"
#import "EVEContractsItem+Neocom.h"


@interface NCContractsViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* contracts;
@end

@implementation NCContractsViewControllerData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.contracts = [aDecoder decodeObjectForKey:@"contracts"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.contracts)
		[aCoder encodeObject:self.contracts forKey:@"contracts"];
}

@end

@interface NCContractsViewController ()

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
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NCContractsViewControllerData* data = self.data;
	return data.contracts.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCContractsViewControllerData* data = self.data;
	EVEContractsItem* contract = data.contracts[indexPath.row];
	
/*	NCWalletJournalCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	if (!cell)
		cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];
	cell.object = row;
	
	cell.titleLabel.text = row.refType ? row.refType.refTypeName : [NSString stringWithFormat:NSLocalizedString(@"Unknown refTypeID %d", nil), [row.item refTypeID]];
	cell.dateLabel.text = [self.dateFormatter stringFromDate:[row.item date]];
	
	
	cell.balanceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Balance: %@ ISK", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@([row.item balance])]];
	
	float amount = [row.item amount];
	float taxAmount = 0;
	if ([row.item isKindOfClass:[EVECharWalletTransactionsItem class]])
		taxAmount = [row.item taxAmount];
	
	//cell.amountLabel.text = [NSString shortStringWithFloat:amount + taxAmount unit:@"ISK"];
	cell.amountLabel.textColor = amount > 0 ? [UIColor greenColor] : [UIColor redColor];
	cell.amountLabel.text = [NSString stringWithFormat:@"%@ ISK", [NSNumberFormatter neocomLocalizedStringFromNumber:@(amount + taxAmount)]];
	
	if (taxAmount > 0)
		cell.taxLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Tax: -%@ ISK (%d%%)", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(taxAmount)], (int)(taxAmount / (taxAmount + amount) * 100)];
	else
		cell.taxLabel.text = nil;
	
	NSString* ownerName1 = [row.item ownerName1];
	NSString* ownerName2 = [row.item ownerName2];
	if (ownerName1.length > 0 && ownerName2.length > 0)
		cell.characterNameLabel.text = [NSString stringWithFormat:@"%@ -> %@", ownerName1, ownerName2];
	else
		cell.characterNameLabel.text = ownerName1;
	return cell;*/
	return nil;
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 87;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
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
												 data.contracts = contracts.contractList;
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

- (void) didChangeAccount:(NCAccount *)account {
	[super didChangeAccount:account];
	if ([self isViewLoaded])
		[self reloadFromCache];
}

@end
