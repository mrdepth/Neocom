//
//  NCDatabaseCertificatesViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 22.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseCertificatesViewController.h"
#import "NCTableViewCell.h"
#import <objc/runtime.h>
#import "NSString+Neocom.h"
#import "NCDatabaseCertificateInfoViewController.h"

@interface NCDatabaseCertificatesViewController ()
@property (nonatomic, strong) NSArray* rows;
@property (nonatomic, strong) NSArray* searchResults;

- (void) reload;
@end

@implementation NCDatabaseCertificatesViewController

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
	if (self.group)
		self.title = self.group.groupName;
	self.refreshControl = nil;
	
	[self reload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCDatabaseCertificatesViewController"]) {
		id row = [sender object];
		
		NCDatabaseCertificatesViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.group = row;
	}
	else {
		NCDatabaseCertificateInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;

		id row = [sender object];
		controller.certificate = row;
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return tableView == self.tableView ? self.rows.count : self.searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	id row = tableView == self.tableView ? self.rows[indexPath.row] : self.searchResults[indexPath.row];
	NCTableViewCell *cell;
	if ([row isKindOfClass:[EVEDBCertCertificate class]]) {
		static NSString *CellIdentifier = @"CertificateCell";
		cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (!cell)
			cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	}
	else {
		static NSString *CellIdentifier = @"GroupCell";
		cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (!cell)
			cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		
		cell.titleLabel.text = [row groupName];
	}
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	return cell;
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 37;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	
	id row = tableView == self.tableView ? self.rows[indexPath.row] : self.searchResults[indexPath.row];
	UITableViewCell *cell;
	if ([row isKindOfClass:[EVEDBCertCertificate class]])
		cell = [self tableView:tableView offscreenCellWithIdentifier:@"CertificateCell"];
	else
		cell = [self tableView:tableView offscreenCellWithIdentifier:@"GroupCell"];
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];

	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (void) didChangeAccount:(NCAccount *)account {
	[super didChangeAccount:account];
	if ([self isViewLoaded])
		[self reload];
}

- (void) didChangeStorage {
	[self reload];
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	id row = tableView == self.tableView ? self.rows[indexPath.row] : self.searchResults[indexPath.row];
	NCTableViewCell *cell = (NCTableViewCell*) tableViewCell;
	if ([row isKindOfClass:[EVEDBCertCertificate class]]) {
		cell.titleLabel.text = [row name];
		int32_t level = [objc_getAssociatedObject(row, @"masteryLevel") intValue];
		cell.iconView.image = [UIImage imageNamed:[EVEDBCertCertificate iconImageNameWithMasteryLevel:level]];
		NSTimeInterval trainingTime = [objc_getAssociatedObject(row, @"trainingTime") doubleValue];
		if (trainingTime > 0)
			cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ to level %d", nil), [NSString stringWithTimeLeft:trainingTime], level + 2];
		else
			cell.subtitleLabel.text = nil;
		cell.object = row;
	}
	else {
		cell.titleLabel.text = [row groupName];
		
		NSString* iconImageName = [row icon].iconImageName;
		if (iconImageName)
			cell.iconView.image = [UIImage imageNamed:iconImageName];
		else
			cell.iconView.image = [UIImage imageNamed:@"Icons/icon38_174.png"];
		
		cell.object = row;
	}
}

#pragma mark - Private

- (void) reload {
	NCAccount* account = [NCAccount currentAccount];

	NSMutableArray* rows = [NSMutableArray new];
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 if (self.group) {
												 [[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * FROM certCerts WHERE groupID = %d ORDER BY name", self.group.groupID]
																					resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																						if ([task isCancelled])
																							*needsMore = NO;
																						EVEDBCertCertificate* certificate = [[EVEDBCertCertificate alloc] initWithStatement:stmt];
																						
																						NSInteger level = -1;
																						
																						NCTrainingQueue* trainingQueue = nil;
																						for (NSArray* skills in certificate.skills) {
																							trainingQueue = [[NCTrainingQueue alloc] initWithAccount:account];
																							for (EVEDBCertSkill* skill in skills) {
																								[trainingQueue addSkill:skill.skill withLevel:skill.skillLevel];
																							}
																							if (trainingQueue.trainingTime > 0.0)
																								break;
																							level++;
																						}
																						objc_setAssociatedObject(certificate, @"masteryLevel", @(level), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
																						objc_setAssociatedObject(certificate, @"trainingTime", @(trainingQueue.trainingTime), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
																						[rows addObject:certificate];
																					}];
											 }
											 else {
												 [[EVEDBDatabase sharedDatabase] execSQLRequest:@"SELECT A.* FROM invGroups as A, certCerts as B where A.groupID = B.groupID GROUP BY B.groupID ORDER BY A.groupName"
																					resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																						if ([task isCancelled])
																							*needsMore = NO;
																						EVEDBInvGroup* group = [[EVEDBInvGroup alloc] initWithStatement:stmt];
																						[rows addObject:group];
																					}];
											 }
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.rows = rows;
									 [self update];
								 }
							 }];
}

@end
