//
//  NCDatabaseCertificateInfoViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 23.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseCertificateInfoViewController.h"
#import "NSString+Neocom.h"
#import "NCDatabaseTypeInfoViewController.h"
#import <objc/runtime.h>
#import "NCTableViewCell.h"
#import "UIColor+Neocom.h"

@interface NCDatabaseCertificateInfoViewControllerRow : NSObject
@property (nonatomic, copy) NSString* title;
@property (nonatomic, copy) NSString* detail;
@property (nonatomic, strong) NSManagedObjectID* iconID;
@property (nonatomic, strong) NSManagedObjectID* accessoryIconID;
@property (nonatomic, strong) NCDBEveIcon* icon;
@property (nonatomic, strong) NCDBEveIcon* accessoryIcon;
@property (nonatomic, strong) id object;
@property (nonatomic, strong) NSString* cellIdentifier;
@end

@implementation NCDatabaseCertificateInfoViewControllerRow
@end

@interface NCDatabaseCertificateInfoViewController ()
@property (strong, nonatomic) NSArray* masteriesSections;
@property (strong, nonatomic) NSArray* requiredForSections;
@property (nonatomic, assign) BOOL needsLayout;
@property (nonatomic, strong) NCDBEveIcon* defaultIcon;
@property (nonatomic, strong) NCDBCertCertificate* certificate;

@end

@implementation NCDatabaseCertificateInfoViewController

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
	self.tableView.tableHeaderView.backgroundColor = [UIColor appearanceTableViewBackgroundColor];
	if (self.navigationController.viewControllers[0] != self)
		self.navigationItem.leftBarButtonItem = nil;
	self.refreshControl = nil;
	self.certificate = (NCDBCertCertificate*) [self.databaseManagedObjectContext existingObjectWithID:self.certificateID error:nil];
	self.defaultIcon = [self.databaseManagedObjectContext eveIconWithIconFile:@"105_32"];
	[self reload];
}

- (void) viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		
		if (self.needsLayout) {
			UIView* header = self.tableView.tableHeaderView;
			CGRect frame = header.frame;
			if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1)
				frame.size.height = [header systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
			else
				frame.size.height = [header systemLayoutSizeFittingSize:UILayoutFittingCompressedSize withHorizontalFittingPriority:999 verticalFittingPriority:1].height;

			if (!CGRectEqualToRect(header.frame, frame)) {
				header.frame = frame;
				self.tableView.tableHeaderView = header;
			}
			self.needsLayout = NO;
		}
	});

}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	self.needsLayout = YES;
	[self.view setNeedsLayout];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	NSIndexPath* indexPath = [self.tableView indexPathForCell:sender];
	NCDatabaseCertificateInfoViewControllerRow* row = self.mode == NCDatabaseCertificateInfoViewControllerModeMasteries ?
		self.masteriesSections[indexPath.section][@"rows"][indexPath.row] :
		self.requiredForSections[indexPath.section][@"rows"][indexPath.row];
	
	if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;

		controller.typeID = row.object;
	}
}

- (IBAction)onChangeMode:(id)sender {
	self.mode = [sender selectedSegmentIndex] == 0 ? NCDatabaseCertificateInfoViewControllerModeMasteries : NCDatabaseCertificateInfoViewControllerModeRequiredFor;
	[self.tableView reloadData];
	[self.tableView scrollsToTop];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.mode == NCDatabaseCertificateInfoViewControllerModeMasteries ? self.masteriesSections.count : self.requiredForSections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.mode == NCDatabaseCertificateInfoViewControllerModeMasteries ? [self.masteriesSections[section][@"rows"] count] : [self.requiredForSections[section][@"rows"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return self.mode == NCDatabaseCertificateInfoViewControllerModeMasteries ? self.masteriesSections[section][@"title"] : [NSString stringWithFormat:@"%@ (%ld)", self.requiredForSections[section][@"title"], (long) [self.requiredForSections[section][@"rows"] count]];
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NCDatabaseCertificateInfoViewControllerRow* row = self.mode == NCDatabaseCertificateInfoViewControllerModeMasteries ?
		self.masteriesSections[indexPath.section][@"rows"][indexPath.row] :
		self.requiredForSections[indexPath.section][@"rows"][indexPath.row];
	
	if (row.object && [row.object isKindOfClass:[NCTrainingQueue class]]) {
		NCTrainingQueue* trainingQueue = row.object;
		UIAlertController* controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Add to skill plan?", nil)
																			message:[NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:trainingQueue.trainingTime]]
																	 preferredStyle:UIAlertControllerStyleAlert];
		[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Add", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			NCAccount* account = [NCAccount currentAccount];
			[account.managedObjectContext performBlock:^{
				[account.activeSkillPlan mergeWithTrainingQueue:trainingQueue completionBlock:nil];
			}];
		}]];
		[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
		}]];
		[self presentViewController:controller animated:YES completion:nil];
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
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

