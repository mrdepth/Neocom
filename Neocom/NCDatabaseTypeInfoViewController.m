//
//  NCDatabaseTypeInfoViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 15.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseTypeInfoViewController.h"
#import "EVEDBAPI.h"
#import "NCStorage.h"
#import "NSNumberFormatter+Neocom.h"
#import "NSString+Neocom.h"
#import "NCDatabaseTypeContainerViewController.h"
#import "NCDatabaseTypeVariationsViewController.h"
#import "NCTrainingQueue.h"
#import "NCSkillHierarchy.h"
#import "NCDatabaseViewController.h"
#import "NSString+HTML.h"

#define EVEDBUnitIDMillisecondsID 101
#define EVEDBUnitIDInverseAbsolutePercentID 108
#define EVEDBUnitIDModifierPercentID 109
#define EVEDBUnitIDInversedModifierPercentID 111
#define EVEDBUnitIDGroupID 115
#define EVEDBUnitIDTypeID 116
#define EVEDBUnitIDSizeClass 117
#define EVEDBUnitIDAttributeID 119
#define EVEDBUnitIDAbsolutePercentID 127

#define EVEDBAttributeIDSKillLevel 280
#define EVEDBAttributeIDBaseWarpSpeed 1281
#define EVEDBAttributeIDWarpSpeedMultiplier 600

#define EVEDBCategoryIDSkill 16

#define SkillTreeRequirementIDKey @"requirementID"
#define SkillTreeSkillLevelIDKey @"skillLevelID"

@interface NCDatabaseTypeInfoViewControllerRow : NSObject
@property (nonatomic, copy) NSString* title;
@property (nonatomic, copy) NSString* detail;
@property (nonatomic, copy) NSString* imageName;
@property (nonatomic, copy) NSString* accessoryImageName;
@property (nonatomic, strong) id object;
@property (nonatomic, assign) NSInteger indentationLevel;

@end

@interface NCDatabaseTypeInfoViewController ()
@property (nonatomic, strong) NSArray* sections;
- (void) reload;
@end

@implementation NCDatabaseTypeInfoViewControllerRow

@end

@implementation NCDatabaseTypeInfoViewController

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
	self.refreshControl = nil;
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (!self.sections)
		[self reload];
}

