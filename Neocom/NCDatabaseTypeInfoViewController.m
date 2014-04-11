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
#import "NCDatabaseTypeVariationsViewController.h"
#import "NCDatabaseTypeMarketInfoViewController.h"
#import "NCTrainingQueue.h"
#import "NCSkillHierarchy.h"
#import "NCDatabaseViewController.h"
#import "NSString+HTML.h"
#import "UIAlertView+Block.h"
#import "NCDatabaseTypeMasteryViewController.h"
#import "NCTableViewCell.h"

#define EVEDBUnitIDMillisecondsID 101
#define EVEDBUnitIDInverseAbsolutePercentID 108
#define EVEDBUnitIDModifierPercentID 109
#define EVEDBUnitIDInversedModifierPercentID 111
#define EVEDBUnitIDGroupID 115
#define EVEDBUnitIDTypeID 116
#define EVEDBUnitIDSizeClass 117
#define EVEDBUnitIDAttributeID 119
#define EVEDBUnitIDAbsolutePercentID 127
#define EVEDBUnitIDBoolean 137
#define EVEDBUnitIDBonus 139

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
@property (nonatomic, strong) NSString* cellIdentifier;
@property (nonatomic, assign) NSInteger indentationLevel;

@end

@interface NCDatabaseTypeInfoViewController ()
@property (nonatomic, strong) NSArray* sections;
@property (nonatomic, assign) BOOL needsLayout;
- (void) reload;
- (void) loadItemAttributes;
- (void) loadBlueprintAttributes;
- (void) loadNPCAttributes;
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
	if (self.navigationController.viewControllers[0] != self)
		self.navigationItem.leftBarButtonItem = nil;
	self.title = self.type.typeName;
	[self reload];
	self.refreshControl = nil;
	if (self.type.marketGroupID == 0)
		self.navigationItem.rightBarButtonItem = nil;
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
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	NSIndexPath* indexPath = [self.tableView indexPathForCell:sender];
	NCDatabaseTypeInfoViewControllerRow* row = self.sections[indexPath.section][@"rows"][indexPath.row];
	if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		controller.type = row.object;
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
		destinationViewController.type = self.type;
	}
	else if ([segue.identifier isEqualToString:@"NCDatabaseTypeMarketInfoViewController"]) {
		NCDatabaseTypeMarketInfoViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.type = self.type;
		destinationViewController.navigationItem.rightBarButtonItem = nil;
	}
	else if ([segue.identifier isEqualToString:@"NCDatabaseTypeMasteryViewController"]) {
		NCDatabaseTypeMasteryViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.type = self.type;
		destinationViewController.masteryLevel = [row.object integerValue];
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
	NCDatabaseTypeInfoViewControllerRow* row = self.sections[indexPath.section][@"rows"][indexPath.row];
	NSString *cellIdentifier = row.cellIdentifier;
	if (!cellIdentifier)
		cellIdentifier = @"Cell";
	
	NCTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	cell.titleLabel.text = row.title;
	cell.subtitleLabel.text = row.detail;
	cell.iconView.image = [UIImage imageNamed:row.imageName ? row.imageName : @"Icons/icon105_32.png"];
	cell.indentationLevel = row.indentationLevel;
	cell.indentationWidth = 16;
	
	cell.accessoryView = row.accessoryImageName ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:row.accessoryImageName]] : nil;
	//if (!cell.accessoryView)
	//	cell.accessoryType = [row.object isKindOfClass:[EVEDBObject class]] || [row.object isKindOfClass:[NSString class]] ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
	
	//cell.indentationLevel = row.indentationLevel;
	
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
	NCDatabaseTypeInfoViewControllerRow* row = self.sections[indexPath.section][@"rows"][indexPath.row];
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


#pragma mark - Private

- (void) reload {
	EVEDBInvType* type = self.type;
	NSString* s = [[type.description stringByRemovingHTMLTags] stringByReplacingHTMLEscapes];
	NSMutableString* description = [NSMutableString stringWithString:s ? s : @""];
	[description replaceOccurrencesOfString:@"\\r" withString:@"" options:0 range:NSMakeRange(0, description.length)];
	[description replaceOccurrencesOfString:@"\\n" withString:@"\n" options:0 range:NSMakeRange(0, description.length)];
	[description replaceOccurrencesOfString:@"\\t" withString:@"\t" options:0 range:NSMakeRange(0, description.length)];

	NSMutableAttributedString* title = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %d", type.typeName, type.typeID]];
	NSRange titleRange = NSMakeRange(0, type.typeName.length);
	NSRange typeIDRange = NSMakeRange(type.typeName.length + 1, title.length - type.typeName.length - 1);
	[title addAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:21]}
							  range:titleRange];
	[title addAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12],
									  (__bridge NSString*) (kCTSuperscriptAttributeName): @(-1),
									  NSForegroundColorAttributeName: [UIColor lightTextColor]}
							  range:typeIDRange];
	
	self.titleLabel.attributedText = title;
	self.imageView.image = [UIImage imageNamed:type.typeLargeImageName];
	
	if (type.traitsString.length > 0) {
		NSMutableAttributedString* traitsAttributedString = [[NSMutableAttributedString alloc] initWithString:type.traitsString
																								   attributes:@{NSFontAttributeName: self.descriptionLabel.font,
																												NSForegroundColorAttributeName: self.descriptionLabel.textColor}];
		
		
		
		NSRegularExpression* expression = [NSRegularExpression regularExpressionWithPattern:@"(<b>)([^<]*)(</b>)"
																					options:NSRegularExpressionCaseInsensitive
																					  error:nil];
		
		NSDictionary* boldAttributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:self.descriptionLabel.font.pointSize], NSForegroundColorAttributeName: [UIColor whiteColor]};
		[expression enumerateMatchesInString:type.traitsString
									 options:0
									   range:NSMakeRange(0, type.traitsString.length)
								  usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
									  if (result.numberOfRanges == 4) {
										  NSRange r = [result rangeAtIndex:2];
										  [traitsAttributedString addAttributes:boldAttributes
																		  range:r];
									  }
								  }];
		
		expression = [NSRegularExpression regularExpressionWithPattern:@"(</?b>)"
															   options:NSRegularExpressionCaseInsensitive
																 error:nil];
		[expression replaceMatchesInString:traitsAttributedString.mutableString options:0 range:NSMakeRange(0, traitsAttributedString.length) withTemplate:@""];
		
		NSMutableAttributedString* descriptionAttributesString = [[NSMutableAttributedString alloc] initWithString:[description stringByAppendingString:@"\n"] attributes:nil];
		[descriptionAttributesString appendAttributedString:traitsAttributedString];
		self.descriptionLabel.attributedText = descriptionAttributesString;
	}
	else
		self.descriptionLabel.text = description;

	
	
	self.needsLayout = YES;
	[self.view setNeedsLayout];
	
	if (type.group.categoryID == 9)
		[self loadBlueprintAttributes];
	else if (type.group.categoryID == 11)
		[self loadNPCAttributes];
	else
		[self loadItemAttributes];
}

