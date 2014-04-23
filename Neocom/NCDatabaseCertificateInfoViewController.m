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

@interface NCDatabaseCertificateInfoViewControllerRow : NSObject
@property (nonatomic, copy) NSString* title;
@property (nonatomic, copy) NSString* detail;
@property (nonatomic, copy) NSString* imageName;
@property (nonatomic, copy) NSString* accessoryImageName;
@property (nonatomic, strong) id object;
@property (nonatomic, strong) NSString* cellIdentifier;
@end

@implementation NCDatabaseCertificateInfoViewControllerRow
@end

@interface NCDatabaseCertificateInfoViewController ()
@property (strong, nonatomic) NSArray* masteriesSections;
@property (strong, nonatomic) NSArray* requiredForSections;
@property (nonatomic, assign) BOOL needsLayout;

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
	if (self.navigationController.viewControllers[0] != self)
		self.navigationItem.leftBarButtonItem = nil;
	self.refreshControl = nil;
	[self reload];
}

- (void) viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		
		if (self.needsLayout) {
			UIView* header = self.tableView.tableHeaderView;
			CGRect frame = header.frame;
			frame.size.height = [header systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
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
	cell.titleLabel.text = row.title;
	cell.subtitleLabel.text = row.detail;
	cell.iconView.image = [UIImage imageNamed:row.imageName ? row.imageName : @"Icons/icon105_32.png"];
	
	cell.accessoryView = row.accessoryImageName ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:row.accessoryImageName]] : nil;
	
	return cell;
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 41;
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

#pragma mark - Private

