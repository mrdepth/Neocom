//
//  NCFittingBattleClinicSearchResultsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 12.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingBattleClinicSearchResultsViewController.h"
#import "BattleClinicAPI.h"
#import "NCFittingBattleClinicSearchResultsCell.h"
#import "NSString+HTML.h"
#import "NCFittingShipViewController.h"
#import "UIAlertView+Error.h"

@interface NCFittingBattleClinicSearchResultsViewController ()
@property (nonatomic, strong) UIImage* typeImage;
@end

@implementation NCFittingBattleClinicSearchResultsViewController

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
	self.typeImage = [UIImage imageNamed:[self.type typeSmallImageName]];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCFittingShipViewController"]) {
		NCFittingShipViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.fit = sender;
	}
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSArray* loadouts = self.data;
	return loadouts.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCFittingBattleClinicSearchResultsCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	NSArray* loadouts = self.data;
	BCEveLoadoutsListItem* loadout = [loadouts objectAtIndex:indexPath.row];
	cell.titleLabel.text = [loadout.subject stringByReplacingHTMLEscapes];
	cell.typeImageView.image = self.typeImage;
	cell.thumbsUpCountLabel.text = [NSString stringWithFormat:@"%d", loadout.thumbsUp];
	cell.thumbsDownCountLabel.text = [NSString stringWithFormat:@"%d", loadout.thumbsDown];
	cell.object = loadout;
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 42;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSArray* loadouts = self.data;
	BCEveLoadoutsListItem* row = [loadouts objectAtIndex:indexPath.row];

	__block NSError* error = nil;
	__block NCShipFit* shipFit = nil;
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 BCEveLoadout *loadout = [BCEveLoadout eveLoadoutsWithAPIKey:NCBattleClinicAPIKey loadoutID:row.loadoutID error:&error progressHandler:nil];
											 shipFit = [[NCShipFit alloc] initWithBattleClinicLoadout:loadout];
										 }
							 completionHandler:^(NCTask *task) {
								 if (error)
									 [[UIAlertView alertViewWithError:error] show];
								 else {
									 [self performSegueWithIdentifier:@"NCFittingShipViewController" sender:shipFit];
								 }
							 }];
}

#pragma mark - NCTableViewController

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	__block NSError* error = nil;
	__block NSArray* loadouts = nil;
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 BCEveLoadoutsList *loadoutsList = [BCEveLoadoutsList eveLoadoutsListWithAPIKey:NCBattleClinicAPIKey raceID:0 typeID:self.type.typeID classID:0 userID:0 tags:self.tags error:&error progressHandler:nil];
											 loadouts = loadoutsList.loadouts;
										 }
							 completionHandler:^(NCTask *task) {
								 if (!task.isCancelled) {
									 if (error) {
										 [self didFailLoadDataWithError:error];
									 }
									 else {
										 [self didFinishLoadData:loadouts withCacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:[self defaultCacheExpireTime]]];
									 }
								 }
							 }];
}

- (NSString*) recordID {
	return [NSString stringWithFormat:@"%@.%@.%lu", NSStringFromClass(self.class), self.type.typeName, (unsigned long)[[self.tags componentsJoinedByString:@","] hash]];
}

- (NSTimeInterval) defaultCacheExpireTime {
	return 60 * 60 * 24;
}


@end