- (void) loadItemAttributes {
	EVEDBInvType* type = self.type;
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
										   
										   NSDictionary *skillRequirementsMap = [NSArray arrayWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"skillRequirementsMap" ofType:@"plist"]]];
										   
										   {
											   EVEDBDatabase* database = [EVEDBDatabase sharedDatabase];
											   __block int32_t parentTypeID = type.typeID;
											   [database execSQLRequest:[NSString stringWithFormat:@"SELECT parentTypeID FROM invMetaTypes WHERE typeID=%d;", parentTypeID]
															resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																int32_t typeID = sqlite3_column_int(stmt, 0);
																if (typeID)
																	parentTypeID = typeID;
																*needsMore = NO;
															}];
											   
											   __block int32_t count = 0;
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
												   row.cellIdentifier = @"VariationsCell";
												   [rows addObject:row];
												   [sections addObject:section];
											   }
										   }
										   
										   if (account && account.activeSkillPlan) {
											   NSMutableDictionary *section = [NSMutableDictionary dictionary];
											   section[@"title"] = NSLocalizedString(@"Skill Plan", nil);
											   NSMutableArray* rows = [NSMutableArray array];
											   section[@"rows"] = rows;
											   
											   if (type.group.categoryID == 16) {
												   EVECharacterSheetSkill* characterSkill = account.characterSheet.skillsMap[@(type.typeID)];
												   for (int32_t level = characterSkill.level + 1; level <= 5; level++) {
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
											   else if (trainingQueue.skills.count > 0){
												   NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
												   row.title = NSLocalizedString(@"Add required skills to training plan", nil);
												   row.detail = [NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:trainingQueue.trainingTime]];
												   row.imageName = @"Icons/icon50_13.png";
												   row.object = trainingQueue;
												   [rows addObject:row];
											   }
											   if (rows.count > 0)
												   [sections addObject:section];
										   }
										   
										   if (type.masteries) {
											   NSMutableDictionary *section = [NSMutableDictionary dictionary];
											   //static NSString* icons[] = {@"Icons/icon79_02.png", @"Icons/icon79_03.png", @"Icons/icon79_04.png", @"Icons/icon79_05.png", @"Icons/icon79_05.png"};
											   
											   section[@"title"] = NSLocalizedString(@"Mastery", nil);
											   NSMutableArray* rows = [NSMutableArray array];
											   section[@"rows"] = rows;
											   
											   int32_t i = 0;
											   for (NSArray* masteries in type.masteries) {
												   NCTrainingQueue* trainingQueue = [[NCTrainingQueue alloc] initWithAccount:account];
												   for (EVEDBCertMastery* mastery in masteries)
													   [trainingQueue addMastery:mastery];
												   
												   NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
												   row.title = [NSString stringWithFormat:NSLocalizedString(@"Mastery %d", nil), i + 1];
												   if (trainingQueue.trainingTime > 0)
													   row.detail = [NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:trainingQueue.trainingTime]];
												   row.imageName = [EVEDBCertCertificate iconImageNameWithMasteryLevel:i];
												   row.cellIdentifier = @"MasteryCell";
												   row.object = @(i);
												   [rows addObject:row];
												   i++;
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
											   row.cellIdentifier = @"TypeCell";
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
												   if (attribute.attribute.unitID == EVEDBUnitIDTypeID) {
													   int32_t typeID = attribute.value;
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
																	   row.cellIdentifier = @"TypeCell";
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
																		   row.detail = [NSString stringWithTimeLeft:[skill trainingTimeToFinishWithCharacterAttributes:attributes]];
																	   
																	   [rows addObject:row];
																   }
																   break;
															   }
														   }
													   }
												   }
												   else {
													   if (attribute.attribute.displayName.length == 0 && attribute.attribute.attributeName.length == 0)
														   continue;
													   
													   NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													   row.title = attribute.attribute.displayName.length > 0 ? attribute.attribute.displayName : attribute.attribute.attributeName;

													   if (attribute.attribute.unitID == EVEDBUnitIDAttributeID) {
														   EVEDBDgmAttributeType *dgmAttribute = [EVEDBDgmAttributeType dgmAttributeTypeWithAttributeTypeID:attribute.value error:nil];
														   row.detail = dgmAttribute.displayName;
														   row.imageName = dgmAttribute.icon.iconImageName;
														   [rows addObject:row];
													   }
													   else if (attribute.attribute.unitID == EVEDBUnitIDGroupID) {
														   EVEDBInvGroup *group = [EVEDBInvGroup invGroupWithGroupID:attribute.value error:nil];
														   row.detail = group.groupName;
														   row.imageName = attribute.attribute.icon.iconImageName ? attribute.attribute.icon.iconImageName : group.icon.iconImageName;
														   row.object = group;
														   row.cellIdentifier = @"GroupCell";
														   [rows addObject:row];
													   }
													   else if (attribute.attribute.unitID == EVEDBUnitIDSizeClass) {
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
													   else if (attribute.attribute.unitID == EVEDBUnitIDBoolean) {
														   row.imageName = attribute.attribute.icon.iconImageName;
														   row.detail = attribute.value == 0.0 ? NSLocalizedString(@"Yes", nil) : NSLocalizedString(@"No", nil);
														   [rows addObject:row];
													   }
													   else if (attribute.attribute.unitID == EVEDBUnitIDBonus) {
														   row.imageName = attribute.attribute.icon.iconImageName;
														   row.detail = [NSString stringWithFormat:@"+%@",
																		 [NSNumberFormatter neocomLocalizedStringFromNumber:@(attribute.value)]];
														   [rows addObject:row];
													   }
													   else {
														   row.imageName = attribute.attribute.icon.iconImageName;
														   
														   if (attribute.attributeID == EVEDBAttributeIDSKillLevel) {
															   int32_t level = 0;
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
											   for (int32_t i = 1; i <= 5; i++) {
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

- (void) loadBlueprintAttributes {
	EVEDBInvType* type = self.type;
	NCAccount *account = [NCAccount currentAccount];
	NCCharacterAttributes* attributes = [account characterAttributes];
	if (!attributes)
		attributes = [NCCharacterAttributes defaultCharacterAttributes];
	
	NSMutableArray* sections = [NSMutableArray new];
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NSMutableArray *rows = [NSMutableArray new];
											 NCDatabaseTypeInfoViewControllerRow* row;
											 
											 EVEDBInvType* productType = type.blueprintType.productType;
											 EVEDBInvBlueprintType* blueprintType = type.blueprintType;
											 
											 row = [NCDatabaseTypeInfoViewControllerRow new];
											 row.title = NSLocalizedString(@"Product", nil);
											 row.detail = productType.typeName;
											 row.imageName = productType.typeSmallImageName;
											 row.object = productType;
											 row.cellIdentifier = @"TypeCell";
											 [rows addObject:row];
											 
											 row = [NCDatabaseTypeInfoViewControllerRow new];
											 row.title = NSLocalizedString(@"Waste Factor", nil);
											 row.detail = [NSString stringWithFormat:@"%d %%", blueprintType.wasteFactor];
											 [rows addObject:row];
											 
											 row = [NCDatabaseTypeInfoViewControllerRow new];
											 row.title = NSLocalizedString(@"Production Limit", nil);
											 row.detail = [NSNumberFormatter neocomLocalizedStringFromInteger:blueprintType.maxProductionLimit];
											 [rows addObject:row];
											 
											 row = [NCDatabaseTypeInfoViewControllerRow new];
											 row.title = NSLocalizedString(@"Productivity Modifier", nil);
											 row.detail = [NSNumberFormatter neocomLocalizedStringFromInteger:blueprintType.productivityModifier];
											 [rows addObject:row];
											 
											 row = [NCDatabaseTypeInfoViewControllerRow new];
											 row.title = NSLocalizedString(@"Manufacturing Time", nil);
											 row.detail = [NSString stringWithTimeLeft:blueprintType.productionTime];
											 [rows addObject:row];
											 
											 row = [NCDatabaseTypeInfoViewControllerRow new];
											 row.title = NSLocalizedString(@"Research Manufacturing Time", nil);
											 row.detail = [NSString stringWithTimeLeft:blueprintType.researchProductivityTime];
											 [rows addObject:row];
											 
											 row = [NCDatabaseTypeInfoViewControllerRow new];
											 row.title = NSLocalizedString(@"Research Material Time", nil);
											 row.detail = [NSString stringWithTimeLeft:blueprintType.researchMaterialTime];
											 [rows addObject:row];
											 
											 row = [NCDatabaseTypeInfoViewControllerRow new];
											 row.title = NSLocalizedString(@"Research Copy Time", nil);
											 row.detail = [NSString stringWithTimeLeft:blueprintType.researchCopyTime];
											 [rows addObject:row];
											 
											 row = [NCDatabaseTypeInfoViewControllerRow new];
											 row.title = NSLocalizedString(@"Research Tech Time", nil);
											 row.detail = [NSString stringWithTimeLeft:blueprintType.researchTechTime];
											 [rows addObject:row];
											 
											 [sections addObject:@{@"title" : NSLocalizedString(@"Blueprint", nil), @"rows" : rows}];
											 
											 NCTrainingQueue* trainingQueue = [[NCTrainingQueue alloc] initWithAccount:account];
											 [trainingQueue addRequiredSkillsForType:type];

											 
											 for (EVEDBInvTypeAttributeCategory *category in type.attributeCategories) {
												 NSString* title = nil;
												 NSMutableArray *rows = [NSMutableArray array];
												 
												 if (category.categoryID == 8 && trainingQueue.trainingTime > 0)
													 title = [NSString stringWithFormat:@"%@ (%@)", category.categoryName, [NSString stringWithTimeLeft:trainingQueue.trainingTime]];
												 else
													 title = category.categoryID == 9 ? @"Other" : category.categoryName;
												 
												 for (EVEDBDgmTypeAttribute *attribute in category.publishedAttributes) {
													 NSString *unit = attribute.attribute.unit.displayName;
													 
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = attribute.attribute.displayName;
													 row.detail = [NSString stringWithFormat:@"%@ %@", [NSNumberFormatter neocomLocalizedStringFromNumber:@(attribute.value)], unit ? unit : @""];
													 row.imageName = attribute.attribute.icon.iconImageName;
													 [rows addObject:row];
												 }
												 if (rows.count > 0)
													 [sections addObject:@{@"title" : title, @"rows" : rows}];
											 }
											 
											 NSArray* activities = [[type.blueprintType activities] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"activityID" ascending:YES]]];
											 for (EVEDBRamActivity* activity in activities) {
												 NSArray* requiredSkills = [type.blueprintType requiredSkillsForActivity:activity.activityID];
												 NCTrainingQueue* requiredSkillsQueue = [[NCTrainingQueue alloc] initWithAccount:account];
												 for (EVEDBInvTypeRequiredSkill* skill in requiredSkills)
													 [requiredSkillsQueue addSkill:skill withLevel:skill.requiredLevel];
												 
												 NSMutableArray *rows = [NSMutableArray array];
												 NSString* title = nil;
												 
												 if (requiredSkillsQueue.trainingTime > 0)
													 title = [NSString stringWithFormat:NSLocalizedString(@"%@ - Skills (%@)", nil), activity.activityName, [NSString stringWithTimeLeft:requiredSkillsQueue.trainingTime]];
												 else
													 title = [NSString stringWithFormat:NSLocalizedString(@"%@ - Skills", nil), activity.activityName];
												 
												 
												 if (requiredSkillsQueue.skills.count && account && account.activeSkillPlan) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Add required skills to training plan", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:requiredSkillsQueue.trainingTime]];
													 row.imageName = @"Icons/icon50_13.png";
													 row.object = requiredSkillsQueue;
													 [rows addObject:row];
												 }
												 
												 
												 for (EVEDBInvTypeRequiredSkill* skill in requiredSkills) {
													 NCSkillHierarchy* hierarchy = [[NCSkillHierarchy alloc] initWithSkill:skill level:skill.requiredLevel account:account];
													 
													 for (NCSkillHierarchySkill* skill in hierarchy.skills) {
														 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
														 row.title = [NSString stringWithFormat:@"%@ %d", skill.typeName, skill.targetLevel];
														 row.object = skill;
														 row.cellIdentifier = @"TypeCell";
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
															 row.detail = [NSString stringWithTimeLeft:[skill trainingTimeToFinishWithCharacterAttributes:attributes]];
														 
														 [rows addObject:row];
													 }
												 }
												 if (rows.count > 0)
													 [sections addObject:@{@"title" : title, @"rows" : rows}];
												 
												 rows = [NSMutableArray array];
												 
												 for (id requirement in [type.blueprintType requiredMaterialsForActivity:activity.activityID]) {
													 if ([requirement isKindOfClass:[EVEDBRamTypeRequirement class]]) {
														 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
														 row.title = [requirement requiredType].typeName;
														 row.detail = [NSNumberFormatter neocomLocalizedStringFromInteger:[[requirement valueForKey:@"quantity"] intValue]];
														 row.imageName = [[requirement requiredType] typeSmallImageName];
														 row.object = [requirement requiredType];
														 row.cellIdentifier = @"TypeCell";
														 [rows addObject:row];
													 }
													 else {
														 EVEDBInvTypeMaterial* material = requirement;
														 float waste = type.blueprintType.wasteFactor / 100.0;
														 NSInteger quantity = material.quantity * (1.0 + waste);
														 NSInteger perfect = material.quantity;
														 
														 NSInteger materialLevel  = quantity * 2.0 * (waste / (1.0 + waste)) - 1;
														 NSString* value;
														 if (materialLevel > 0)
															 value = [NSString stringWithFormat:NSLocalizedString(@"%@ (%@ at ME: %@)", nil),
																	  [NSNumberFormatter neocomLocalizedStringFromInteger:quantity],
																	  [NSNumberFormatter neocomLocalizedStringFromInteger:perfect],
																	  [NSNumberFormatter neocomLocalizedStringFromInteger:materialLevel]];
														 else
															 value = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:quantity] numberStyle:NSNumberFormatterDecimalStyle];
														 
														 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
														 row.title = material.materialType.typeName;
														 row.detail = value;
														 row.imageName = [material.materialType typeSmallImageName];
														 row.object = material.materialType;
														 row.cellIdentifier = @"TypeCell";
														 [rows addObject:row];
													 }
												 }
												 
												 if (rows.count > 0)
													 [sections addObject:@{@"title" : [NSString stringWithFormat:NSLocalizedString(@"%@ - Material / Mineral", nil), activity.activityName], @"rows" : rows}];
											 }
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.sections = sections;
									 [self.tableView reloadData];
								 }
							 }];
}

