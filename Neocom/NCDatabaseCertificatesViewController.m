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

@interface NCDatabaseCertificatesViewControllerRow : NSObject
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSString* subtitle;
@property (nonatomic, strong) NSManagedObjectID* iconID;
@property (nonatomic, strong) NCDBEveIcon* icon;
@property (nonatomic, strong) id object;
@end

@implementation NCDatabaseCertificatesViewControllerRow

@end

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
	if (self.groupID) {
		NCDBInvGroup* group = (NCDBInvGroup*) [self.databaseManagedObjectContext objectWithID:self.groupID];
		self.title = group.groupName;
	}
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
		destinationViewController.groupID = row;
	}
	else {
		NCDatabaseCertificateInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;

		id row = [sender object];
		controller.certificateID = row;
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

- (void) didChangeAccount:(NSNotification *)notification {
	[super didChangeAccount:notification];
	if ([self isViewLoaded])
		[self reload];
}

- (void) didChangeStorage:(NSNotification *)notification {
	[super didChangeStorage:notification];
	[self reload];
}

- (NSString*)tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCDatabaseCertificatesViewControllerRow* row = self.rows[indexPath.row];
	if (NSClassFromString([[row.object entity] managedObjectClassName]) == [NCDBCertCertificate class])
		return @"CertificateCell";
	else
		return @"GroupCell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCDatabaseCertificatesViewControllerRow* row = self.rows[indexPath.row];
	NCDefaultTableViewCell *cell = (NCDefaultTableViewCell*) tableViewCell;
	
	if (!row.icon && row.iconID)
		row.icon = (NCDBEveIcon*) [self.databaseManagedObjectContext objectWithID:row.iconID];
	
	cell.titleLabel.text = row.title;
	cell.subtitleLabel.text = row.subtitle;
	cell.iconView.image = row.icon.image.image;
	cell.object = row.object;
}

#pragma mark - Private

- (void) reload {
	NCAccount *account = [NCAccount currentAccount];
	
	void (^load)(EVECharacterSheet*) = ^(EVECharacterSheet* characterSheet) {
		NSManagedObjectContext* managedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContext];
		[managedObjectContext performBlock:^{
			NSMutableArray* rows = [NSMutableArray new];
			
			if (self.groupID) {
				NCDBInvGroup* group = (NCDBInvGroup*) [managedObjectContext objectWithID:self.groupID];
				NSArray* certificates = [group.certificates sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"certificateName" ascending:YES]]];
				NCDBEveIcon* unclaimedIcon = [managedObjectContext certificateUnclaimedIcon];
				for (NCDBCertCertificate* certificate in certificates) {
					
					NCTrainingQueue* trainingQueue = nil;
					NCDBCertMasteryLevel* level;
					for (NCDBCertMastery* mastery in [certificate.masteries sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"level.level" ascending:YES]]]) {
						trainingQueue = [[NCTrainingQueue alloc] initWithCharacterSheet:characterSheet databaseManagedObjectContext:managedObjectContext];
						[trainingQueue addMastery:mastery];
						if (trainingQueue.trainingTime > 0.0)
							break;
						level = mastery.level;
					}
					NSTimeInterval trainingTime = trainingQueue.trainingTime;
					
					NCDatabaseCertificatesViewControllerRow* row = [NCDatabaseCertificatesViewControllerRow new];
					row.title = certificate.certificateName;
					if (trainingTime > 0)
						row.subtitle = [NSString stringWithFormat:NSLocalizedString(@"%@ to level %d", nil), [NSString stringWithTimeLeft:trainingTime], level ? level.level + 2 : 1];
					row.iconID = level ? [level.icon objectID] : [unclaimedIcon objectID];
					row.object = [certificate objectID];
					[rows addObject:row];
				}
			}
			else {
				NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvGroup"];
				request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"groupName" ascending:YES]];
				request.predicate = [NSPredicate predicateWithFormat:@"certificates.@count > 0"];
				NSArray* groups = [managedObjectContext executeFetchRequest:request error:nil];
				NCDBEveIcon* defaultGroupIcon = [managedObjectContext defaultGroupIcon];

				for (NCDBInvGroup* group in groups) {
					NCDatabaseCertificatesViewControllerRow* row = [NCDatabaseCertificatesViewControllerRow new];
					row.title = group.groupName;
					row.iconID = group.icon ? [group.icon objectID] : [defaultGroupIcon objectID];
					row.object = [group objectID];
					[rows addObject:row];
				}
			}
			
			dispatch_async(dispatch_get_main_queue(), ^{
				self.rows = rows;
				[self.tableView reloadData];
			});
		}];
	};
	
	if (account) {
		[account loadCharacterSheetWithCompletionBlock:^(EVECharacterSheet *characterSheet, NSError *error) {
			load(characterSheet);
		}];
	}
	else
		load(nil);
}

@end