- (BOOL) initiallySectionIsCollapsed:(NSInteger)section {
	return self.mode == NCDatabaseCertificateInfoViewControllerModeMasteries ? [self.masteriesSections[section][@"collapsed"] boolValue]: YES;
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCDatabaseCertificateInfoViewControllerRow* row = self.mode == NCDatabaseCertificateInfoViewControllerModeMasteries ?
	self.masteriesSections[indexPath.section][@"rows"][indexPath.row] :
	self.requiredForSections[indexPath.section][@"rows"][indexPath.row];
	
	NSString *cellIdentifier = row.cellIdentifier;
	if (!cellIdentifier)
		cellIdentifier = @"Cell";
	return cellIdentifier;
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCDatabaseCertificateInfoViewControllerRow* row = self.mode == NCDatabaseCertificateInfoViewControllerModeMasteries ?
	self.masteriesSections[indexPath.section][@"rows"][indexPath.row] :
	self.requiredForSections[indexPath.section][@"rows"][indexPath.row];
	
	NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
	cell.titleLabel.text = row.title;
	cell.subtitleLabel.text = row.detail;
	
	if (row.iconID && !row.icon)
		row.icon = (NCDBEveIcon*) [self.databaseManagedObjectContext existingObjectWithID:row.iconID error:nil];
	if (row.accessoryIconID && !row.accessoryIcon)
		row.accessoryIcon = (NCDBEveIcon*) [self.databaseManagedObjectContext existingObjectWithID:row.accessoryIconID error:nil];

	cell.iconView.image = row.icon ? row.icon.image.image : self.defaultIcon.image.image;
	
	cell.accessoryView = row.accessoryIcon ? [[UIImageView alloc] initWithImage:row.accessoryIcon.image.image] : nil;
}

#pragma mark - Private