- (void) loadNPCAttributes {
	EVEDBInvType* type = self.type;

	NSMutableArray* sections = [NSMutableArray new];
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 EVEDBDgmTypeAttribute* emDamageAttribute = type.attributesDictionary[@(114)];
											 EVEDBDgmTypeAttribute* explosiveDamageAttribute = type.attributesDictionary[@(116)];
											 EVEDBDgmTypeAttribute* kineticDamageAttribute = type.attributesDictionary[@(117)];
											 EVEDBDgmTypeAttribute* thermalDamageAttribute = type.attributesDictionary[@(118)];
											 EVEDBDgmTypeAttribute* damageMultiplierAttribute = type.attributesDictionary[@(64)];
											 EVEDBDgmTypeAttribute* missileDamageMultiplierAttribute = type.attributesDictionary[@(212)];
											 EVEDBDgmTypeAttribute* missileTypeIDAttribute = type.attributesDictionary[@(507)];
											 EVEDBDgmTypeAttribute* missileVelocityMultiplierAttribute = type.attributesDictionary[@(645)];
											 EVEDBDgmTypeAttribute* missileFlightTimeMultiplierAttribute = type.attributesDictionary[@(646)];
											 
											 EVEDBDgmTypeAttribute* armorEmDamageResonanceAttribute = type.attributesDictionary[@(267)];
											 EVEDBDgmTypeAttribute* armorExplosiveDamageResonanceAttribute = type.attributesDictionary[@(268)];
											 EVEDBDgmTypeAttribute* armorKineticDamageResonanceAttribute = type.attributesDictionary[@(269)];
											 EVEDBDgmTypeAttribute* armorThermalDamageResonanceAttribute = type.attributesDictionary[@(270)];
											 
											 EVEDBDgmTypeAttribute* shieldEmDamageResonanceAttribute = type.attributesDictionary[@(271)];
											 EVEDBDgmTypeAttribute* shieldExplosiveDamageResonanceAttribute = type.attributesDictionary[@(272)];
											 EVEDBDgmTypeAttribute* shieldKineticDamageResonanceAttribute = type.attributesDictionary[@(273)];
											 EVEDBDgmTypeAttribute* shieldThermalDamageResonanceAttribute = type.attributesDictionary[@(274)];
											 
											 EVEDBDgmTypeAttribute* structureEmDamageResonanceAttribute = type.attributesDictionary[@(113)];
											 EVEDBDgmTypeAttribute* structureExplosiveDamageResonanceAttribute = type.attributesDictionary[@(111)];
											 EVEDBDgmTypeAttribute* structureKineticDamageResonanceAttribute = type.attributesDictionary[@(109)];
											 EVEDBDgmTypeAttribute* structureThermalDamageResonanceAttribute = type.attributesDictionary[@(110)];
											 
											 EVEDBDgmTypeAttribute* armorHPAttribute = type.attributesDictionary[@(265)];
											 EVEDBDgmTypeAttribute* hpAttribute = type.attributesDictionary[@(9)];
											 EVEDBDgmTypeAttribute* shieldCapacityAttribute = type.attributesDictionary[@(263)];
											 EVEDBDgmTypeAttribute* shieldRechargeRate = type.attributesDictionary[@(479)];
											 
											 EVEDBDgmTypeAttribute* optimalAttribute = type.attributesDictionary[@(54)];
											 EVEDBDgmTypeAttribute* falloffAttribute = type.attributesDictionary[@(158)];
											 EVEDBDgmTypeAttribute* trackingSpeedAttribute = type.attributesDictionary[@(160)];
											 
											 EVEDBDgmTypeAttribute* turretFireSpeedAttribute = type.attributesDictionary[@(51)];
											 EVEDBDgmTypeAttribute* missileLaunchDurationAttribute = type.attributesDictionary[@(506)];
											 
											 
											 //NPC Info
											 {
												 NSMutableArray* rows = [[NSMutableArray alloc] init];
												 
												 EVEDBDgmTypeAttribute* bountyAttribute = type.attributesDictionary[@(481)];
												 if (bountyAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = bountyAttribute.attribute.displayName;
													 row.imageName = bountyAttribute.attribute.icon.iconImageName;
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(bountyAttribute.value)]];
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* securityStatusBonusAttribute = type.attributesDictionary[@(252)];
												 if (securityStatusBonusAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Security Increase", nil);
													 row.imageName = securityStatusBonusAttribute.attribute.icon.iconImageName;
													 row.detail = [NSString stringWithFormat:@"%f", securityStatusBonusAttribute.value];
													 [rows addObject:row];
												 }
												 
												 
												 EVEDBDgmTypeAttribute* factionLossAttribute = type.attributesDictionary[@(562)];
												 if (factionLossAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Faction Stading Loss", nil);
													 row.imageName = factionLossAttribute.attribute.icon.iconImageName;
													 row.detail = [NSString stringWithFormat:@"%f", factionLossAttribute.value];
													 [rows addObject:row];
												 }
												 
												 if (rows.count > 0)
													 [sections addObject:@{@"title" : NSLocalizedString(@"NPC Info", nil), @"rows" : rows}];
											 }
											 
											 
											 //Turrets damage
											 
											 float emDamageTurret = 0;
											 float explosiveDamageTurret = 0;
											 float kineticDamageTurret = 0;
											 float thermalDamageTurret = 0;
											 float intervalTurret = 0;
											 float totalDamageTurret = 0;
											 
											 if (type.effectsDictionary[@(10)] || type.effectsDictionary[@(1086)]) {
												 NSMutableArray* rows = [[NSMutableArray alloc] init];
												 
												 float damageMultiplier = [damageMultiplierAttribute value];
												 if (damageMultiplier == 0)
													 damageMultiplier = 1;
												 
												 emDamageTurret = [emDamageAttribute value] * damageMultiplier;
												 explosiveDamageTurret = [explosiveDamageAttribute value] * damageMultiplier;
												 kineticDamageTurret = [kineticDamageAttribute value] * damageMultiplier;
												 thermalDamageTurret = [thermalDamageAttribute value] * damageMultiplier;
												 intervalTurret = [turretFireSpeedAttribute value] / 1000.0;
												 totalDamageTurret = emDamageTurret + explosiveDamageTurret + kineticDamageTurret + thermalDamageTurret;
												 float optimal = [optimalAttribute value];
												 float fallof = [falloffAttribute value];
												 float trackingSpeed = [trackingSpeedAttribute value];
												 
												 float tmpInterval = intervalTurret > 0 ? intervalTurret : 1;
												 
												 NSString* titles[] = {NSLocalizedString(@"Em Damage", nil), NSLocalizedString(@"Explosive Damage", nil), NSLocalizedString(@"Kinetic Damage", nil), NSLocalizedString(@"Thermal Damage", nil), NSLocalizedString(@"Total Damage", nil), NSLocalizedString(@"Rate of Fire", nil), NSLocalizedString(@"Optimal Range", nil), NSLocalizedString(@"Falloff", nil), NSLocalizedString(@"Tracking Speed", nil)};
												 NSString* icons[] = {@"em.png", @"explosion.png", @"kinetic.png", @"thermal.png", @"turrets.png", @"Icons/icon22_21.png", @"Icons/icon22_15.png", @"Icons/icon22_23.png", @"Icons/icon22_22.png"};
												 NSString* values[] = {
													 [NSString stringWithFormat:@"%.2f (%.2f/s, %.0f%%)", emDamageTurret, emDamageTurret / tmpInterval, totalDamageTurret > 0 ? emDamageTurret / totalDamageTurret * 100 : 0.0],
													 [NSString stringWithFormat:@"%.2f (%.2f/s, %.0f%%)", explosiveDamageTurret, explosiveDamageTurret / tmpInterval, totalDamageTurret > 0 ? explosiveDamageTurret / totalDamageTurret * 100 : 0.0],
													 [NSString stringWithFormat:@"%.2f (%.2f/s, %.0f%%)", kineticDamageTurret, kineticDamageTurret / tmpInterval, totalDamageTurret > 0 ? kineticDamageTurret / totalDamageTurret * 100 : 0.0],
													 [NSString stringWithFormat:@"%.2f (%.2f/s, %.0f%%)", thermalDamageTurret, thermalDamageTurret / tmpInterval, totalDamageTurret > 0 ? thermalDamageTurret / totalDamageTurret * 100 : 0.0],
													 [NSString stringWithFormat:@"%.2f (%.2f/s)", totalDamageTurret, totalDamageTurret / tmpInterval],
													 [NSString stringWithFormat:@"%.2f s", intervalTurret],
													 [NSString stringWithFormat:@"%@ m", [NSNumberFormatter neocomLocalizedStringFromInteger:optimal]],
													 [NSString stringWithFormat:@"%@ m", [NSNumberFormatter neocomLocalizedStringFromInteger:fallof]],
													 [NSString stringWithFormat:@"%f rad/sec", trackingSpeed]
												 };
												 
												 for (int i = 0; i < 9; i++) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = titles[i];
													 row.imageName = icons[i];
													 row.detail = values[i];
													 [rows addObject:row];
												 }
												 [sections addObject:@{@"title" : NSLocalizedString(@"Turrets Damage", nil), @"rows" : rows}];
											 }
											 
											 //Missiles damage
											 float emDamageMissile = 0;
											 float explosiveDamageMissile = 0;
											 float kineticDamageMissile = 0;
											 float thermalDamageMissile = 0;
											 float intervalMissile = 0;
											 float totalDamageMissile = 0;
											 
											 if (type.effectsDictionary[@(569)]) {
												 EVEDBInvType* missile = [EVEDBInvType invTypeWithTypeID:(int32_t)[missileTypeIDAttribute value] error:nil];
												 if (missile) {
													 NSMutableArray* rows = [[NSMutableArray alloc] init];
													 
													 EVEDBDgmTypeAttribute* emDamageAttribute = missile.attributesDictionary[@(114)];
													 EVEDBDgmTypeAttribute* explosiveDamageAttribute = missile.attributesDictionary[@(116)];
													 EVEDBDgmTypeAttribute* kineticDamageAttribute = missile.attributesDictionary[@(117)];
													 EVEDBDgmTypeAttribute* thermalDamageAttribute = missile.attributesDictionary[@(118)];
													 EVEDBDgmTypeAttribute* maxVelocityAttribute = missile.attributesDictionary[@(37)];
													 EVEDBDgmTypeAttribute* explosionDelayAttribute = missile.attributesDictionary[@(281)];
													 EVEDBDgmTypeAttribute* agilityAttribute = missile.attributesDictionary[@(70)];
													 
													 float missileDamageMultiplier = [missileDamageMultiplierAttribute value];
													 if (missileDamageMultiplier == 0)
														 missileDamageMultiplier = 1;
													 
													 emDamageMissile = [emDamageAttribute value] * missileDamageMultiplier;
													 explosiveDamageMissile = [explosiveDamageAttribute value] * missileDamageMultiplier;
													 kineticDamageMissile = [kineticDamageAttribute value] * missileDamageMultiplier;
													 thermalDamageMissile = [thermalDamageAttribute value] * missileDamageMultiplier;
													 intervalMissile = [missileLaunchDurationAttribute value] / 1000.0;
													 totalDamageMissile = emDamageMissile + explosiveDamageMissile + kineticDamageMissile + thermalDamageMissile;
													 
													 float missileVelocityMultiplier = missileVelocityMultiplierAttribute.value;
													 if (missileVelocityMultiplier == 0)
														 missileVelocityMultiplier = 1;
													 float missileFlightTimeMultiplier = missileFlightTimeMultiplierAttribute.value;
													 if (missileFlightTimeMultiplier == 0)
														 missileFlightTimeMultiplier = 1;
													 
													 float maxVelocity = maxVelocityAttribute.value * missileVelocityMultiplier;
													 float flightTime = explosionDelayAttribute.value * missileFlightTimeMultiplier / 1000.0;
													 float mass = missile.mass;
													 float agility = agilityAttribute.value;
													 
													 float accelTime = MIN(flightTime, mass * agility / 1000000.0);
													 float duringAcceleration = maxVelocity / 2 * accelTime;
													 float fullSpeed = maxVelocity * (flightTime - accelTime);
													 float optimal =  duringAcceleration + fullSpeed;
													 
													 float tmpInterval = intervalMissile > 0 ? intervalMissile : 1;
													 
													 NSString* titles[] = {NSLocalizedString(@"Em Damage", nil), NSLocalizedString(@"Explosive Damage", nil), NSLocalizedString(@"Kinetic Damage", nil), NSLocalizedString(@"Thermal Damage", nil), NSLocalizedString(@"Total Damage", nil), NSLocalizedString(@"Rate of Fire", nil), NSLocalizedString(@"Optimal Range", nil)};
													 NSString* icons[] = {@"em.png", @"explosion.png", @"kinetic.png", @"thermal.png", @"launchers.png", @"Icons/icon22_21.png", @"Icons/icon22_15.png"};
													 NSString* values[] = {
														 [NSString stringWithFormat:@"%.2f (%.2f/s, %.0f%%)", emDamageMissile, emDamageMissile / tmpInterval, totalDamageMissile > 0 ? emDamageMissile / totalDamageMissile * 100 : 0.0],
														 [NSString stringWithFormat:@"%.2f (%.2f/s, %.0f%%)", explosiveDamageMissile, explosiveDamageMissile / tmpInterval, totalDamageMissile > 0 ? explosiveDamageMissile / totalDamageMissile * 100 : 0.0],
														 [NSString stringWithFormat:@"%.2f (%.2f/s, %.0f%%)", kineticDamageMissile, kineticDamageMissile / tmpInterval, totalDamageMissile > 0 ? kineticDamageMissile / totalDamageMissile * 100 : 0.0],
														 [NSString stringWithFormat:@"%.2f (%.2f/s, %.0f%%)", thermalDamageMissile, thermalDamageMissile / tmpInterval, totalDamageMissile > 0 ? thermalDamageMissile / totalDamageMissile * 100 : 0.0],
														 [NSString stringWithFormat:@"%.2f (%.2f/s)", totalDamageMissile, totalDamageMissile / tmpInterval],
														 [NSString stringWithFormat:@"%.2f s", intervalMissile],
														 [NSString stringWithFormat:@"%@ m", [NSNumberFormatter neocomLocalizedStringFromInteger:optimal]]
													 };
													 
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Missile Type", nil);
													 row.detail = missile.typeName;
													 row.imageName = [missile typeSmallImageName];
													 row.object = missile;
													 row.cellIdentifier = @"TypeCell";
													 [rows addObject:row];
													 
													 for (int i = 0; i < 7; i++) {
														 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
														 row.title = titles[i];
														 row.imageName = icons[i];
														 row.detail = values[i];
														 [rows addObject:row];
													 }
													 [sections addObject:@{@"title" : NSLocalizedString(@"Missiles Damage", nil), @"rows" : rows}];
												 }
											 }
											 
											 //Total damage
											 if (totalDamageTurret > 0 && totalDamageMissile > 0) {
												 NSMutableArray* rows = [[NSMutableArray alloc] init];
												 
												 float emDPSTurret = emDamageTurret / intervalTurret;
												 float explosiveDPSTurret = explosiveDamageTurret / intervalTurret;
												 float kineticDPSTurret = kineticDamageTurret / intervalTurret;
												 float thermalDPSTurret = thermalDamageTurret / intervalTurret;
												 float totalDPSTurret = emDPSTurret + explosiveDPSTurret + kineticDPSTurret + thermalDPSTurret;
												 
												 if (intervalMissile == 0)
													 intervalMissile = 1;
												 
												 float emDPSMissile = emDamageMissile / intervalMissile;
												 float explosiveDPSMissile = explosiveDamageMissile / intervalMissile;
												 float kineticDPSMissile = kineticDamageMissile / intervalMissile;
												 float thermalDPSMissile = thermalDamageMissile / intervalMissile;
												 float totalDPSMissile = emDPSMissile + explosiveDPSMissile + kineticDPSMissile + thermalDPSMissile;
												 
												 float emDPS = emDPSTurret + emDPSMissile;
												 float explosiveDPS = explosiveDPSTurret + explosiveDPSMissile;
												 float kineticDPS = kineticDPSTurret + kineticDPSMissile;
												 float thermalDPS = thermalDPSTurret + thermalDPSMissile;
												 float totalDPS = totalDPSTurret + totalDPSMissile;
												 
												 
												 NSString* titles[] = {NSLocalizedString(@"Em Damage", nil), NSLocalizedString(@"Explosive Damage", nil), NSLocalizedString(@"Kinetic Damage", nil), NSLocalizedString(@"Thermal Damage", nil), NSLocalizedString(@"Total Damage", nil)};
												 NSString* icons[] = {@"em.png", @"explosion.png", @"kinetic.png", @"thermal.png", @"dps.png"};
												 NSString* values[] = {
													 [NSString stringWithFormat:@"%.2f (%.2f/s, %.0f%%)", emDamageTurret + emDamageMissile, emDPS, emDPS / totalDPS * 100],
													 [NSString stringWithFormat:@"%.2f (%.2f/s, %.0f%%)", explosiveDamageTurret + explosiveDamageMissile, explosiveDPS, explosiveDPS / totalDPS * 100],
													 [NSString stringWithFormat:@"%.2f (%.2f/s, %.0f%%)", kineticDamageTurret + kineticDamageMissile, kineticDPS, kineticDPS / totalDPS * 100],
													 [NSString stringWithFormat:@"%.2f (%.2f/s, %.0f%%)", thermalDamageTurret + thermalDamageMissile, thermalDPS, thermalDPS / totalDPS * 100],
													 [NSString stringWithFormat:@"%.2f (%.2f/s)", totalDamageTurret + totalDamageMissile, totalDPS]
												 };
												 
												 for (int i = 0; i < 5; i++) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = titles[i];
													 row.imageName = icons[i];
													 row.detail = values[i];
													 [rows addObject:row];
												 }
												 [sections addObject:@{@"title" : NSLocalizedString(@"Total Damage", nil), @"rows" : rows}];
											 }
											 
											 //Shield
											 {
												 NSMutableArray* rows = [[NSMutableArray alloc] init];
												 
												 float passiveRechargeRate = shieldRechargeRate.value > 0 ? 10.0 / (shieldRechargeRate.value / 1000.0) * 0.5 * (1 - 0.5) * shieldCapacityAttribute.value : 0;
												 float em = shieldEmDamageResonanceAttribute ? shieldEmDamageResonanceAttribute.value : 1;
												 float explosive = shieldExplosiveDamageResonanceAttribute ? shieldExplosiveDamageResonanceAttribute.value : 1;
												 float kinetic = shieldKineticDamageResonanceAttribute ? shieldKineticDamageResonanceAttribute.value : 1;
												 float thermal = shieldThermalDamageResonanceAttribute ? shieldThermalDamageResonanceAttribute.value : 1;
												 
												 
												 NSString* titles[] = {
													 NSLocalizedString(@"Shield Capacity", nil),
													 NSLocalizedString(@"Shield Em Damage Resistance", nil),
													 NSLocalizedString(@"Shield Explosive Damage Resistance", nil),
													 NSLocalizedString(@"Shield Kinetic Damage Resistance", nil),
													 NSLocalizedString(@"Shield Thermal Damage Resistance", nil),
													 NSLocalizedString(@"Shield Recharge Time", nil),
													 NSLocalizedString(@"Passive Recharge Rate", nil)};
												 NSString* icons[] = {@"shield.png", @"em.png", @"explosion.png", @"kinetic.png", @"thermal.png", @"Icons/icon22_16.png", @"shieldRecharge.png"};
												 NSString* values[] = {
													 [NSString stringWithFormat:@"%@ HP", [NSNumberFormatter neocomLocalizedStringFromInteger:shieldCapacityAttribute.value]],
													 [NSString stringWithFormat:@"%.0f %%", (1 - em) * 100],
													 [NSString stringWithFormat:@"%.0f %%", (1 - explosive) * 100],
													 [NSString stringWithFormat:@"%.0f %%", (1 - kinetic) * 100],
													 [NSString stringWithFormat:@"%.0f %%", (1 - thermal) * 100],
													 [NSString stringWithFormat:@"%@ s", [NSNumberFormatter neocomLocalizedStringFromInteger:shieldRechargeRate.value / 1000.0]],
													 [NSString stringWithFormat:@"%.2f HP/s", passiveRechargeRate],
												 };
												 
												 for (int i = 0; i < 7; i++) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = titles[i];
													 row.detail = values[i];
													 row.imageName = icons[i];
													 [rows addObject:row];
												 }
												 
												 if (type.effectsDictionary[@(2192)] || type.effectsDictionary[@(2193)] || type.effectsDictionary[@(2194)] || type.effectsDictionary[@(876)]) {
													 EVEDBDgmTypeAttribute* shieldBoostAmountAttribute = type.attributesDictionary[@(637)];
													 EVEDBDgmTypeAttribute* shieldBoostDurationAttribute = type.attributesDictionary[@(636)];
													 EVEDBDgmTypeAttribute* shieldBoostDelayChanceAttribute = type.attributesDictionary[@(639)];
													 
													 if (!shieldBoostDelayChanceAttribute)
														 shieldBoostDelayChanceAttribute = type.attributesDictionary[@(1006)];
													 if (!shieldBoostDelayChanceAttribute)
														 shieldBoostDelayChanceAttribute = type.attributesDictionary[@(1007)];
													 if (!shieldBoostDelayChanceAttribute)
														 shieldBoostDelayChanceAttribute = type.attributesDictionary[@(1008)];
													 
													 float shieldBoostAmount = shieldBoostAmountAttribute.value;
													 float shieldBoostDuration = shieldBoostDurationAttribute.value;
													 float shieldBoostDelayChance = shieldBoostDelayChanceAttribute.value;
													 float repairRate = shieldBoostDuration > 0 ? shieldBoostAmount * shieldBoostDelayChance / (shieldBoostDuration / 1000.0) : 0;
													 
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Repair Rate", nil);
													 row.detail = [NSString stringWithFormat:@"%.2f HP/s", repairRate + passiveRechargeRate];
													 row.imageName = @"shieldBooster.png";
													 [rows addObject:row];
												 }
												 [sections addObject:@{@"title" : NSLocalizedString(@"Shield", nil), @"rows" : rows}];
											 }
											 
											 //Armor
											 {
												 NSMutableArray* rows = [[NSMutableArray alloc] init];
												 
												 float em = armorEmDamageResonanceAttribute ? armorEmDamageResonanceAttribute.value : 1;
												 float explosive = armorExplosiveDamageResonanceAttribute ? armorExplosiveDamageResonanceAttribute.value : 1;
												 float kinetic = armorKineticDamageResonanceAttribute ? armorKineticDamageResonanceAttribute.value : 1;
												 float thermal = armorThermalDamageResonanceAttribute ? armorThermalDamageResonanceAttribute.value : 1;
												 
												 
												 NSString* titles[] = {
													 NSLocalizedString(@"Armor Hitpoints", nil),
													 NSLocalizedString(@"Armor Em Damage Resistance", nil),
													 NSLocalizedString(@"Armor Explosive Damage Resistance", nil),
													 NSLocalizedString(@"Armor Kinetic Damage Resistance", nil),
													 NSLocalizedString(@"Armor Thermal Damage Resistance", nil)};
												 NSString* icons[] = {@"armor.png", @"em.png", @"explosion.png", @"kinetic.png", @"thermal.png"};
												 NSString* values[] = {
													 [NSString stringWithFormat:@"%@ HP", [NSNumberFormatter neocomLocalizedStringFromInteger:armorHPAttribute.value]],
													 [NSString stringWithFormat:@"%.0f %%", (1 - em) * 100],
													 [NSString stringWithFormat:@"%.0f %%", (1 - explosive) * 100],
													 [NSString stringWithFormat:@"%.0f %%", (1 - kinetic) * 100],
													 [NSString stringWithFormat:@"%.0f %%", (1 - thermal) * 100]
												 };
												 
												 for (int i = 0; i < 5; i++) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = titles[i];
													 row.detail = values[i];
													 row.imageName = icons[i];
													 [rows addObject:row];
												 }
												 
												 if (type.effectsDictionary[@(2195)] || type.effectsDictionary[@(2196)] || type.effectsDictionary[@(2197)] || type.effectsDictionary[@(878)]) {
													 EVEDBDgmTypeAttribute* armorRepairAmountAttribute = type.attributesDictionary[@(631)];
													 EVEDBDgmTypeAttribute* armorRepairDurationAttribute = type.attributesDictionary[@(630)];
													 EVEDBDgmTypeAttribute* armorRepairDelayChanceAttribute = type.attributesDictionary[@(638)];
													 
													 if (!armorRepairDelayChanceAttribute)
														 armorRepairDelayChanceAttribute = type.attributesDictionary[@(1009)];
													 if (!armorRepairDelayChanceAttribute)
														 armorRepairDelayChanceAttribute = type.attributesDictionary[@(1010)];
													 if (!armorRepairDelayChanceAttribute)
														 armorRepairDelayChanceAttribute = type.attributesDictionary[@(1011)];
													 
													 float armorRepairAmount = armorRepairAmountAttribute.value;
													 float armorRepairDuration = armorRepairDurationAttribute.value;
													 float armorRepairDelayChance = armorRepairDelayChanceAttribute.value;
													 if (armorRepairDelayChance == 0)
														 armorRepairDelayChance = 1.0;
													 float repairRate = armorRepairDuration > 0 ? armorRepairAmount * armorRepairDelayChance / (armorRepairDuration / 1000.0) : 0;
													 
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Repair Rate", nil);
													 row.detail = [NSString stringWithFormat:@"%.2f HP/s", repairRate];
													 row.imageName = @"armorRepairer.png";
													 [rows addObject:row];
												 }
												 [sections addObject:@{@"title" : NSLocalizedString(@"Armor", nil), @"rows" : rows}];
											 }
											 
											 //Structure
											 {
												 NSMutableArray* rows = [[NSMutableArray alloc] init];
												 
												 float em = structureEmDamageResonanceAttribute ? structureEmDamageResonanceAttribute.value : 1;
												 float explosive = structureExplosiveDamageResonanceAttribute ? structureExplosiveDamageResonanceAttribute.value : 1;
												 float kinetic = structureKineticDamageResonanceAttribute ? structureKineticDamageResonanceAttribute.value : 1;
												 float thermal = structureThermalDamageResonanceAttribute ? structureThermalDamageResonanceAttribute.value : 1;
												 
												 
												 NSString* titles[] = {
													 NSLocalizedString(@"Structure Hitpoints", nil),
													 NSLocalizedString(@"Structure Em Damage Resistance", nil),
													 NSLocalizedString(@"Structure Explosive Damage Resistance", nil),
													 NSLocalizedString(@"Structure Kinetic Damage Resistance", nil),
													 NSLocalizedString(@"Structure Thermal Damage Resistance", nil)};
												 NSString* icons[] = {@"armor.png", @"em.png", @"explosion.png", @"kinetic.png", @"thermal.png"};
												 NSString* values[] = {
													 [NSString stringWithFormat:@"%@ HP", [NSNumberFormatter neocomLocalizedStringFromInteger:hpAttribute.value]],
													 [NSString stringWithFormat:@"%.0f %%", (1 - em) * 100],
													 [NSString stringWithFormat:@"%.0f %%", (1 - explosive) * 100],
													 [NSString stringWithFormat:@"%.0f %%", (1 - kinetic) * 100],
													 [NSString stringWithFormat:@"%.0f %%", (1 - thermal) * 100]
												 };
												 
												 for (int i = 0; i < 5; i++) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = titles[i];
													 row.detail = values[i];
													 row.imageName = icons[i];
													 [rows addObject:row];
												 }
												 [sections addObject:@{@"title" : NSLocalizedString(@"Structure", nil), @"rows" : rows}];
											 }
											 
											 //Targeting
											 {
												 NSMutableArray* rows = [[NSMutableArray alloc] init];
												 
												 EVEDBDgmTypeAttribute* attackRangeAttribute = type.attributesDictionary[@(247)];
												 if (attackRangeAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Attack Range", nil);
													 row.detail = [NSString stringWithFormat:@"%@ m", [NSNumberFormatter neocomLocalizedStringFromInteger:attackRangeAttribute.value]];
													 row.imageName = attackRangeAttribute.attribute.icon.iconImageName;
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* signatureRadiusAttribute = type.attributesDictionary[@(552)];
												 if (signatureRadiusAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = signatureRadiusAttribute.attribute.displayName;
													 row.detail = [NSString stringWithFormat:@"%@ m", [NSNumberFormatter neocomLocalizedStringFromInteger:signatureRadiusAttribute.value]];
													 row.imageName = signatureRadiusAttribute.attribute.icon.iconImageName;
													 [rows addObject:row];
												 }
												 
												 
												 EVEDBDgmTypeAttribute* scanResolutionAttribute = type.attributesDictionary[@(564)];
												 if (scanResolutionAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = scanResolutionAttribute.attribute.displayName;
													 row.detail = [NSString stringWithFormat:@"%@ m", [NSNumberFormatter neocomLocalizedStringFromInteger:scanResolutionAttribute.value]];
													 row.imageName = scanResolutionAttribute.attribute.icon.iconImageName;
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* sensorStrengthAttribute = type.attributesDictionary[@(208)];
												 if (sensorStrengthAttribute.value == 0)
													 sensorStrengthAttribute = type.attributesDictionary[@(209)];
												 if (sensorStrengthAttribute.value == 0)
													 sensorStrengthAttribute = type.attributesDictionary[@(210)];
												 if (sensorStrengthAttribute.value == 0)
													 sensorStrengthAttribute = type.attributesDictionary[@(211)];
												 if (sensorStrengthAttribute.value > 0) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = sensorStrengthAttribute.attribute.displayName;
													 row.detail = [NSString stringWithFormat:@"%.0f", sensorStrengthAttribute.value];
													 row.imageName = sensorStrengthAttribute.attribute.icon.iconImageName;
													 [rows addObject:row];
												 }
												 
												 if (rows.count > 0)
													 [sections addObject:@{@"title" : NSLocalizedString(@"Targeting", nil), @"rows" : rows}];
											 }
											 
											 //Movement
											 {
												 NSMutableArray* rows = [[NSMutableArray alloc] init];
												 
												 EVEDBDgmTypeAttribute* maxVelocityAttribute = type.attributesDictionary[@(37)];
												 if (maxVelocityAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = maxVelocityAttribute.attribute.displayName;
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ m/s", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:maxVelocityAttribute.value]];
													 row.imageName = maxVelocityAttribute.attribute.icon.iconImageName;
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* orbitVelocityAttribute = type.attributesDictionary[@(508)];
												 if (orbitVelocityAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = orbitVelocityAttribute.attribute.displayName;
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ m/s", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:orbitVelocityAttribute.value]];
													 row.imageName = @"Icons/icon22_13.png";
													 [rows addObject:row];
												 }
												 
												 
												 EVEDBDgmTypeAttribute* entityFlyRangeAttribute = type.attributesDictionary[@(416)];
												 if (entityFlyRangeAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Orbit Range", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:entityFlyRangeAttribute.value]];
													 row.imageName = @"Icons/icon22_15.png";
													 [rows addObject:row];
												 }
												 
												 if (rows.count > 0)
													 [sections addObject:@{@"title" : NSLocalizedString(@"Movement", nil), @"rows" : rows}];
											 }
											 
											 //Stasis Webifying
											 if (type.effectsDictionary[@(575)] || type.effectsDictionary[@(3714)]) {
												 NSMutableArray* rows = [[NSMutableArray alloc] init];
												 
												 EVEDBDgmTypeAttribute* speedFactorAttribute = type.attributesDictionary[@(20)];
												 if (speedFactorAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = speedFactorAttribute.attribute.displayName;
													 row.detail = [NSString stringWithFormat:@"%.0f %%", speedFactorAttribute.value];
													 row.imageName = speedFactorAttribute.attribute.icon.iconImageName;
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* modifyTargetSpeedRangeAttribute = type.attributesDictionary[@(514)];
												 if (modifyTargetSpeedRangeAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Range", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:modifyTargetSpeedRangeAttribute.value]];
													 row.imageName = @"targetingRange.png";
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* modifyTargetSpeedDurationAttribute = type.attributesDictionary[@(513)];
												 if (modifyTargetSpeedDurationAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Duration", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%.2f s", nil), modifyTargetSpeedDurationAttribute.value / 1000.0];
													 row.imageName = @"Icons/icon22_16.png";
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* modifyTargetSpeedChanceAttribute = type.attributesDictionary[@(512)];
												 if (modifyTargetSpeedChanceAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Webbing Chance", nil);
													 row.detail = [NSString stringWithFormat:@"%.0f %%", modifyTargetSpeedChanceAttribute.value * 100];
													 row.imageName = modifyTargetSpeedChanceAttribute.attribute.icon.iconImageName;
													 [rows addObject:row];
												 }
												 
												 if (rows.count > 0)
													 [sections addObject:@{@"title" : NSLocalizedString(@"Stasis Webifying", nil), @"rows" : rows}];
											 }
											 
											 //Warp Scramble
											 if (type.effectsDictionary[@(39)] || type.effectsDictionary[@(563)] || type.effectsDictionary[@(3713)]) {
												 NSMutableArray* rows = [[NSMutableArray alloc] init];
												 
												 EVEDBDgmTypeAttribute* warpScrambleStrengthAttribute = type.attributesDictionary[@(105)];
												 if (warpScrambleStrengthAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = warpScrambleStrengthAttribute.attribute.displayName;
													 row.detail = [NSString stringWithFormat:@"%.0f", warpScrambleStrengthAttribute.value];
													 row.imageName = warpScrambleStrengthAttribute.attribute.icon.iconImageName;
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* warpScrambleRangeAttribute = type.attributesDictionary[@(103)];
												 if (warpScrambleRangeAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = warpScrambleRangeAttribute.attribute.displayName;
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:warpScrambleRangeAttribute.value]];
													 row.imageName = warpScrambleRangeAttribute.attribute.icon.iconImageName;
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* warpScrambleDurationAttribute = type.attributesDictionary[@(505)];
												 if (warpScrambleDurationAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = warpScrambleDurationAttribute.attribute.displayName;
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%.2f s", nil), warpScrambleDurationAttribute.value / 1000];
													 row.imageName = warpScrambleDurationAttribute.attribute.icon.iconImageName;
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* warpScrambleChanceAttribute = type.attributesDictionary[@(504)];
												 if (warpScrambleChanceAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Scrambling Chance", nil);
													 row.detail = [NSString stringWithFormat:@"%.0f %%", warpScrambleChanceAttribute.value * 100];
													 row.imageName = warpScrambleChanceAttribute.attribute.icon.iconImageName;
													 [rows addObject:row];
												 }
												 
												 if (rows.count > 0)
													 [sections addObject:@{@"title" : NSLocalizedString(@"Warp Scramble", nil), @"rows" : rows}];
											 }
											 
											 //Target Painting
											 if (type.effectsDictionary[@(1879)]) {
												 NSMutableArray* rows = [[NSMutableArray alloc] init];
												 
												 EVEDBDgmTypeAttribute* signatureRadiusBonusAttribute = type.attributesDictionary[@(554)];
												 if (signatureRadiusBonusAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = signatureRadiusBonusAttribute.attribute.displayName;
													 row.detail = [NSString stringWithFormat:@"%.0f %%", signatureRadiusBonusAttribute.value];
													 row.imageName = signatureRadiusBonusAttribute.attribute.icon.iconImageName;
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* targetPaintRangeAttribute = type.attributesDictionary[@(941)];
												 if (targetPaintRangeAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Optimal Range", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:targetPaintRangeAttribute.value]];
													 row.imageName = @"Icons/icon22_15.png";
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* targetPaintFalloffAttribute = type.attributesDictionary[@(954)];
												 if (targetPaintFalloffAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Accuracy Falloff", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:targetPaintFalloffAttribute.value]];
													 row.imageName = @"Icons/icon22_23.png";
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* targetPaintDurationAttribute = type.attributesDictionary[@(945)];
												 if (targetPaintDurationAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Duration", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%.2f s", nil), targetPaintDurationAttribute.value / 1000];
													 row.imageName = @"Icons/icon22_16.png";
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* targetPaintChanceAttribute = type.attributesDictionary[@(935)];
												 if (targetPaintChanceAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Chance", nil);
													 row.detail = [NSString stringWithFormat:@"%.0f %%", targetPaintChanceAttribute.value * 100];
													 row.imageName = targetPaintChanceAttribute.attribute.icon.iconImageName;
													 [rows addObject:row];
												 }
												 
												 if (rows.count > 0)
													 [sections addObject:@{@"title" : NSLocalizedString(@"Target Painting", nil), @"rows" : rows}];
											 }
											 
											 //Tracking Disruption
											 if (type.effectsDictionary[@(1877)]) {
												 NSMutableArray* rows = [[NSMutableArray alloc] init];
												 
												 EVEDBDgmTypeAttribute* trackingDisruptMultiplierAttribute = type.attributesDictionary[@(948)];
												 if (trackingDisruptMultiplierAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Tracking Speed Bonus", nil);
													 row.detail = [NSString stringWithFormat:@"%.0f %%", (trackingDisruptMultiplierAttribute.value - 1) * 100];
													 row.imageName = @"Icons/icon22_22.png";
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* trackingDisruptRangeAttribute = type.attributesDictionary[@(940)];
												 if (trackingDisruptRangeAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Optimal Range", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:trackingDisruptRangeAttribute.value]];
													 row.imageName = @"Icons/icon22_15.png";
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* trackingDisruptFalloffAttribute = type.attributesDictionary[@(951)];
												 if (trackingDisruptFalloffAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Accuracy Falloff", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:trackingDisruptFalloffAttribute.value]];
													 row.imageName = @"Icons/icon22_23.png";
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* trackingDisruptDurationAttribute = type.attributesDictionary[@(944)];
												 if (trackingDisruptDurationAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Duration", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%.2f s", nil), trackingDisruptDurationAttribute.value / 1000];
													 row.imageName = @"Icons/icon22_16.png";
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* trackingDisruptChanceAttribute = type.attributesDictionary[@(933)];
												 if (trackingDisruptChanceAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Chance", nil);
													 row.detail = [NSString stringWithFormat:@"%.0f %%", trackingDisruptChanceAttribute.value * 100];
													 row.imageName = trackingDisruptChanceAttribute.attribute.icon.iconImageName;
													 [rows addObject:row];
												 }
												 
												 if (rows.count > 0)
													 [sections addObject:@{@"title" : NSLocalizedString(@"Tracking Disruption", nil), @"rows" : rows}];
											 }
											 
											 //Sensor Dampening
											 if (type.effectsDictionary[@(1878)]) {
												 NSMutableArray* rows = [[NSMutableArray alloc] init];
												 
												 EVEDBDgmTypeAttribute* maxTargetRangeMultiplierAttribute = type.attributesDictionary[@(237)];
												 if (maxTargetRangeMultiplierAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Max Targeting Range Bonus", nil);
													 row.detail = [NSString stringWithFormat:@"%.0f %%", (maxTargetRangeMultiplierAttribute.value - 1) * 100];
													 row.imageName = maxTargetRangeMultiplierAttribute.attribute.icon.iconImageName;
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* scanResolutionMultiplierAttribute = type.attributesDictionary[@(565)];
												 if (scanResolutionMultiplierAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Scan Resolution Bonus", nil);
													 row.detail = [NSString stringWithFormat:@"%.0f %%", (scanResolutionMultiplierAttribute.value - 1) * 100];
													 row.imageName = scanResolutionMultiplierAttribute.attribute.icon.iconImageName;
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* sensorDampenRangeAttribute = type.attributesDictionary[@(938)];
												 if (sensorDampenRangeAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Optimal Range", nil);
													 row.detail = [NSString stringWithFormat:@"%@ m", [NSNumberFormatter neocomLocalizedStringFromInteger:sensorDampenRangeAttribute.value]];
													 row.imageName = @"Icons/icon22_15.png";
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* sensorDampenFalloffAttribute = type.attributesDictionary[@(950)];
												 if (sensorDampenFalloffAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Accuracy Falloff", nil);
													 row.detail = [NSString stringWithFormat:@"%@ m", [NSNumberFormatter neocomLocalizedStringFromInteger:sensorDampenFalloffAttribute.value]];
													 row.imageName = @"Icons/icon22_23.png";
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* sensorDampenDurationAttribute = type.attributesDictionary[@(943)];
												 if (sensorDampenDurationAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Duration", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%.2f s", nil), sensorDampenDurationAttribute.value / 1000];
													 row.imageName = @"Icons/icon22_16.png";
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* sensorDampenChanceAttribute = type.attributesDictionary[@(932)];
												 if (sensorDampenChanceAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Chance", nil);
													 row.detail = [NSString stringWithFormat:@"%.0f %%", sensorDampenChanceAttribute.value * 100];
													 row.imageName = sensorDampenChanceAttribute.attribute.icon.iconImageName;
													 [rows addObject:row];
												 }
												 
												 if (rows.count > 0)
													 [sections addObject:@{@"title" : NSLocalizedString(@"Sensor Dampening", nil), @"rows" : rows}];
											 }
											 
											 //ECM Jamming
											 if (type.effectsDictionary[@(1871)] || type.effectsDictionary[@(1752)] || type.effectsDictionary[@(3710)] || type.effectsDictionary[@(4656)]) {
												 NSMutableArray* rows = [[NSMutableArray alloc] init];
												 
												 EVEDBDgmTypeAttribute* scanGravimetricStrengthBonusAttribute = type.attributesDictionary[@(238)];
												 if (scanGravimetricStrengthBonusAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = scanGravimetricStrengthBonusAttribute.attribute.displayName;
													 row.detail = [NSString stringWithFormat:@"%.2f", scanGravimetricStrengthBonusAttribute.value];
													 row.imageName = scanGravimetricStrengthBonusAttribute.attribute.icon.iconImageName;
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* scanLadarStrengthBonusAttribute = type.attributesDictionary[@(239)];
												 if (scanLadarStrengthBonusAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = scanLadarStrengthBonusAttribute.attribute.displayName;
													 row.detail = [NSString stringWithFormat:@"%.2f", scanLadarStrengthBonusAttribute.value];
													 row.imageName = scanLadarStrengthBonusAttribute.attribute.icon.iconImageName;
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* scanMagnetometricStrengthBonusAttribute = type.attributesDictionary[@(240)];
												 if (scanMagnetometricStrengthBonusAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = scanMagnetometricStrengthBonusAttribute.attribute.displayName;
													 row.detail = [NSString stringWithFormat:@"%.2f", scanMagnetometricStrengthBonusAttribute.value];
													 row.imageName = scanMagnetometricStrengthBonusAttribute.attribute.icon.iconImageName;
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* scanRadarStrengthBonusAttribute = type.attributesDictionary[@(241)];
												 if (scanLadarStrengthBonusAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = scanRadarStrengthBonusAttribute.attribute.displayName;
													 row.detail = [NSString stringWithFormat:@"%.2f", scanRadarStrengthBonusAttribute.value];
													 row.imageName = scanRadarStrengthBonusAttribute.attribute.icon.iconImageName;
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* targetJamRangeAttribute = type.attributesDictionary[@(936)];
												 if (targetJamRangeAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Optimal Range", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:targetJamRangeAttribute.value]];
													 row.imageName = @"Icons/icon22_15.png";
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* targetJamFalloffAttribute = type.attributesDictionary[@(953)];
												 if (targetJamFalloffAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Accuracy Falloff", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:targetJamFalloffAttribute.value]];
													 row.imageName = @"Icons/icon22_23.png";
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* targetJamDurationAttribute = type.attributesDictionary[@(929)];
												 if (targetJamDurationAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Duration", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%.2f s", nil), targetJamDurationAttribute.value / 1000];
													 row.imageName = @"Icons/icon22_16.png";
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* targetJamChanceAttribute = type.attributesDictionary[@(930)];
												 if (targetJamChanceAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Chance", nil);
													 row.detail = [NSString stringWithFormat:@"%.0f %%", targetJamChanceAttribute.value * 100];
													 row.imageName = targetJamChanceAttribute.attribute.icon.iconImageName;
													 [rows addObject:row];
												 }
												 
												 if (rows.count > 0)
													 [sections addObject:@{@"title" : NSLocalizedString(@"ECM Jamming", nil), @"rows" : rows}];
											 }
											 
											 //Energy Vampire
											 if (type.effectsDictionary[@(1872)]) {
												 NSMutableArray* rows = [[NSMutableArray alloc] init];
												 
												 EVEDBDgmTypeAttribute* capacitorDrainAmountAttribute = type.attributesDictionary[@(946)];
												 if (!capacitorDrainAmountAttribute)
													 capacitorDrainAmountAttribute = type.attributesDictionary[@(90)];
												 
												 EVEDBDgmTypeAttribute* capacitorDrainDurationAttribute = type.attributesDictionary[@(942)];
												 if (capacitorDrainAmountAttribute.value > 0) {
													 NSString* value;
													 if (capacitorDrainDurationAttribute) {
														 value = [NSString stringWithFormat:@"%@ GJ (%.2f GJ/s)",
																  [NSNumberFormatter neocomLocalizedStringFromInteger:capacitorDrainAmountAttribute.value],
																  capacitorDrainAmountAttribute.value / (capacitorDrainDurationAttribute.value / 1000)];
														 
													 }
													 else {
														 value = [NSString stringWithFormat:@"%@ GJ", [NSNumberFormatter neocomLocalizedStringFromInteger:capacitorDrainAmountAttribute.value]];
													 }
													 
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Amount", nil);
													 row.detail = value;
													 row.imageName = @"Icons/icon22_08.png";
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* capacitorDrainRangeAttribute = type.attributesDictionary[@(937)];
												 if (capacitorDrainRangeAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Optimal Range", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:capacitorDrainRangeAttribute.value]];
													 row.imageName = @"Icons/icon22_15.png";
													 [rows addObject:row];
												 }
												 
												 if (capacitorDrainDurationAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Duration", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%.2f s", nil), capacitorDrainDurationAttribute.value / 1000];
													 row.imageName = @"Icons/icon22_16.png";
													 [rows addObject:row];
												 }
												 
												 EVEDBDgmTypeAttribute* capacitorDrainChanceAttribute = type.attributesDictionary[@(931)];
												 if (capacitorDrainChanceAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Chance", nil);
													 row.detail = [NSString stringWithFormat:@"%.0f %%", capacitorDrainChanceAttribute.value * 100];
													 row.imageName = capacitorDrainChanceAttribute.attribute.icon.iconImageName;
													 [rows addObject:row];
												 }
												 
												 if (rows.count > 0)
													 [sections addObject:@{@"title" : NSLocalizedString(@"Energy Vampire", nil), @"rows" : rows}];
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
