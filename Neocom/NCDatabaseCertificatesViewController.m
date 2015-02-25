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
    return self.rows.count;
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

- (NSString*)tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	id row = self.rows[indexPath.row];
	NCTableViewCell *cell;
	if ([row isKindOfClass:[NCDBCertCertificate class]])
		return @"CertificateCell";
	else
		return @"GroupCell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	id row = self.rows[indexPath.row];
	NCTableViewCell *cell = (NCTableViewCell*) tableViewCell;
	if ([row isKindOfClass:[NCDBCertCertificate class]]) {
		NCDBCertCertificate* certificate = row;
		cell.titleLabel.text = certificate.certificateName;
		NCDBEveIcon* icon = objc_getAssociatedObject(row, @"icon");
		cell.iconView.image = icon.image.image;
		NSTimeInterval trainingTime = [objc_getAssociatedObject(row, @"trainingTime") doubleValue];
		int32_t level = [objc_getAssociatedObject(row, @"level") intValue];
		if (trainingTime > 0)
			cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ to level %d", nil), [NSString stringWithTimeLeft:trainingTime], level + 2];
		else
			cell.subtitleLabel.text = nil;
		cell.object = row;
	}
	else {
		NCDBInvGroup* group = row;
		cell.titleLabel.text = group.groupName;
		cell.iconView.image = group.icon ? group.icon.image.image : [[[NCDBEveIcon defaultGroupIcon] image] image];
		cell.object = row;
	}
}

#pragma mark - Private

- (void) reload {
	NCAccount* account = [NCAccount currentAccount];

	__block NSArray* rows = nil;
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NCDatabase* database = [NCDatabase sharedDatabase];
											 [database.backgroundManagedObjectContext performBlockAndWait:^{
												 if (self.group) {
													 NCDBInvGroup* group = (NCDBInvGroup*) [database.backgroundManagedObjectContext objectWithID:self.group.objectID];
													 rows = [group.certificates sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"certificateName" ascending:YES]]];
													 NCDBEveIcon* unclaimedIcon = [NCDBEveIcon certificateUnclaimedIcon];
													 for (NCDBCertCertificate* certificate in rows) {

														 NCTrainingQueue* trainingQueue = nil;
														 NCDBCertMasteryLevel* level;
														 for (NCDBCertMastery* mastery in [certificate.masteries sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"level.level" ascending:YES]]]) {
															 trainingQueue = [[NCTrainingQueue alloc] initWithAccount:account];
															 [trainingQueue addMastery:mastery];
															 if (trainingQueue.trainingTime > 0.0)
																 break;
															 level = mastery.level;
														 }
														 if (level) {
															 objc_setAssociatedObject(certificate, @"level", @(level.level), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
															 objc_setAssociatedObject(certificate, @"icon", level.icon, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
														 }
														 else {
															 objc_setAssociatedObject(certificate, @"level", @(-1), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
															 objc_setAssociatedObject(certificate, @"icon", unclaimedIcon, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
														 }
														 
														 objc_setAssociatedObject(certificate, @"trainingTime", @(trainingQueue.trainingTime), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
													 }
												 }
												 else {
													 NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvGroup"];
													 request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"groupName" ascending:YES]];
													 request.predicate = [NSPredicate predicateWithFormat:@"certificates.@count > 0"];
													 rows = [database.backgroundManagedObjectContext executeFetchRequest:request error:nil];
												 }
											 }];

										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.rows = rows;
									 [self update];
								 }
							 }];
}

@end
