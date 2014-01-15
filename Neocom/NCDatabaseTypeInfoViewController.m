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
#import "NCDatabaseTypeContainerViewController.h"

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
@property (nonatomic, assign) SEL selector;

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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
	
	cell.accessoryView = row.accessoryImageName ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:row.accessoryImageName]] : nil;
	if (!cell.accessoryView)
		cell.accessoryType = [row.object isKindOfClass:[EVEDBObject class]] ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
	
	//cell.indentationLevel = cellData.indentationLevel;
	
	return cell;
}

#pragma mark - Private

- (void) reload {
	[self loadItemAttributes];
}

- (void) loadItemAttributes {
	EVEDBInvType* type = [(NCDatabaseTypeContainerViewController*) self.parentViewController type];
	NCAccount *account = [NCAccount currentAccount];
	NSMutableArray* sections = [NSMutableArray new];

	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
									   title:NCTaskManagerDefaultTitle
									   block:^(NCTask *task) {
										   //self.trainingTime = [[TrainingQueue trainingQueueWithType:self.type] trainingTime];
										   //NSDictionary *skillRequirementsMap = [NSArray arrayWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"skillRequirementsMap" ofType:@"plist"]]];
										   
										   
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
												   row.selector = @selector(onVariations:);
												   row.object = type;
												   [rows addObject:row];
												   [sections addObject:section];
											   }
										   }
										   
										   /*TrainingQueue* requiredSkillsQueue = nil;
										   TrainingQueue* certificateRecommendationsQueue = nil;
										   if (account && account.skillPlan && (self.type.requiredSkills.count > 0 || self.type.certificateRecommendations.count > 0 || self.type.group.categoryID == 16)) {
											   NSMutableDictionary *section = [NSMutableDictionary dictionary];
											   section[@"title"] = NSLocalizedString(@"Skill Plan", nil);
											   NSMutableArray* rows = [NSMutableArray array];
											   section[@"rows"] = rows;
											   
											   requiredSkillsQueue = [[TrainingQueue alloc] initWithType:self.type];
											   certificateRecommendationsQueue = [[TrainingQueue alloc] init];
											   
											   for (EVEDBCrtRecommendation* recommendation in self.type.certificateRecommendations) {
												   for (EVEDBInvTypeRequiredSkill* skill in recommendation.certificate.trainingQueue.skills)
													   [certificateRecommendationsQueue addSkill:skill];
											   }
											   
											   if (self.type.group.categoryID == 16) {
												   EVECharacterSheetSkill* characterSkill = account.characterSheet.skillsMap[@(self.type.typeID)];
												   NSString* romanNumbers[] = {@"0", @"I", @"II", @"III", @"IV", @"V"};
												   for (NSInteger level = characterSkill.level + 1; level <= 5; level++) {
													   TrainingQueue* trainingQueue = [[TrainingQueue alloc] init];
													   [trainingQueue.skills addObjectsFromArray:requiredSkillsQueue.skills];
													   EVEDBInvTypeRequiredSkill* skill = [EVEDBInvTypeRequiredSkill invTypeWithInvType:self.type];
													   skill.requiredLevel = level;
													   skill.currentLevel = characterSkill.level;
													   [trainingQueue addSkill:skill];
													   
													   ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
													   cellData.title = [NSString stringWithFormat:NSLocalizedString(@"Train to level %@", nil), romanNumbers[level]];
													   cellData.value = [NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:trainingQueue.trainingTime]];
													   cellData.icon = @"Icons/icon50_13.png";
													   cellData.selector = @selector(onTrain:);
													   cellData.object = trainingQueue;
													   
													   [rows addObject:cellData];
												   }
											   }
											   else {
												   if (requiredSkillsQueue.skills.count) {
													   ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
													   cellData.title = NSLocalizedString(@"Add required skills to training plan", nil);
													   cellData.value = [NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:requiredSkillsQueue.trainingTime]];
													   cellData.icon = @"Icons/icon50_13.png";
													   cellData.selector = @selector(onTrain:);
													   cellData.object = requiredSkillsQueue;
													   [rows addObject:cellData];
												   }
												   if (certificateRecommendationsQueue.skills.count) {
													   ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
													   cellData.title = NSLocalizedString(@"Add recommended certificates to training plan", nil);
													   cellData.value = [NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:certificateRecommendationsQueue.trainingTime]];
													   cellData.icon = @"Icons/icon79_06.png";
													   cellData.selector = @selector(onTrain:);
													   cellData.object = certificateRecommendationsQueue;
													   [rows addObject:cellData];
												   }
											   }
											   if (rows.count > 0)
												   [self.sections addObject:section];
										   }
										   */
										   if (type.blueprint) {
											   NSMutableDictionary *section = [NSMutableDictionary dictionary];
											   NSMutableArray *rows = [NSMutableArray array];
											   
											   NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
											   row.title = NSLocalizedString(@"Blueprint", nil);
											   row.detail = [type.blueprint typeName];
											   row.imageName = [type.blueprint typeSmallImageName];
											   row.selector = @selector(onTypeInfo:);
											   row.object = type.blueprint;
											   [rows addObject:row];
											   
											   section[@"title"] = NSLocalizedString(@"Manufacturing", nil);
											   section[@"rows"] = rows;
											   [sections addObject:section];
										   }
										   
										   for (EVEDBInvTypeAttributeCategory *category in type.attributeCategories) {
											   NSMutableDictionary *section = [NSMutableDictionary dictionary];
											   NSMutableArray *rows = [NSMutableArray array];
											   
											   /*if (category.categoryID == 8 && self.trainingTime > 0) {
												   NSString *title = [NSString stringWithFormat:@"%@ (%@)", category.categoryName, [NSString stringWithTimeLeft:self.trainingTime]];
												   section[@"title"] = title;
											   }
											   else
												   section[@"title"] = category.categoryID == 9 ? @"Other" : category.categoryName;*/
											   
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
													   /*int typeID = attribute.value;
													   EVEDBInvType *skill = [EVEDBInvType invTypeWithTypeID:typeID error:nil];
													   if (skill) {
														   for (NSDictionary *requirementMap in skillRequirementsMap) {
															   if ([requirementMap[SkillTreeRequirementIDKey] integerValue] == attribute.attributeID) {
																   EVEDBDgmTypeAttribute *level = self.type.attributesDictionary[requirementMap[SkillTreeSkillLevelIDKey]];
																   SkillTree *skillTree = [SkillTree skillTreeWithRootSkill:skill skillLevel:level.value];
																   for (SkillTreeItem *skill in skillTree.skills) {
																	   ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
																	   cellData.title = [NSString stringWithFormat:@"%@ %@", skill.typeName, [skill romanSkillLevel]];
																	   cellData.selector = @selector(onTypeInfo:);
																	   cellData.object = skill;
																	   cellData.indentationLevel = skill.hierarchyLevel;
																	   
																	   switch (skill.skillAvailability) {
																		   case SkillTreeItemAvailabilityLearned:
																			   cellData.icon = @"Icons/icon50_11.png";
																			   cellData.accessoryImage = @"Icons/icon38_193.png";
																			   break;
																		   case SkillTreeItemAvailabilityNotLearned:
																			   cellData.icon = @"Icons/icon50_11.png";
																			   cellData.accessoryImage = @"Icons/icon38_194.png";
																			   break;
																		   case SkillTreeItemAvailabilityLowLevel:
																			   cellData.icon = @"Icons/icon50_11.png";
																			   cellData.accessoryImage = @"Icons/icon38_195.png";
																			   break;
																		   default:
																			   break;
																	   }
																	   [rows addObject:cellData];
																   }
																   break;
															   }
														   }
													   }*/
												   }
												   else if (attribute.attribute.unitID == EVEDBUnitIDGroupID) {
													   EVEDBInvGroup *group = [EVEDBInvGroup invGroupWithGroupID:attribute.value error:nil];
													   
													   NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													   row.title = attribute.attribute.displayName;
													   row.detail = group.groupName;
													   row.imageName = attribute.attribute.icon.iconImageName ? attribute.attribute.icon.iconImageName : group.icon.iconImageName;
													   row.selector = @selector(onGroupInfo:);
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
/*										   if (self.type.group.category.categoryID == EVEDBCategoryIDSkill) { //Skill
											   EVEAccount *account = [EVEAccount currentAccount];
											   if (!account || account.characterSheet == nil)
												   account = [EVEAccount dummyAccount];
											   NSMutableDictionary *section = [NSMutableDictionary dictionary];
											   NSMutableArray *rows = [NSMutableArray array];
											   section[@"title"] = NSLocalizedString(@"Training time", nil);
											   [self.sections addObject:section];
											   
											   float startSP = 0;
											   float endSP;
											   for (int i = 1; i <= 5; i++) {
												   endSP = [self.type skillPointsAtLevel:i];
												   NSTimeInterval needsTime = (endSP - startSP) / [account.characterAttributes skillpointsPerSecondForSkill:self.type];
												   NSString *text = [NSString stringWithFormat:NSLocalizedString(@"SP: %@ (%@)", nil),
																	 [NSNumberFormatter neocomLocalizedStringFromInteger:endSP],
																	 [NSString stringWithTimeLeft:needsTime]];
												   
												   NSString *rank = (i == 1 ? NSLocalizedString(@"Level I", nil) : (i == 2 ? NSLocalizedString(@"Level II", nil) : (i == 3 ? NSLocalizedString(@"Level III", nil) : (i == 4 ? NSLocalizedString(@"Level IV", nil) : NSLocalizedString(@"Level V", nil)))));
												   
												   ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
												   cellData.title = rank;
												   cellData.value = text;
												   cellData.icon = @"Icons/icon50_13.png";
												   [rows addObject:cellData];
												   startSP = endSP;
											   }
											   [section setValue:rows forKey:@"rows"];
										   }*/
										   
/*										   if (self.type.certificateRecommendations.count > 0) {
											   NSMutableDictionary *section = [NSMutableDictionary dictionary];
											   NSMutableArray *rows = [NSMutableArray array];
											   TrainingQueue* trainingQueue = [[TrainingQueue alloc] init];
											   [self.sections addObject:section];
											   
											   for (EVEDBCrtRecommendation* recommendation in self.type.certificateRecommendations) {
												   ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
												   cellData.title = [NSString stringWithFormat:@"%@ - %@", recommendation.certificate.certificateClass.className, recommendation.certificate.gradeText];
												   cellData.icon = recommendation.certificate.iconImageName;
												   cellData.selector = @selector(onTrain:);
												   cellData.object = recommendation.certificate.trainingQueue;
												   
												   if (recommendation.certificate.trainingQueue.trainingTime > 0)
													   cellData.value = [NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil),
																		 [NSString stringWithTimeLeft:recommendation.certificate.trainingQueue.trainingTime]];
												   cellData.accessoryImage = recommendation.certificate.stateIconImageName;
												   
												   for (EVEDBInvTypeRequiredSkill* skill in recommendation.certificate.trainingQueue.skills)
													   [trainingQueue addSkill:skill];
												   [rows addObject:cellData];
											   }
											   
											   if (trainingQueue.trainingTime > 0)
												   section[@"title"] = [NSString stringWithFormat:NSLocalizedString(@"Recommended certificates (%@)", nil), [NSString stringWithTimeLeft:trainingQueue.trainingTime]];
											   else
												   section[@"title"] = NSLocalizedString(@"Recommended certificates", nil);
											   [section setValue:rows forKey:@"rows"];
										   }*/
									   }
						   completionHandler:^(NCTask *task) {
							   if (![task isCancelled]) {
								   self.sections = sections;
								   [self.tableView reloadData];
							   }
						   }];
}

@end
