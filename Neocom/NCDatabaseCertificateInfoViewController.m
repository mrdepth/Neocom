//
//  NCDatabaseCertificateInfoViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 23.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseCertificateInfoViewController.h"
#import "NSString+Neocom.h"
#import "NSString+HTML.h"
#import "NCDatabaseTypeInfoViewController.h"
#import <objc/runtime.h>
#import "UIAlertView+Block.h"
#import "NCTableViewCell.h"
#import "UIColor+Neocom.h"

@interface NCDatabaseCertificateInfoViewControllerRow : NSObject
@property (nonatomic, copy) NSString* title;
@property (nonatomic, copy) NSString* detail;
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
	self.defaultIcon = [NCDBEveIcon eveIconWithIconFile:@"105_32"];
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

		controller.type = row.object;
	}
}

- (IBAction)onChangeMode:(id)sender {
	self.mode = [sender selectedSegmentIndex] == 0 ? NCDatabaseCertificateInfoViewControllerModeMasteries : NCDatabaseCertificateInfoViewControllerModeRequiredFor;
	[self update];
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

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCDatabaseCertificateInfoViewControllerRow* row = self.mode == NCDatabaseCertificateInfoViewControllerModeMasteries ?
		self.masteriesSections[indexPath.section][@"rows"][indexPath.row] :
		self.requiredForSections[indexPath.section][@"rows"][indexPath.row];
	
	NSString *cellIdentifier = row.cellIdentifier;
	if (!cellIdentifier)
		cellIdentifier = @"Cell";
	
	NCTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	return cell;
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 42;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1)
		return UITableViewAutomaticDimension;

	NCDatabaseCertificateInfoViewControllerRow* row = self.mode == NCDatabaseCertificateInfoViewControllerModeMasteries ?
	self.masteriesSections[indexPath.section][@"rows"][indexPath.row] :
	self.requiredForSections[indexPath.section][@"rows"][indexPath.row];
	
	NSString *cellIdentifier = row.cellIdentifier;
	if (!cellIdentifier)
		cellIdentifier = @"Cell";
	
	UITableViewCell* cell = [self tableView:tableView offscreenCellWithIdentifier:cellIdentifier];
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell layoutIfNeeded];
	return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NCDatabaseCertificateInfoViewControllerRow* row = self.mode == NCDatabaseCertificateInfoViewControllerModeMasteries ?
		self.masteriesSections[indexPath.section][@"rows"][indexPath.row] :
		self.requiredForSections[indexPath.section][@"rows"][indexPath.row];
	
	if (row.object && [row.object isKindOfClass:[NCTrainingQueue class]]) {
		NCTrainingQueue* trainingQueue = row.object;
		[[UIAlertView alertViewWithTitle:NSLocalizedString(@"Add to skill plan?", nil)
								 message:[NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:trainingQueue.trainingTime]]
					   cancelButtonTitle:NSLocalizedString(@"No", nil)
					   otherButtonTitles:@[NSLocalizedString(@"Yes", nil)]
						 completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
							 if (selectedButtonIndex != alertView.cancelButtonIndex) {
								 NCSkillPlan* skillPlan = [[NCAccount currentAccount] activeSkillPlan];
								 [skillPlan mergeWithTrainingQueue:trainingQueue];
							 }
						 }
							 cancelBlock:nil] show];
	}
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

- (BOOL) initiallySectionIsCollapsed:(NSInteger)section {
	return self.mode == NCDatabaseCertificateInfoViewControllerModeMasteries ? [self.masteriesSections[section][@"collapsed"] boolValue]: YES;
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCDatabaseCertificateInfoViewControllerRow* row = self.mode == NCDatabaseCertificateInfoViewControllerModeMasteries ?
	self.masteriesSections[indexPath.section][@"rows"][indexPath.row] :
	self.requiredForSections[indexPath.section][@"rows"][indexPath.row];
	
	NCTableViewCell* cell = (NCTableViewCell*) tableViewCell;
	cell.titleLabel.text = row.title;
	cell.subtitleLabel.text = row.detail;
	cell.iconView.image = row.icon ? row.icon.image.image : self.defaultIcon.image.image;
	
	cell.accessoryView = row.accessoryIcon ? [[UIImageView alloc] initWithImage:row.accessoryIcon.image.image] : nil;
}

#pragma mark - Private