- (void) viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	UIView* header = self.tableView.tableHeaderView;
	CGRect frame = header.frame;
	frame.size.height = CGRectGetMaxY(self.descriptionLabel.frame);
	if (!CGRectEqualToRect(header.frame, frame)) {
		header.frame = frame;
		self.tableView.tableHeaderView = header;
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	NSIndexPath* indexPath = [self.tableView indexPathForCell:sender];
	NCDatabaseTypeInfoViewControllerRow* row = self.sections[indexPath.section][@"rows"][indexPath.row];
	if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeContainerViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.type = row.object;
	}
	else if ([segue.identifier isEqualToString:@"NCDatabaseViewController"]) {
		NCDatabaseViewController* destinationViewController = segue.destinationViewController;
		if ([row.object isKindOfClass:[EVEDBInvGroup class]])
			destinationViewController.group = row.object;
		else if ([row.object isKindOfClass:[EVEDBInvCategory class]])
			destinationViewController.category = row.object;
	}
	else if ([segue.identifier isEqualToString:@"NCDatabaseTypeVariationsViewController"]) {
		NCDatabaseTypeVariationsViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.type = [(NCDatabaseTypeContainerViewController*) self.parentViewController type];
	}
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (void) didChangeAccount:(NCAccount *)account {
	[self reload];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.sections[section][@"rows"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return self.sections[section][@"title"];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"Cell";
	NCDatabaseTypeInfoViewControllerRow* row = self.sections[indexPath.section][@"rows"][indexPath.row];
	UITableViewCell* cell = (UITableViewCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
	cell.textLabel.text = row.title;
	cell.detailTextLabel.text = row.detail;
	cell.imageView.image = [UIImage imageNamed:row.imageName ? row.imageName : @"Icons/icon105_32.png"];
	cell.indentationLevel = row.indentationLevel;
	cell.indentationWidth = 16;
	
	cell.accessoryView = row.accessoryImageName ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:row.accessoryImageName]] : nil;
	if (!cell.accessoryView)
		cell.accessoryType = [row.object isKindOfClass:[EVEDBObject class]] || [row.object isKindOfClass:[NSString class]] ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
	
	//cell.indentationLevel = cellData.indentationLevel;
	
	return cell;
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NCDatabaseTypeInfoViewControllerRow* row = self.sections[indexPath.section][@"rows"][indexPath.row];
	if (row.object) {
		if ([row.object isKindOfClass:[EVEDBInvGroup class]])
			[self performSegueWithIdentifier:@"NCDatabaseViewController" sender:[tableView cellForRowAtIndexPath:indexPath]];
		else if ([row.object isKindOfClass:[EVEDBInvType class]])
			[self performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController" sender:[tableView cellForRowAtIndexPath:indexPath]];
		else if ([row.object isKindOfClass:[NSString class]])
			[self performSegueWithIdentifier:row.object sender:[tableView cellForRowAtIndexPath:indexPath]];
	}
}

#pragma mark - Private

- (void) reload {
	EVEDBInvType* type = [(NCDatabaseTypeContainerViewController*) self.parentViewController type];
	NSString* s = [[type.description stringByRemovingHTMLTags] stringByReplacingHTMLEscapes];
	NSMutableString* description = [NSMutableString stringWithString:s ? s : @""];
	[description replaceOccurrencesOfString:@"\\r" withString:@"" options:0 range:NSMakeRange(0, description.length)];
	[description replaceOccurrencesOfString:@"\\n" withString:@"\n" options:0 range:NSMakeRange(0, description.length)];
	[description replaceOccurrencesOfString:@"\\t" withString:@"\t" options:0 range:NSMakeRange(0, description.length)];

	self.titleLabel.text = type.typeName;
	self.imageView.image = [UIImage imageNamed:type.typeLargeImageName];
	self.descriptionLabel.text = description;
	[self.view setNeedsLayout];
	[self loadItemAttributes];
}

- (void) loadItemAttributes {
	EVEDBInvType* type = [(NCDatabaseTypeContainerViewController*) self.parentViewController type];
	NCAccount *account = [NCAccount currentAccount];
	NCCharacterAttributes* attributes = [account characterAttributes];
	if (!attributes)
		attributes = [NCCharacterAttributes defaultCharacterAttributes];
	
	NSMutableArray* sections = [NSMutableArray new];

	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
									   title:NCTaskManagerDefaultTitle
									   block:^(NCTask *task) {
										   NCTrainingQueue* trainingQueue = [[NCTrainingQueue alloc] initWithAccount:account];
										   [trainingQueue addRequiredSkillsForType:type];
										   //self.trainingTime = [[TrainingQueue trainingQueueWithType:self.type] trainingTime];
										   
										   NSDictionary *skillRequirementsMap = [NSArray arrayWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"skillRequirementsMap" ofType:@"plist"]]];
										   
										   {
											   EVEDBDatabase* database = [EVEDBDatabase sharedDatabase];
											   __block NSInteger parentTypeID = type.typeID;
											   [database execSQLRequest:[NSString stringWithFormat:@"SELECT parentTypeID FROM invMetaTypes WHERE typeID=%d;", parentTypeID]
															resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																NSInteger typeID = sqlite3_column_int(stmt, 0);
																if (typeID)
																	parentTypeID = typeID;
																*needsMore = NO;
															}];
											   
											   __block NSInteger count = 0;
											   [database execSQLRequest:[NSString stringWithFormat:@"SELECT count() as count FROM invMetaTypes WHERE parentTypeID=%d;", parentTypeID]
															resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																count = sqlite3_column_int(stmt, 0);
															}];
											   
											   if (count > 0) {
												   NSMutableDictionary *section = [NSMutableDictionary dictionary];
												   section[@"title"] = NSLocalizedString(@"Variations", nil);
												   NSMutableArray* rows = [NSMutableArray array];
												   section[@"rows"] = rows;
												   
												   NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
												   row.title = NSLocalizedString(@"Variations", nil);
												   row.detail = [NSString stringWithFormat:@"%d", count + 1];
												   row.imageName = @"Icons/icon09_07.png";
												   row.object = @"NCDatabaseTypeVariationsViewController";
												   [rows addObject:row];
												   [sections addObject:section];
											   }
										   }
										   
										   if (account && account.activeSkillPlan && trainingQueue.skills.count > 0) {
											   NSMutableDictionary *section = [NSMutableDictionary dictionary];
											   section[@"title"] = NSLocalizedString(@"Skill Plan", nil);
											   NSMutableArray* rows = [NSMutableArray array];
											   section[@"rows"] = rows;
											   
											   if (type.group.categoryID == 16) {
												   EVECharacterSheetSkill* characterSkill = account.characterSheet.skillsMap[@(type.typeID)];
												   for (NSInteger level = characterSkill.level + 1; level <= 5; level++) {
													   NCTrainingQueue* trainingQueue = [[NCTrainingQueue alloc] initWithAccount:account];
													   [trainingQueue addSkill:type withLevel:level];
													   
													   NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													   row.title = [NSString stringWithFormat:NSLocalizedString(@"Train to level %d", nil), level];
													   row.detail = [NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:trainingQueue.trainingTime]];
													   row.imageName = @"Icons/icon50_13.png";
													   row.object = trainingQueue;
													   
													   [rows addObject:row];
												   }
											   }
											   else {
												   if (trainingQueue.skills.count) {
													   NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													   row.title = NSLocalizedString(@"Add required skills to training plan", nil);
													   row.detail = [NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:trainingQueue.trainingTime]];
													   row.imageName = @"Icons/icon50_13.png";
													   row.object = trainingQueue;
													   [rows addObject:row];
												   }
											   }
											   if (rows.count > 0)
												   [sections addObject:section];
										   }
										   
										   if (type.blueprint) {
											   NSMutableDictionary *section = [NSMutableDictionary dictionary];
											   NSMutableArray *rows = [NSMutableArray array];
											   
											   NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
											   row.title = NSLocalizedString(@"Blueprint", nil);
											   row.detail = [type.blueprint typeName];
											   row.imageName = [type.blueprint typeSmallImageName];
											   row.object = type.blueprint;
											   [rows addObject:row];
											   
											   section[@"title"] = NSLocalizedString(@"Manufacturing", nil);
											   section[@"rows"] = rows;
											   [sections addObject:section];
										   }
										   
										   for (EVEDBInvTypeAttributeCategory *category in type.attributeCategories) {
											   NSMutableDictionary *section = [NSMutableDictionary dictionary];
											   NSMutableArray *rows = [NSMutableArray array];
											   
											   if (category.categoryID == 8 && trainingQueue.trainingTime > 0) {
												   NSString *title = [NSString stringWithFormat:@"%@ (%@)", category.categoryName, [NSString stringWithTimeLeft:trainingQueue.trainingTime]];
												   section[@"title"] = title;
											   }
											   else
												   section[@"title"] = category.categoryID == 9 ? @"Other" : category.categoryName;
											   
											   section[@"rows"] = rows;
											   
											   for (EVEDBDgmTypeAttribute *attribute in category.publishedAttributes) {
												   if (attribute.attribute.unitID == EVEDBUnitIDAttributeID) {
													   EVEDBDgmAttributeType *dgmAttribute = [EVEDBDgmAttributeType dgmAttributeTypeWithAttributeTypeID:attribute.value error:nil];
													   
													   NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													   row.title = attribute.attribute.displayName;
													   row.detail = dgmAttribute.displayName;
													   row.imageName = dgmAttribute.icon.iconImageName;
													   [rows addObject:row];
												   }
												   else if (attribute.attribute.unitID == EVEDBUnitIDTypeID) {
													   NSInteger typeID = attribute.value;
													   EVEDBInvType *skill = [EVEDBInvType invTypeWithTypeID:typeID error:nil];
													   if (skill) {
														   for (NSDictionary *requirementMap in skillRequirementsMap) {
															   if ([requirementMap[SkillTreeRequirementIDKey] integerValue] == attribute.attributeID) {
																   EVEDBDgmTypeAttribute* level = type.attributesDictionary[@([requirementMap[SkillTreeSkillLevelIDKey] integerValue])];
																   NCSkillHierarchy* hierarchy = [[NCSkillHierarchy alloc] initWithSkill:skill level:level.value account:account];
																   
																   for (NCSkillHierarchySkill* skill in hierarchy.skills) {
																	   NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
																	   row.title = [NSString stringWithFormat:@"%@ %d", skill.typeName, skill.targetLevel];
																	   row.object = skill;
																	   row.indentationLevel = skill.nestingLevel;
																	   
																	   switch (skill.availability) {
																		   case NCSkillHierarchyAvailabilityLearned:
																			   row.imageName = @"Icons/icon50_11.png";
																			   row.accessoryImageName = @"Icons/icon38_193.png";
																			   break;
																		   case NCSkillHierarchyAvailabilityNotLearned:
																			   row.imageName = @"Icons/icon50_11.png";
																			   row.accessoryImageName = @"Icons/icon38_194.png";
																			   break;
																		   case NCSkillHierarchyAvailabilityLowLevel:
																			   row.imageName = @"Icons/icon50_11.png";
																			   row.accessoryImageName = @"Icons/icon38_195.png";
																			   break;
																		   default:
																			   break;
																	   }
																	   
																	   if (skill.availability != NCSkillHierarchyAvailabilityLearned)
																		   row.detail = [NSString stringWithTimeLeft:[skill trainingTimeWithCharacterAttributes:attributes]];
																	   
																	   [rows addObject:row];
																   }
																   break;
															   }
														   }
													   }
												   }
												   else if (attribute.attribute.unitID == EVEDBUnitIDGroupID) {
													   EVEDBInvGroup *group = [EVEDBInvGroup invGroupWithGroupID:attribute.value error:nil];
													   
													   NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													   row.title = attribute.attribute.displayName;
													   row.detail = group.groupName;
													   row.imageName = attribute.attribute.icon.iconImageName ? attribute.attribute.icon.iconImageName : group.icon.iconImageName;
													   row.object = group;
													   [rows addObject:row];
												   }
												   else if (attribute.attribute.unitID == EVEDBUnitIDSizeClass) {
													   NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													   row.title = attribute.attribute.displayName;
													   row.imageName = attribute.attribute.icon.iconImageName;
													   
													   int size = attribute.value;
													   if (size == 1)
														   row.detail = NSLocalizedString(@"Small", nil);
													   else if (size == 2)
														   row.detail = NSLocalizedString(@"Medium", nil);
													   else
														   row.detail = NSLocalizedString(@"Large", nil);
													   
													   [rows addObject:row];
												   }
												   else {
													   NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													   row.title = attribute.attribute.displayName;
													   row.imageName = attribute.attribute.icon.iconImageName;
													   
													   if (attribute.attributeID == EVEDBAttributeIDSKillLevel) {
														   NSInteger level = 0;
														   EVECharacterSheetSkill *skill = account.characterSheet.skillsMap[@(type.typeID)];
														   if (skill)
															   level = skill.level;
														   row.detail = [NSString stringWithFormat:@"%d", level];
													   }
													   else {
														   float value = 0;
														   NSString *unit;
														   
														   if (attribute.attributeID == EVEDBAttributeIDBaseWarpSpeed) {
															   value = [(EVEDBDgmTypeAttribute*) type.attributesDictionary[@(EVEDBAttributeIDWarpSpeedMultiplier)] value];
															   if (value == 0.0)
																   value = 1.0;
															   value *= 3;
															   unit = NSLocalizedString(@"AU/sec", nil);
														   }
														   else if (attribute.attribute.unit.unitID == EVEDBUnitIDInverseAbsolutePercentID || attribute.attribute.unit.unitID == EVEDBUnitIDInversedModifierPercentID) {
															   value = (1 - attribute.value) * 100;
															   unit = attribute.attribute.unit.displayName;
														   }
														   else if (attribute.attribute.unit.unitID == EVEDBUnitIDModifierPercentID) {
															   value = (attribute.value - 1) * 100;
															   unit = attribute.attribute.unit.displayName;
														   }
														   else if (attribute.attribute.unit.unitID == EVEDBUnitIDAbsolutePercentID) {
															   value = attribute.value * 100;
															   unit = attribute.attribute.unit.displayName;
														   }
														   else if (attribute.attribute.unit.unitID == EVEDBUnitIDMillisecondsID) {
															   value = attribute.value / 1000.0;
															   unit = attribute.attribute.unit.displayName;
														   }
														   else {
															   value = attribute.value;
															   unit = attribute.attribute.unit.displayName;
														   }
														   row.detail = [NSString stringWithFormat:@"%@ %@",
																		   [NSNumberFormatter neocomLocalizedStringFromNumber:@(value)],
																		   unit ? unit : @""];
													   }
													   [rows addObject:row];
												   }
											   }
											   if (rows.count > 0)
												   [sections addObject:section];
										   }
										   if (type.group.category.categoryID == EVEDBCategoryIDSkill) { //Skill
											   NSMutableDictionary *section = [NSMutableDictionary dictionary];
											   NSMutableArray *rows = [NSMutableArray array];
											   section[@"title"] = NSLocalizedString(@"Training time", nil);
											   section[@"rows"] = rows;
											   
											   float startSP = 0;
											   float endSP;
											   for (int i = 1; i <= 5; i++) {
												   endSP = [type skillPointsAtLevel:i];
												   NSTimeInterval needsTime = (endSP - startSP) / [attributes skillpointsPerSecondForSkill:type];
												   NSString *text = [NSString stringWithFormat:NSLocalizedString(@"SP: %@ (%@)", nil),
																	 [NSNumberFormatter neocomLocalizedStringFromInteger:endSP],
																	 [NSString stringWithTimeLeft:needsTime]];
												   
												   NSString* rank = [NSString stringWithFormat:NSLocalizedString(@"Level %d", nil), i];
												   
												   NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
												   row.title = rank;
												   row.detail = text;
												   row.imageName = @"Icons/icon50_13.png";
												   [rows addObject:row];
												   startSP = endSP;
											   }
											   [sections addObject:section];
										   }
									   }
						   completionHandler:^(NCTask *task) {
							   if (![task isCancelled]) {
								   self.sections = sections;
								   [self.tableView reloadData];
							   }
						   }];
}

@end