- (void) reload {
	NSString* s = [[self.certificate.description stringByRemovingHTMLTags] stringByReplacingHTMLEscapes];
	NSMutableString* description = [NSMutableString stringWithString:s ? s : @""];
	[description replaceOccurrencesOfString:@"\\r" withString:@"" options:0 range:NSMakeRange(0, description.length)];
	[description replaceOccurrencesOfString:@"\\n" withString:@"\n" options:0 range:NSMakeRange(0, description.length)];
	[description replaceOccurrencesOfString:@"\\t" withString:@"\t" options:0 range:NSMakeRange(0, description.length)];
	
	
	self.titleLabel.text = self.certificate.name;
	NSNumber* masteryLevel = objc_getAssociatedObject(self.certificate, @"masteryLevel");
	self.imageView.image = [UIImage imageNamed:masteryLevel ? [EVEDBCertCertificate iconImageNameWithMasteryLevel:[masteryLevel intValue]] : @"Icons/icon79_01.png"];
	self.descriptionLabel.text = description;

	self.needsLayout = YES;
	[self.view setNeedsLayout];

	
	__block int32_t availableMasteryLevel = -1;
	NCAccount* account = [NCAccount currentAccount];
	NSMutableArray* masteriesSections = [NSMutableArray new];
	__block NSArray* requiredForSections = nil;
	BOOL canTrain = account && account.accountType == NCAccountTypeCharacter && account.activeSkillPlan;
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 int32_t masteryLevel = 0;
											 for (NSArray* skills in self.certificate.skills) {
												 NSMutableArray* rows = [NSMutableArray new];
												 NCTrainingQueue* trainingQueue = [[NCTrainingQueue alloc] initWithAccount:account];
												 for (EVEDBCertSkill* skill in skills) {
													 [trainingQueue addSkill:skill.skill withLevel:skill.skillLevel];
													 NCTrainingQueue* skillTrainingQueue = [[NCTrainingQueue alloc] initWithAccount:account];
													 [skillTrainingQueue addSkill:skill.skill withLevel:skill.skillLevel];
													 
													 EVECharacterSheetSkill* characerSkill = account.characterSheet.skillsMap[@(skill.skillID)];
													 
													 NCDatabaseCertificateInfoViewControllerRow* row = [NCDatabaseCertificateInfoViewControllerRow new];
													 row.title = [NSString stringWithFormat:@"%@ %d", skill.skill.typeName, skill.skillLevel];
													 row.object = skill.skill;
													 row.cellIdentifier = @"TypeCell";
													 
													 if (!characerSkill) {
														 row.imageName = @"Icons/icon50_11.png";
														 row.accessoryImageName = @"Icons/icon38_194.png";
													 }
													 else if (characerSkill.level >= skill.skillLevel) {
														 row.imageName = @"Icons/icon50_11.png";
														 row.accessoryImageName = @"Icons/icon38_193.png";
													 }
													 else {
														 row.imageName = @"Icons/icon50_11.png";
														 row.accessoryImageName = @"Icons/icon38_195.png";
													 }
													 
													 if (skillTrainingQueue.trainingTime > 0.0)
														 row.detail = [NSString stringWithTimeLeft:skillTrainingQueue.trainingTime];
													 
													 [rows addObject:row];
												 }
												 NSString* title;
												 BOOL collapsed;
												 if (canTrain && trainingQueue.trainingTime > 0.0) {
													 NCDatabaseCertificateInfoViewControllerRow* row = [NCDatabaseCertificateInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Add required skills to training plan", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:trainingQueue.trainingTime]];
													 row.imageName = @"Icons/icon50_13.png";
													 row.object = trainingQueue;
													 [rows insertObject:row atIndex:0];

													 title = [NSString stringWithFormat:NSLocalizedString(@"Mastery %d (%@)", nil), masteryLevel + 1, [NSString stringWithTimeLeft:trainingQueue.trainingTime]];
													 collapsed = NO;
												 }
												 else {
													 title = [NSString stringWithFormat:NSLocalizedString(@"Mastery %d", nil), masteryLevel + 1];
													 if (canTrain) {
														 availableMasteryLevel++;
														 collapsed = YES;
													 }
													 else
														 collapsed = NO;
												 }
												 [masteriesSections addObject:@{@"title": title, @"rows": rows, @"collapsed": @(collapsed)}];
												 masteryLevel++;
											 }
											 
											 if ([task isCancelled])
												 return;
											 task.progress = 0.5;

											 NSMutableDictionary* dic = [NSMutableDictionary new];
											 [[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT A.* FROM invTypes as A, certMasteries as B where A.typeID=B.typeID AND B.certID=%d GROUP BY B.typeID ORDER BY A.typeName;", self.certificate.certificateID]
																				resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																					if ([task isCancelled])
																						*needsMore = NO;
																					EVEDBInvType* type = [[EVEDBInvType alloc] initWithStatement:stmt];
																					NSDictionary* section = dic[@(type.groupID)];
																					if (!section) {
																						dic[@(type.groupID)] = section = @{@"title": type.group.groupName, @"rows": [NSMutableArray new]};
																					}
																					NCTrainingQueue* trainingQueue = [[NCTrainingQueue alloc] initWithAccount:account];
																					[trainingQueue addRequiredSkillsForType:type];
																					
																					NCDatabaseCertificateInfoViewControllerRow* row = [NCDatabaseCertificateInfoViewControllerRow new];
																					row.title = type.typeName;
																					row.cellIdentifier = @"TypeCell";
																					row.object = type;
																					row.imageName = type.typeSmallImageName;
																					if (trainingQueue.trainingTime > 0) {
																						row.detail = [NSString stringWithTimeLeft:trainingQueue.trainingTime];
																						row.accessoryImageName = @"Icons/icon38_195.png";
																					}
																					else
																						row.accessoryImageName = @"Icons/icon38_193.png";
																					[section[@"rows"] addObject:row];
																				}];
											 if ([task isCancelled])
												 return;
											 task.progress = 0.9;
											 requiredForSections = [[dic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.masteriesSections = masteriesSections;
									 self.requiredForSections = requiredForSections;
									 [self update];
									 self.imageView.image = [UIImage imageNamed:[EVEDBCertCertificate iconImageNameWithMasteryLevel:availableMasteryLevel]];

								 }
							 }];
}

@end