- (void) reload {
	self.titleLabel.text = self.certificate.certificateName;
	NCDBEveIcon* icon = objc_getAssociatedObject(self.certificate, @"icon");
	self.imageView.image = icon ? icon.image.image : [[[NCDBEveIcon eveIconWithIconFile:@"79_01"] image] image];
	self.descriptionLabel.text = self.certificate.certificateDescription.text;

	self.needsLayout = YES;
	[self.view setNeedsLayout];

	
	NCAccount* account = [NCAccount currentAccount];
	NSMutableArray* masteriesSections = [NSMutableArray new];
	__block NSArray* requiredForSections = nil;
	BOOL canTrain = account && account.accountType == NCAccountTypeCharacter && account.activeSkillPlan;
	__block NCDBEveIcon* certificateIcon;
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NCDatabase* database = [NCDatabase sharedDatabase];
											 [database.backgroundManagedObjectContext performBlockAndWait:^{
												 NCDBCertCertificate* certificate = (NCDBCertCertificate*) [database.backgroundManagedObjectContext objectWithID:self.certificate.objectID];
												 NSArray* masteries = [certificate.masteries sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"level.level" ascending:YES]]];
												 
												 NCDBEveIcon* skillIcon = [NCDBEveIcon eveIconWithIconFile:@"50_11"];
												 NCDBEveIcon* notKnownIcon = [NCDBEveIcon eveIconWithIconFile:@"38_194"];
												 NCDBEveIcon* lowLevelIcon = [NCDBEveIcon eveIconWithIconFile:@"38_193"];
												 NCDBEveIcon* knownIcon = [NCDBEveIcon eveIconWithIconFile:@"38_195"];
												 
												 NCDBCertMasteryLevel* level = nil;
												 NCDBEveIcon* unclaimedIcon = [NCDBEveIcon certificateUnclaimedIcon];
												 
												 for (NCDBCertMastery* mastery in masteries) {
													 NSMutableArray* rows = [NSMutableArray new];
													 NCTrainingQueue* trainingQueue = [[NCTrainingQueue alloc] initWithAccount:account];
													 
													 for (NCDBCertSkill* skill in [mastery.skills sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]]) {
														 [trainingQueue addSkill:skill.type withLevel:skill.skillLevel];
														 NCTrainingQueue* skillTrainingQueue = [[NCTrainingQueue alloc] initWithAccount:account];
														 [skillTrainingQueue addSkill:skill.type withLevel:skill.skillLevel];
														 
														 if (skill.skillLevel > 0) {
															 EVECharacterSheetSkill* characerSkill = account.characterSheet.skillsMap[@(skill.type.typeID)];
															 
															 NCDatabaseCertificateInfoViewControllerRow* row = [NCDatabaseCertificateInfoViewControllerRow new];
															 row.title = [NSString stringWithFormat:@"%@ %d", skill.type.typeName, skill.skillLevel];
															 row.object = skill.type;
															 row.cellIdentifier = @"TypeCell";
															 row.icon = skillIcon;
															 
															 if (!characerSkill)
																 row.accessoryIcon = notKnownIcon;
															 else if (characerSkill.level >= skill.skillLevel)
																 row.accessoryIcon = lowLevelIcon;
															 else
																 row.accessoryIcon = knownIcon;
															 
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
														 row.icon = skillIcon;
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
															 certificateIcon = unclaimedIcon;
													 }
													 else
														 level = mastery.level;

												 }
												 
												 if (level)
													 certificateIcon = level.icon;

												 if ([task isCancelled])
													 return;
												 
												 task.progress = 0.5;
												 NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
												 request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"group.groupName" ascending:YES],
																			 [NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];
												 request.predicate = [NSPredicate predicateWithFormat:@"ANY certificates == %@", certificate];
												 NSFetchedResultsController* controller = [[NSFetchedResultsController alloc] initWithFetchRequest:request
																															  managedObjectContext:database.backgroundManagedObjectContext
																																sectionNameKeyPath:@"group.groupName"
																																		 cacheName:nil];
												 [controller performFetch:nil];
												 NSMutableArray* sections = [NSMutableArray new];
												 for (id<NSFetchedResultsSectionInfo> sectionInfo in controller.sections) {
													 NSMutableArray* rows = [NSMutableArray new];
													 for (NCDBInvType* type in sectionInfo.objects) {
														 NCTrainingQueue* trainingQueue = [[NCTrainingQueue alloc] initWithAccount:account];
														 [trainingQueue addRequiredSkillsForType:type];
														 NCDatabaseCertificateInfoViewControllerRow* row = [NCDatabaseCertificateInfoViewControllerRow new];
														 row.title = type.typeName;
														 row.cellIdentifier = @"TypeCell";
														 row.object = type;
														 row.icon = type.icon;
														 if (trainingQueue.trainingTime > 0) {
															 row.detail = [NSString stringWithTimeLeft:trainingQueue.trainingTime];
															 row.accessoryIcon = knownIcon;
														 }
														 else
															 row.accessoryIcon = lowLevelIcon;
														 [rows addObject:row];
													 }
													 [sections addObject:@{@"title": sectionInfo.name, @"rows": rows}];
												 }
												 requiredForSections = sections;
												 
											  }];
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.masteriesSections = masteriesSections;
									 self.requiredForSections = requiredForSections;
									 [self update];
									 self.imageView.image = certificateIcon.image.image;

								 }
							 }];
}

@end