- (void) reload {
	NCAccount *account = [NCAccount currentAccount];
	
	void (^load)(EVECharacterSheet*, BOOL) = ^(EVECharacterSheet* characterSheet, BOOL canTrain) {
		NSManagedObjectContext* managedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContext];
		[managedObjectContext performBlock:^{
			NSMutableArray* masteriesSections = [NSMutableArray new];
			NSArray* requiredForSections = nil;
			NSManagedObjectID* certificateIconID;

			NCDBCertCertificate* certificate = (NCDBCertCertificate*) [managedObjectContext existingObjectWithID:self.certificateID error:nil];
			NSArray* masteries = [certificate.masteries sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"level.level" ascending:YES]]];
			
			NCDBEveIcon* skillIcon = [managedObjectContext eveIconWithIconFile:@"50_11"];
			NCDBEveIcon* notKnownIcon = [managedObjectContext eveIconWithIconFile:@"38_194"];
			NCDBEveIcon* lowLevelIcon = [managedObjectContext eveIconWithIconFile:@"38_193"];
			NCDBEveIcon* knownIcon = [managedObjectContext eveIconWithIconFile:@"38_195"];
			
			NCDBCertMasteryLevel* level = nil;
			NCDBEveIcon* unclaimedIcon = [managedObjectContext certificateUnclaimedIcon];
			
			for (NCDBCertMastery* mastery in masteries) {
				NSMutableArray* rows = [NSMutableArray new];
				NCTrainingQueue* trainingQueue = [[NCTrainingQueue alloc] initWithCharacterSheet:characterSheet databaseManagedObjectContext:managedObjectContext];
				
				for (NCDBCertSkill* skill in [mastery.skills sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]]) {
					[trainingQueue addSkill:skill.type withLevel:skill.skillLevel];
					NCTrainingQueue* skillTrainingQueue = [[NCTrainingQueue alloc] initWithCharacterSheet:characterSheet databaseManagedObjectContext:managedObjectContext];
					[skillTrainingQueue addSkill:skill.type withLevel:skill.skillLevel];
					
					if (skill.skillLevel > 0) {
						EVECharacterSheetSkill* characerSkill = characterSheet.skillsMap[@(skill.type.typeID)];
						
						NCDatabaseCertificateInfoViewControllerRow* row = [NCDatabaseCertificateInfoViewControllerRow new];
						row.title = [NSString stringWithFormat:@"%@ %d", skill.type.typeName, skill.skillLevel];
						row.object = [skill.type objectID];
						row.cellIdentifier = @"TypeCell";
						row.iconID = [skillIcon objectID];
						
						if (!characerSkill)
							row.accessoryIconID = [notKnownIcon objectID];
						else if (characerSkill.level >= skill.skillLevel)
							row.accessoryIconID = [lowLevelIcon objectID];
						else
							row.accessoryIconID = [knownIcon objectID];
						
						if (skillTrainingQueue.trainingTime > 0.0)
							row.detail = [NSString stringWithTimeLeft:skillTrainingQueue.trainingTime];
						
						[rows addObject:row];
					}
				}
				
				NSString* title;
				BOOL collapsed;
				if (canTrain && trainingQueue.trainingTime > 0.0) {
					NCDatabaseCertificateInfoViewControllerRow* row = [NCDatabaseCertificateInfoViewControllerRow new];
					row.title = NSLocalizedString(@"Add required skills to training plan", nil);
					row.detail = [NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:trainingQueue.trainingTime]];
					row.iconID = [skillIcon objectID];
					row.object = trainingQueue;
					[rows insertObject:row atIndex:0];
					
					title = [NSString stringWithFormat:NSLocalizedString(@"Mastery %d (%@)", nil), mastery.level.level + 1, [NSString stringWithTimeLeft:trainingQueue.trainingTime]];
					collapsed = NO;
				}
				else {
					title = [NSString stringWithFormat:NSLocalizedString(@"Mastery %d", nil), mastery.level.level + 1];
					if (canTrain) {
						collapsed = YES;
					}
					else
						collapsed = NO;
				}
				[masteriesSections addObject:@{@"title": title, @"rows": rows, @"collapsed": @(collapsed)}];
				
				if (trainingQueue.trainingTime > 0.0) {
					if (!level)
						certificateIconID = [unclaimedIcon objectID];
				}
				else
					level = mastery.level;
				
			}
			
			if (level)
				certificateIconID = [level.icon objectID];
			
			NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
			request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"group.groupName" ascending:YES],
										[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];
			request.predicate = [NSPredicate predicateWithFormat:@"ANY certificates == %@", certificate];
			NSFetchedResultsController* controller = [[NSFetchedResultsController alloc] initWithFetchRequest:request
																						 managedObjectContext:managedObjectContext
																						   sectionNameKeyPath:@"group.groupName"
																									cacheName:nil];
			[controller performFetch:nil];
			NSMutableArray* sections = [NSMutableArray new];
			for (id<NSFetchedResultsSectionInfo> sectionInfo in controller.sections) {
				NSMutableArray* rows = [NSMutableArray new];
				for (NCDBInvType* type in sectionInfo.objects) {
					NCTrainingQueue* trainingQueue = [[NCTrainingQueue alloc] initWithCharacterSheet:characterSheet databaseManagedObjectContext:managedObjectContext];
					[trainingQueue addRequiredSkillsForType:type];
					NCDatabaseCertificateInfoViewControllerRow* row = [NCDatabaseCertificateInfoViewControllerRow new];
					row.title = type.typeName;
					row.cellIdentifier = @"TypeCell";
					row.object = [type objectID];
					row.iconID = [type.icon objectID];
					if (trainingQueue.trainingTime > 0) {
						row.detail = [NSString stringWithTimeLeft:trainingQueue.trainingTime];
						row.accessoryIconID = [knownIcon objectID];
					}
					else
						row.accessoryIconID = [lowLevelIcon objectID];
					[rows addObject:row];
				}
				[sections addObject:@{@"title": sectionInfo.name, @"rows": rows}];
			}
			requiredForSections = sections;

			
			dispatch_async(dispatch_get_main_queue(), ^{
				self.masteriesSections = masteriesSections;
				self.requiredForSections = requiredForSections;
				if (certificateIconID) {
					NCDBEveIcon* certificateIcon = (NCDBEveIcon*) [self.databaseManagedObjectContext existingObjectWithID:certificateIconID error:nil];
					self.imageView.image = certificateIcon.image.image;
				}
				[self.tableView reloadData];
			});
		}];
	};
	
	if (account) {
		[account loadCharacterSheetWithCompletionBlock:^(EVECharacterSheet *characterSheet, NSError *error) {
			[account.managedObjectContext performBlock:^{
				BOOL canTrain = account.accountType == NCAccountTypeCharacter && account.activeSkillPlan;
				load(characterSheet, canTrain);
			}];
		}];
	}
	else
		load(nil, NO);

	
	self.titleLabel.text = self.certificate.certificateName;
	self.imageView.image = [[[self.databaseManagedObjectContext eveIconWithIconFile:@"79_01"] image] image];
	self.descriptionLabel.attributedText = self.certificate.certificateDescription.text;
	self.needsLayout = YES;
	[self.view setNeedsLayout];
}

@end
