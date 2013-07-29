//
//  ItemInfoViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ItemInfoViewController.h"
#import "ItemsDBViewController.h"
#import "ItemViewController.h"
#import "UIView+Nib.h"
#import "Globals.h"
#import "EVEDBAPI.h"
#import "SkillTree.h"
#import "EVEAccount.h"
#import "EVEOnlineAPI.h"
#import "NSString+HTML.h"
#import "TrainingQueue.h"
#import "NSString+TimeLeft.h"
#import "EVEDBCrtCertificate+TrainingQueue.h"
#import "EVEDBCrtCertificate+State.h"
#import "CertificateViewController.h"
#import "VariationsViewController.h"
#import "appearance.h"
#import "NSNumberFormatter+Neocom.h"
#import "CollapsableTableHeaderView.h"
#import "UIAlertView+Block.h"
#import "GroupedCell.h"

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

@interface ItemInfoCellData : NSObject
@property (nonatomic, copy) NSString* title;
@property (nonatomic, copy) NSString* value;
@property (nonatomic, copy) NSString* icon;
@property (nonatomic, copy) NSString* accessoryImage;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, strong) id object;
@property (nonatomic, assign) NSInteger indentationLevel;
@end

@implementation ItemInfoCellData
@end


@interface ItemInfoViewController()
@property (nonatomic, assign) NSTimeInterval trainingTime;
@property (nonatomic, strong) NSIndexPath* modifiedIndexPath;
@property (nonatomic, strong) NSMutableArray *sections;

- (void) loadAttributes;
- (void) loadNPCAttributes;
- (void) loadBlueprintAttributes;
- (void) onTypeInfo:(EVEDBInvType*) type;
- (void) onGroupInfo:(EVEDBInvGroup*) group;
- (void) onTrain:(TrainingQueue*) trainingQueue;
- (void) onVariations:(EVEDBInvType*) type;
@end


@implementation ItemInfoViewController

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.clearsSelectionOnViewWillAppear = YES;
	
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	self.titleLabel.text = self.type.typeName;
	self.title = NSLocalizedString(@"Info", nil);
	self.volumeLabel.text = [NSString stringWithFormat:@"%@ m3", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:self.type.volume] numberStyle:NSNumberFormatterDecimalStyle]];
	self.massLabel.text = [NSString stringWithFormat:@"%@ kg", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:self.type.mass] numberStyle:NSNumberFormatterDecimalStyle]];
	self.capacityLabel.text = [NSString stringWithFormat:@"%@ m3", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:self.type.capacity] numberStyle:NSNumberFormatterDecimalStyle]];
	self.radiusLabel.text = [NSString stringWithFormat:@"%@ m", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:self.type.radius] numberStyle:NSNumberFormatterDecimalStyle]];
	NSString* s = [[self.type.description stringByRemovingHTMLTags] stringByReplacingHTMLEscapes];
	NSMutableString* description = [NSMutableString stringWithString:s ? s : @""];
	[description replaceOccurrencesOfString:@"\\r" withString:@"" options:0 range:NSMakeRange(0, description.length)];
	[description replaceOccurrencesOfString:@"\\n" withString:@"\n" options:0 range:NSMakeRange(0, description.length)];
	[description replaceOccurrencesOfString:@"\\t" withString:@"\t" options:0 range:NSMakeRange(0, description.length)];
	self.descriptionLabel.text = description;
	self.imageView.image = [UIImage imageNamed:[self.type typeLargeImageName]];
	
	EVEDBDgmTypeAttribute *attribute = self.type.attributesDictionary[@(422)];
	int techLevel = attribute.value;
	if (techLevel == 1)
		self.techLevelImageView.image = [UIImage imageNamed:@"Icons/icon38_140.png"];
	else if (techLevel == 2)
		self.techLevelImageView.image = [UIImage imageNamed:@"Icons/icon38_141.png"];
	else if (techLevel == 3)
		self.techLevelImageView.image = [UIImage imageNamed:@"Icons/icon38_142.png"];
	else
		self.techLevelImageView.image = nil;
	
	self.trainingTime = 0;
	self.sections = [[NSMutableArray alloc] init];
	if (self.type.group.categoryID == 11)
		[self loadNPCAttributes];
	else if (self.type.group.categoryID == 9)
		[self loadBlueprintAttributes];
	else
		[self loadAttributes];
	
//	attributesTable.frame = CGRectMake(attributesTable.frame.origin.x, typeInfoView.frame.size.height, attributesTable.frame.size.width, self.view.frame.size.height);
}

- (void) viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	CGRect r = [self.descriptionLabel textRectForBounds:CGRectMake(0, 0, self.descriptionLabel.frame.size.width, 1024) limitedToNumberOfLines:0];
	self.descriptionLabel.frame = CGRectMake(self.descriptionLabel.frame.origin.x, self.descriptionLabel.frame.origin.y, self.descriptionLabel.frame.size.width, r.size.height);
	
	r = CGRectMake(self.typeInfoView.frame.origin.x, self.typeInfoView.frame.origin.y, self.typeInfoView.frame.size.width, self.descriptionLabel.frame.origin.y + self.descriptionLabel.frame.size.height + 5);
	if (!CGRectEqualToRect(r, self.typeInfoView.frame)) {
		self.typeInfoView.frame = r;
		self.tableView.tableHeaderView = self.typeInfoView;
	}
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	if ([self isViewLoaded] && [self.view window] == nil) {
		self.view = nil;
		self.sections = nil;
	}
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
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
	ItemInfoCellData* cellData = self.sections[indexPath.section][@"rows"][indexPath.row];
	GroupedCell* cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
		cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
	cell.textLabel.text = cellData.title;
	cell.detailTextLabel.text = cellData.value;
	cell.imageView.image = [UIImage imageNamed:cellData.icon ? cellData.icon : @"Icons/icon105_32.png"];
	//cell.imageView.image = cellData.icon ? [UIImage imageNamed:cellData.icon] : nil;
	
	cell.accessoryView = cellData.accessoryImage ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:cellData.accessoryImage]] : nil;
	if (!cell.accessoryView)
		cell.accessoryType = [cellData.object isKindOfClass:[EVEDBObject class]] ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
	
	cell.indentationLevel = cellData.indentationLevel;
	
	GroupedCellGroupStyle groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = groupStyle;
	
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
	view.titleLabel.text = [self tableView:tableView titleForHeaderInSection:section];
	return view;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 22;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	ItemInfoCellData* cellData = self.sections[indexPath.section][@"rows"][indexPath.row];
	if (cellData.selector)
		SuppressPerformSelectorLeakWarning(
										   [self performSelector:cellData.selector withObject:cellData.object];
		);
}

#pragma mark - Private

- (void) loadAttributes {
	EUOperation* operation = [EUOperation operationWithIdentifier:@"ItemInfoViewController+load" name:NSLocalizedString(@"Loading Attributes", nil)];
	[operation addExecutionBlock:^{
		self.trainingTime = [[TrainingQueue trainingQueueWithType:self.type] trainingTime];
		NSDictionary *skillRequirementsMap = [NSArray arrayWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"skillRequirementsMap" ofType:@"plist"]]];
		EVEAccount *account = [EVEAccount currentAccount];
		[account updateSkillpoints];
		
		{
			EVEDBDatabase* database = [EVEDBDatabase sharedDatabase];
			__block NSInteger parentTypeID = self.type.typeID;
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
				
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Variations", nil);
				cellData.value = [NSString stringWithFormat:@"%d", count + 1];
				cellData.icon = @"Icons/icon09_07.png";
				cellData.selector = @selector(onVariations:);
				cellData.object = self.type;
				[rows addObject:cellData];
				[self.sections addObject:section];
			}
		}
		
		TrainingQueue* requiredSkillsQueue = nil;
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
		
		if (self.type.blueprint) {
			NSMutableDictionary *section = [NSMutableDictionary dictionary];
			NSMutableArray *rows = [NSMutableArray array];
			
			ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
			cellData.title = NSLocalizedString(@"Blueprint", nil);
			cellData.value = [self.type.blueprint typeName];
			cellData.icon = [self.type.blueprint typeSmallImageName];
			cellData.selector = @selector(onTypeInfo:);
			cellData.object = self.type.blueprint;
			[rows addObject:cellData];
			
			section[@"title"] = NSLocalizedString(@"Manufacturing", nil);
			section[@"rows"] = rows;
			[self.sections addObject:section];
		}
		
		for (EVEDBInvTypeAttributeCategory *category in self.type.attributeCategories) {
			NSMutableDictionary *section = [NSMutableDictionary dictionary];
			NSMutableArray *rows = [NSMutableArray array];
			
			if (category.categoryID == 8 && self.trainingTime > 0) {
				NSString *title = [NSString stringWithFormat:@"%@ (%@)", category.categoryName, [NSString stringWithTimeLeft:self.trainingTime]];
				section[@"title"] = title;
			}
			else
				section[@"title"] = category.categoryID == 9 ? @"Other" : category.categoryName;
			
			section[@"rows"] = rows;
			
			for (EVEDBDgmTypeAttribute *attribute in category.publishedAttributes) {
				if (attribute.attribute.unitID == EVEDBUnitIDAttributeID) {
					EVEDBDgmAttributeType *dgmAttribute = [EVEDBDgmAttributeType dgmAttributeTypeWithAttributeTypeID:attribute.value error:nil];
					
					ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
					cellData.title = attribute.attribute.displayName;
					cellData.value = dgmAttribute.displayName;
					cellData.icon = dgmAttribute.icon.iconImageName;
					[rows addObject:cellData];
				}
				else if (attribute.attribute.unitID == EVEDBUnitIDTypeID) {
					int typeID = attribute.value;
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
					}
				}
				else if (attribute.attribute.unitID == EVEDBUnitIDGroupID) {
					EVEDBInvGroup *group = [EVEDBInvGroup invGroupWithGroupID:attribute.value error:nil];

					ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
					cellData.title = attribute.attribute.displayName;
					cellData.value = group.groupName;
					cellData.icon = attribute.attribute.icon.iconImageName ? attribute.attribute.icon.iconImageName : group.icon.iconImageName;
					cellData.selector = @selector(onGroupInfo:);
					cellData.object = group;
					[rows addObject:cellData];
				}
				else if (attribute.attribute.unitID == EVEDBUnitIDSizeClass) {
					ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
					cellData.title = attribute.attribute.displayName;
					cellData.icon = attribute.attribute.icon.iconImageName;

					int size = attribute.value;
					if (size == 1)
						cellData.value = NSLocalizedString(@"Small", nil);
					else if (size == 2)
						cellData.value = NSLocalizedString(@"Medium", nil);
					else
						cellData.value = NSLocalizedString(@"Large", nil);

					[rows addObject:cellData];
				}
				else {
					ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
					cellData.title = attribute.attribute.displayName;
					cellData.icon = attribute.attribute.icon.iconImageName;

					if (attribute.attributeID == EVEDBAttributeIDSKillLevel) {
						NSInteger level = 0;
						EVECharacterSheetSkill *skill = account.characterSheet.skillsMap[@(self.type.typeID)];
						if (skill)
							level = skill.level;
						cellData.value = [NSString stringWithFormat:@"%d", level];
					}
					else {
						float value = 0;
						NSString *unit;
						
						if (attribute.attributeID == EVEDBAttributeIDBaseWarpSpeed) {
							value = [(EVEDBDgmTypeAttribute*) self.type.attributesDictionary[@(EVEDBAttributeIDWarpSpeedMultiplier)] value];
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
						cellData.value = [NSString stringWithFormat:@"%@ %@",
										  [NSNumberFormatter neocomLocalizedStringFromNumber:@(value)],
										  unit ? unit : @""];
					}
					[rows addObject:cellData];
				}
			}
			if (rows.count > 0)
				[self.sections addObject:section];
		}
		if (self.type.group.category.categoryID == EVEDBCategoryIDSkill) { //Skill
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
		}
		
		if (self.type.certificateRecommendations.count > 0) {
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
		}
	}];
	
	[operation setCompletionBlockInMainThread:^{
		[self.tableView reloadData];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) loadNPCAttributes {
	EUOperation* operation = [EUOperation operationWithIdentifier:@"ItemInfoViewController+load" name:NSLocalizedString(@"Loading Attributes", nil)];
	[operation addExecutionBlock:^{
		EVEDBDgmTypeAttribute* emDamageAttribute = self.type.attributesDictionary[@(114)];
		EVEDBDgmTypeAttribute* explosiveDamageAttribute = self.type.attributesDictionary[@(116)];
		EVEDBDgmTypeAttribute* kineticDamageAttribute = self.type.attributesDictionary[@(117)];
		EVEDBDgmTypeAttribute* thermalDamageAttribute = self.type.attributesDictionary[@(118)];
		EVEDBDgmTypeAttribute* damageMultiplierAttribute = self.type.attributesDictionary[@(64)];
		EVEDBDgmTypeAttribute* missileDamageMultiplierAttribute = self.type.attributesDictionary[@(212)];
		EVEDBDgmTypeAttribute* missileTypeIDAttribute = self.type.attributesDictionary[@(507)];
		EVEDBDgmTypeAttribute* missileVelocityMultiplierAttribute = self.type.attributesDictionary[@(645)];
		EVEDBDgmTypeAttribute* missileFlightTimeMultiplierAttribute = self.type.attributesDictionary[@(646)];
		
		EVEDBDgmTypeAttribute* armorEmDamageResonanceAttribute = self.type.attributesDictionary[@(267)];
		EVEDBDgmTypeAttribute* armorExplosiveDamageResonanceAttribute = self.type.attributesDictionary[@(268)];
		EVEDBDgmTypeAttribute* armorKineticDamageResonanceAttribute = self.type.attributesDictionary[@(269)];
		EVEDBDgmTypeAttribute* armorThermalDamageResonanceAttribute = self.type.attributesDictionary[@(270)];

		EVEDBDgmTypeAttribute* shieldEmDamageResonanceAttribute = self.type.attributesDictionary[@(271)];
		EVEDBDgmTypeAttribute* shieldExplosiveDamageResonanceAttribute = self.type.attributesDictionary[@(272)];
		EVEDBDgmTypeAttribute* shieldKineticDamageResonanceAttribute = self.type.attributesDictionary[@(273)];
		EVEDBDgmTypeAttribute* shieldThermalDamageResonanceAttribute = self.type.attributesDictionary[@(274)];

		EVEDBDgmTypeAttribute* structureEmDamageResonanceAttribute = self.type.attributesDictionary[@(113)];
		EVEDBDgmTypeAttribute* structureExplosiveDamageResonanceAttribute = self.type.attributesDictionary[@(111)];
		EVEDBDgmTypeAttribute* structureKineticDamageResonanceAttribute = self.type.attributesDictionary[@(109)];
		EVEDBDgmTypeAttribute* structureThermalDamageResonanceAttribute = self.type.attributesDictionary[@(110)];

		EVEDBDgmTypeAttribute* armorHPAttribute = self.type.attributesDictionary[@(265)];
		EVEDBDgmTypeAttribute* hpAttribute = self.type.attributesDictionary[@(9)];
		EVEDBDgmTypeAttribute* shieldCapacityAttribute = self.type.attributesDictionary[@(263)];
		EVEDBDgmTypeAttribute* shieldRechargeRate = self.type.attributesDictionary[@(479)];

		EVEDBDgmTypeAttribute* optimalAttribute = self.type.attributesDictionary[@(54)];
		EVEDBDgmTypeAttribute* falloffAttribute = self.type.attributesDictionary[@(158)];
		EVEDBDgmTypeAttribute* trackingSpeedAttribute = self.type.attributesDictionary[@(160)];

		EVEDBDgmTypeAttribute* turretFireSpeedAttribute = self.type.attributesDictionary[@(51)];
		EVEDBDgmTypeAttribute* missileLaunchDurationAttribute = self.type.attributesDictionary[@(506)];
		

		//NPC Info
		{
			NSMutableArray* rows = [[NSMutableArray alloc] init];
			
			EVEDBDgmTypeAttribute* bountyAttribute = self.type.attributesDictionary[@(481)];
			if (bountyAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = bountyAttribute.attribute.displayName;
				cellData.icon = bountyAttribute.attribute.icon.iconImageName;
				cellData.value = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(bountyAttribute.value)]];
				[rows addObject:cellData];
			}
			
			EVEDBDgmTypeAttribute* securityStatusBonusAttribute = self.type.attributesDictionary[@(252)];
			if (securityStatusBonusAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Security Increase", nil);
				cellData.icon = securityStatusBonusAttribute.attribute.icon.iconImageName;
				cellData.value = [NSString stringWithFormat:@"%f", securityStatusBonusAttribute.value];
				[rows addObject:cellData];
			}
			
			
			EVEDBDgmTypeAttribute* factionLossAttribute = self.type.attributesDictionary[@(562)];
			if (factionLossAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Faction Stading Loss", nil);
				cellData.icon = factionLossAttribute.attribute.icon.iconImageName;
				cellData.value = [NSString stringWithFormat:@"%f", factionLossAttribute.value];
				[rows addObject:cellData];
			}
			
			if (rows.count > 0)
				[self.sections addObject:@{@"title" : NSLocalizedString(@"NPC Info", nil), @"rows" : rows}];
		}

		
		//Turrets damage

		float emDamageTurret = 0;
		float explosiveDamageTurret = 0;
		float kineticDamageTurret = 0;
		float thermalDamageTurret = 0;
		float intervalTurret = 0;
		float totalDamageTurret = 0;

		if (self.type.effectsDictionary[@(10)] || self.type.effectsDictionary[@(1086)]) {
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
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = titles[i];
				cellData.icon = icons[i];
				cellData.value = values[i];
				[rows addObject:cellData];
			}
			[self.sections addObject:@{@"title" : NSLocalizedString(@"Turrets Damage", nil), @"rows" : rows}];
		}
		
		//Missiles damage
		float emDamageMissile = 0;
		float explosiveDamageMissile = 0;
		float kineticDamageMissile = 0;
		float thermalDamageMissile = 0;
		float intervalMissile = 0;
		float totalDamageMissile = 0;

		if (self.type.effectsDictionary[@(569)]) {
			EVEDBInvType* missile = [EVEDBInvType invTypeWithTypeID:(NSInteger)[missileTypeIDAttribute value] error:nil];
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
				
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Missile Type", nil);
				cellData.value = missile.typeName;
				cellData.icon = [missile typeSmallImageName];
				cellData.selector = @selector(onTypeInfo:);
				cellData.object = missile;
				[rows addObject:cellData];
				
				for (int i = 0; i < 7; i++) {
					ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
					cellData.title = titles[i];
					cellData.icon = icons[i];
					cellData.value = values[i];
					[rows addObject:cellData];
				}
				[self.sections addObject:@{@"title" : NSLocalizedString(@"Missiles Damage", nil), @"rows" : rows}];
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
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = titles[i];
				cellData.icon = icons[i];
				cellData.value = values[i];
				[rows addObject:cellData];
			}
			[self.sections addObject:@{@"title" : NSLocalizedString(@"Total Damage", nil), @"rows" : rows}];
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
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = titles[i];
				cellData.value = values[i];
				cellData.icon = icons[i];
				[rows addObject:cellData];
			}
			
			if (self.type.effectsDictionary[@(2192)] || self.type.effectsDictionary[@(2193)] || self.type.effectsDictionary[@(2194)] || self.type.effectsDictionary[@(876)]) {
				EVEDBDgmTypeAttribute* shieldBoostAmountAttribute = self.type.attributesDictionary[@(637)];
				EVEDBDgmTypeAttribute* shieldBoostDurationAttribute = self.type.attributesDictionary[@(636)];
				EVEDBDgmTypeAttribute* shieldBoostDelayChanceAttribute = self.type.attributesDictionary[@(639)];
				
				if (!shieldBoostDelayChanceAttribute)
					shieldBoostDelayChanceAttribute = self.type.attributesDictionary[@(1006)];
				if (!shieldBoostDelayChanceAttribute)
					shieldBoostDelayChanceAttribute = self.type.attributesDictionary[@(1007)];
				if (!shieldBoostDelayChanceAttribute)
					shieldBoostDelayChanceAttribute = self.type.attributesDictionary[@(1008)];
				
				float shieldBoostAmount = shieldBoostAmountAttribute.value;
				float shieldBoostDuration = shieldBoostDurationAttribute.value;
				float shieldBoostDelayChance = shieldBoostDelayChanceAttribute.value;
				float repairRate = shieldBoostDuration > 0 ? shieldBoostAmount * shieldBoostDelayChance / (shieldBoostDuration / 1000.0) : 0;
				
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Repair Rate", nil);
				cellData.value = [NSString stringWithFormat:@"%.2f HP/s", repairRate + passiveRechargeRate];
				cellData.icon = @"shieldBooster.png";
				[rows addObject:cellData];
			}
			[self.sections addObject:@{@"title" : NSLocalizedString(@"Shield", nil), @"rows" : rows}];
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
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = titles[i];
				cellData.value = values[i];
				cellData.icon = icons[i];
				[rows addObject:cellData];
			}
			
			if (self.type.effectsDictionary[@(2195)] || self.type.effectsDictionary[@(2196)] || self.type.effectsDictionary[@(2197)] || self.type.effectsDictionary[@(878)]) {
				EVEDBDgmTypeAttribute* armorRepairAmountAttribute = self.type.attributesDictionary[@(631)];
				EVEDBDgmTypeAttribute* armorRepairDurationAttribute = self.type.attributesDictionary[@(630)];
				EVEDBDgmTypeAttribute* armorRepairDelayChanceAttribute = self.type.attributesDictionary[@(638)];
				
				if (!armorRepairDelayChanceAttribute)
					armorRepairDelayChanceAttribute = self.type.attributesDictionary[@(1009)];
				if (!armorRepairDelayChanceAttribute)
					armorRepairDelayChanceAttribute = self.type.attributesDictionary[@(1010)];
				if (!armorRepairDelayChanceAttribute)
					armorRepairDelayChanceAttribute = self.type.attributesDictionary[@(1011)];
				
				float armorRepairAmount = armorRepairAmountAttribute.value;
				float armorRepairDuration = armorRepairDurationAttribute.value;
				float armorRepairDelayChance = armorRepairDelayChanceAttribute.value;
				if (armorRepairDelayChance == 0)
					armorRepairDelayChance = 1.0;
				float repairRate = armorRepairDuration > 0 ? armorRepairAmount * armorRepairDelayChance / (armorRepairDuration / 1000.0) : 0;
				
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Repair Rate", nil);
				cellData.value = [NSString stringWithFormat:@"%.2f HP/s", repairRate];
				cellData.icon = @"armorRepairer.png";
				[rows addObject:cellData];
			}
			[self.sections addObject:@{@"title" : NSLocalizedString(@"Armor", nil), @"rows" : rows}];
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
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = titles[i];
				cellData.value = values[i];
				cellData.icon = icons[i];
				[rows addObject:cellData];
			}
			[self.sections addObject:@{@"title" : NSLocalizedString(@"Structure", nil), @"rows" : rows}];
		}
		
		//Targeting
		{
			NSMutableArray* rows = [[NSMutableArray alloc] init];
			
			EVEDBDgmTypeAttribute* attackRangeAttribute = self.type.attributesDictionary[@(247)];
			if (attackRangeAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Attack Range", nil);
				cellData.value = [NSString stringWithFormat:@"%@ m", [NSNumberFormatter neocomLocalizedStringFromInteger:attackRangeAttribute.value]];
				cellData.icon = attackRangeAttribute.attribute.icon.iconImageName;
				[rows addObject:cellData];
			}
			
			EVEDBDgmTypeAttribute* signatureRadiusAttribute = self.type.attributesDictionary[@(552)];
			if (signatureRadiusAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = signatureRadiusAttribute.attribute.displayName;
				cellData.value = [NSString stringWithFormat:@"%@ m", [NSNumberFormatter neocomLocalizedStringFromInteger:signatureRadiusAttribute.value]];
				cellData.icon = signatureRadiusAttribute.attribute.icon.iconImageName;
				[rows addObject:cellData];
			}

			
			EVEDBDgmTypeAttribute* scanResolutionAttribute = self.type.attributesDictionary[@(564)];
			if (scanResolutionAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = scanResolutionAttribute.attribute.displayName;
				cellData.value = [NSString stringWithFormat:@"%@ m", [NSNumberFormatter neocomLocalizedStringFromInteger:scanResolutionAttribute.value]];
				cellData.icon = scanResolutionAttribute.attribute.icon.iconImageName;
				[rows addObject:cellData];
			}

			EVEDBDgmTypeAttribute* sensorStrengthAttribute = self.type.attributesDictionary[@(208)];
			if (sensorStrengthAttribute.value == 0)
				sensorStrengthAttribute = self.type.attributesDictionary[@(209)];
			if (sensorStrengthAttribute.value == 0)
				sensorStrengthAttribute = self.type.attributesDictionary[@(210)];
			if (sensorStrengthAttribute.value == 0)
				sensorStrengthAttribute = self.type.attributesDictionary[@(211)];
			if (sensorStrengthAttribute.value > 0) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = sensorStrengthAttribute.attribute.displayName;
				cellData.value = [NSString stringWithFormat:@"%.0f", sensorStrengthAttribute.value];
				cellData.icon = sensorStrengthAttribute.attribute.icon.iconImageName;
				[rows addObject:cellData];
			}
			
			if (rows.count > 0)
				[self.sections addObject:@{@"title" : NSLocalizedString(@"Targeting", nil), @"rows" : rows}];
		}

		//Movement
		{
			NSMutableArray* rows = [[NSMutableArray alloc] init];
			
			EVEDBDgmTypeAttribute* maxVelocityAttribute = self.type.attributesDictionary[@(37)];
			if (maxVelocityAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = maxVelocityAttribute.attribute.displayName;
				cellData.value = [NSString stringWithFormat:NSLocalizedString(@"%@ m/s", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:maxVelocityAttribute.value]];
				cellData.icon = maxVelocityAttribute.attribute.icon.iconImageName;
				[rows addObject:cellData];
			}
			
			EVEDBDgmTypeAttribute* orbitVelocityAttribute = self.type.attributesDictionary[@(508)];
			if (orbitVelocityAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = orbitVelocityAttribute.attribute.displayName;
				cellData.value = [NSString stringWithFormat:NSLocalizedString(@"%@ m/s", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:orbitVelocityAttribute.value]];
				cellData.icon = @"Icons/icon22_13.png";
				[rows addObject:cellData];
			}
			
			
			EVEDBDgmTypeAttribute* entityFlyRangeAttribute = self.type.attributesDictionary[@(416)];
			if (entityFlyRangeAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Orbit Range", nil);
				cellData.value = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:entityFlyRangeAttribute.value]];
				cellData.icon = @"Icons/icon22_15.png";
				[rows addObject:cellData];
			}
			
			if (rows.count > 0)
				[self.sections addObject:@{@"title" : NSLocalizedString(@"Movement", nil), @"rows" : rows}];
		}
		
		//Stasis Webifying
		if (self.type.effectsDictionary[@(575)] || self.type.effectsDictionary[@(3714)]) {
			NSMutableArray* rows = [[NSMutableArray alloc] init];

			EVEDBDgmTypeAttribute* speedFactorAttribute = self.type.attributesDictionary[@(20)];
			if (speedFactorAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = speedFactorAttribute.attribute.displayName;
				cellData.value = [NSString stringWithFormat:@"%.0f %%", speedFactorAttribute.value];
				cellData.icon = speedFactorAttribute.attribute.icon.iconImageName;
				[rows addObject:cellData];
			}

			EVEDBDgmTypeAttribute* modifyTargetSpeedRangeAttribute = self.type.attributesDictionary[@(514)];
			if (modifyTargetSpeedRangeAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Range", nil);
				cellData.value = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:modifyTargetSpeedRangeAttribute.value]];
				cellData.icon = @"targetingRange.png";
				[rows addObject:cellData];
			}

			EVEDBDgmTypeAttribute* modifyTargetSpeedDurationAttribute = self.type.attributesDictionary[@(513)];
			if (modifyTargetSpeedDurationAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Duration", nil);
				cellData.value = [NSString stringWithFormat:NSLocalizedString(@"%.2f s", nil), modifyTargetSpeedDurationAttribute.value / 1000.0];
				cellData.icon = @"Icons/icon22_16.png";
				[rows addObject:cellData];
			}

			EVEDBDgmTypeAttribute* modifyTargetSpeedChanceAttribute = self.type.attributesDictionary[@(512)];
			if (modifyTargetSpeedChanceAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Webbing Chance", nil);
				cellData.value = [NSString stringWithFormat:@"%.0f %%", modifyTargetSpeedChanceAttribute.value * 100];
				cellData.icon = modifyTargetSpeedChanceAttribute.attribute.icon.iconImageName;
				[rows addObject:cellData];
			}

			if (rows.count > 0)
				[self.sections addObject:@{@"title" : NSLocalizedString(@"Stasis Webifying", nil), @"rows" : rows}];
		}
		
		//Warp Scramble
		if (self.type.effectsDictionary[@(39)] || self.type.effectsDictionary[@(563)] || self.type.effectsDictionary[@(3713)]) {
			NSMutableArray* rows = [[NSMutableArray alloc] init];
			
			EVEDBDgmTypeAttribute* warpScrambleStrengthAttribute = self.type.attributesDictionary[@(105)];
			if (warpScrambleStrengthAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = warpScrambleStrengthAttribute.attribute.displayName;
				cellData.value = [NSString stringWithFormat:@"%.0f", warpScrambleStrengthAttribute.value];
				cellData.icon = warpScrambleStrengthAttribute.attribute.icon.iconImageName;
				[rows addObject:cellData];
			}
			
			EVEDBDgmTypeAttribute* warpScrambleRangeAttribute = self.type.attributesDictionary[@(103)];
			if (warpScrambleRangeAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = warpScrambleRangeAttribute.attribute.displayName;
				cellData.value = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:warpScrambleRangeAttribute.value]];
				cellData.icon = warpScrambleRangeAttribute.attribute.icon.iconImageName;
				[rows addObject:cellData];
			}
			
			EVEDBDgmTypeAttribute* warpScrambleDurationAttribute = self.type.attributesDictionary[@(505)];
			if (warpScrambleDurationAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = warpScrambleDurationAttribute.attribute.displayName;
				cellData.value = [NSString stringWithFormat:NSLocalizedString(@"%.2f s", nil), warpScrambleDurationAttribute.value / 1000];
				cellData.icon = warpScrambleDurationAttribute.attribute.icon.iconImageName;
				[rows addObject:cellData];
			}
			
			EVEDBDgmTypeAttribute* warpScrambleChanceAttribute = self.type.attributesDictionary[@(504)];
			if (warpScrambleChanceAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Scrambling Chance", nil);
				cellData.value = [NSString stringWithFormat:@"%.0f %%", warpScrambleChanceAttribute.value * 100];
				cellData.icon = warpScrambleChanceAttribute.attribute.icon.iconImageName;
				[rows addObject:cellData];
			}
			
			if (rows.count > 0)
				[self.sections addObject:@{@"title" : NSLocalizedString(@"Warp Scramble", nil), @"rows" : rows}];
		}

		//Target Painting
		if (self.type.effectsDictionary[@(1879)]) {
			NSMutableArray* rows = [[NSMutableArray alloc] init];
			
			EVEDBDgmTypeAttribute* signatureRadiusBonusAttribute = self.type.attributesDictionary[@(554)];
			if (signatureRadiusBonusAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = signatureRadiusBonusAttribute.attribute.displayName;
				cellData.value = [NSString stringWithFormat:@"%.0f %%", signatureRadiusBonusAttribute.value];
				cellData.icon = signatureRadiusBonusAttribute.attribute.icon.iconImageName;
				[rows addObject:cellData];
			}
			
			EVEDBDgmTypeAttribute* targetPaintRangeAttribute = self.type.attributesDictionary[@(941)];
			if (targetPaintRangeAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Optimal Range", nil);
				cellData.value = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:targetPaintRangeAttribute.value]];
				cellData.icon = @"Icons/icon22_15.png";
				[rows addObject:cellData];
			}

			EVEDBDgmTypeAttribute* targetPaintFalloffAttribute = self.type.attributesDictionary[@(954)];
			if (targetPaintFalloffAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Accuracy Falloff", nil);
				cellData.value = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:targetPaintFalloffAttribute.value]];
				cellData.icon = @"Icons/icon22_23.png";
				[rows addObject:cellData];
			}

			EVEDBDgmTypeAttribute* targetPaintDurationAttribute = self.type.attributesDictionary[@(945)];
			if (targetPaintDurationAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Duration", nil);
				cellData.value = [NSString stringWithFormat:NSLocalizedString(@"%.2f s", nil), targetPaintDurationAttribute.value / 1000];
				cellData.icon = @"Icons/icon22_16.png";
				[rows addObject:cellData];
			}
			
			EVEDBDgmTypeAttribute* targetPaintChanceAttribute = self.type.attributesDictionary[@(935)];
			if (targetPaintChanceAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Chance", nil);
				cellData.value = [NSString stringWithFormat:@"%.0f %%", targetPaintChanceAttribute.value * 100];
				cellData.icon = targetPaintChanceAttribute.attribute.icon.iconImageName;
				[rows addObject:cellData];
			}
			
			if (rows.count > 0)
				[self.sections addObject:@{@"title" : NSLocalizedString(@"Target Painting", nil), @"rows" : rows}];
		}
		
		//Tracking Disruption
		if (self.type.effectsDictionary[@(1877)]) {
			NSMutableArray* rows = [[NSMutableArray alloc] init];
			
			EVEDBDgmTypeAttribute* trackingDisruptMultiplierAttribute = self.type.attributesDictionary[@(948)];
			if (trackingDisruptMultiplierAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Tracking Speed Bonus", nil);
				cellData.value = [NSString stringWithFormat:@"%.0f %%", (trackingDisruptMultiplierAttribute.value - 1) * 100];
				cellData.icon = @"Icons/icon22_22.png";
				[rows addObject:cellData];
			}
			
			EVEDBDgmTypeAttribute* trackingDisruptRangeAttribute = self.type.attributesDictionary[@(940)];
			if (trackingDisruptRangeAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Optimal Range", nil);
				cellData.value = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:trackingDisruptRangeAttribute.value]];
				cellData.icon = @"Icons/icon22_15.png";
				[rows addObject:cellData];
			}
			
			EVEDBDgmTypeAttribute* trackingDisruptFalloffAttribute = self.type.attributesDictionary[@(951)];
			if (trackingDisruptFalloffAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Accuracy Falloff", nil);
				cellData.value = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:trackingDisruptFalloffAttribute.value]];
				cellData.icon = @"Icons/icon22_23.png";
				[rows addObject:cellData];
			}
			
			EVEDBDgmTypeAttribute* trackingDisruptDurationAttribute = self.type.attributesDictionary[@(944)];
			if (trackingDisruptDurationAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Duration", nil);
				cellData.value = [NSString stringWithFormat:NSLocalizedString(@"%.2f s", nil), trackingDisruptDurationAttribute.value / 1000];
				cellData.icon = @"Icons/icon22_16.png";
				[rows addObject:cellData];
			}
			
			EVEDBDgmTypeAttribute* trackingDisruptChanceAttribute = self.type.attributesDictionary[@(933)];
			if (trackingDisruptChanceAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Chance", nil);
				cellData.value = [NSString stringWithFormat:@"%.0f %%", trackingDisruptChanceAttribute.value * 100];
				cellData.icon = trackingDisruptChanceAttribute.attribute.icon.iconImageName;
				[rows addObject:cellData];
			}
			
			if (rows.count > 0)
				[self.sections addObject:@{@"title" : NSLocalizedString(@"Tracking Disruption", nil), @"rows" : rows}];
		}
		
		//Sensor Dampening
		if (self.type.effectsDictionary[@(1878)]) {
			NSMutableArray* rows = [[NSMutableArray alloc] init];
			
			EVEDBDgmTypeAttribute* maxTargetRangeMultiplierAttribute = self.type.attributesDictionary[@(237)];
			if (maxTargetRangeMultiplierAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Max Targeting Range Bonus", nil);
				cellData.value = [NSString stringWithFormat:@"%.0f %%", (maxTargetRangeMultiplierAttribute.value - 1) * 100];
				cellData.icon = maxTargetRangeMultiplierAttribute.attribute.icon.iconImageName;
				[rows addObject:cellData];
			}

			EVEDBDgmTypeAttribute* scanResolutionMultiplierAttribute = self.type.attributesDictionary[@(565)];
			if (scanResolutionMultiplierAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Scan Resolution Bonus", nil);
				cellData.value = [NSString stringWithFormat:@"%.0f %%", (scanResolutionMultiplierAttribute.value - 1) * 100];
				cellData.icon = scanResolutionMultiplierAttribute.attribute.icon.iconImageName;
				[rows addObject:cellData];
			}

			EVEDBDgmTypeAttribute* sensorDampenRangeAttribute = self.type.attributesDictionary[@(938)];
			if (sensorDampenRangeAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Optimal Range", nil);
				cellData.value = [NSString stringWithFormat:@"%@ m", [NSNumberFormatter neocomLocalizedStringFromInteger:sensorDampenRangeAttribute.value]];
				cellData.icon = @"Icons/icon22_15.png";
				[rows addObject:cellData];
			}
			
			EVEDBDgmTypeAttribute* sensorDampenFalloffAttribute = self.type.attributesDictionary[@(950)];
			if (sensorDampenFalloffAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Accuracy Falloff", nil);
				cellData.value = [NSString stringWithFormat:@"%@ m", [NSNumberFormatter neocomLocalizedStringFromInteger:sensorDampenFalloffAttribute.value]];
				cellData.icon = @"Icons/icon22_23.png";
				[rows addObject:cellData];
			}
			
			EVEDBDgmTypeAttribute* sensorDampenDurationAttribute = self.type.attributesDictionary[@(943)];
			if (sensorDampenDurationAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Duration", nil);
				cellData.value = [NSString stringWithFormat:NSLocalizedString(@"%.2f s", nil), sensorDampenDurationAttribute.value / 1000];
				cellData.icon = @"Icons/icon22_16.png";
				[rows addObject:cellData];
			}
			
			EVEDBDgmTypeAttribute* sensorDampenChanceAttribute = self.type.attributesDictionary[@(932)];
			if (sensorDampenChanceAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Chance", nil);
				cellData.value = [NSString stringWithFormat:@"%.0f %%", sensorDampenChanceAttribute.value * 100];
				cellData.icon = sensorDampenChanceAttribute.attribute.icon.iconImageName;
				[rows addObject:cellData];
			}
			
			if (rows.count > 0)
				[self.sections addObject:@{@"title" : NSLocalizedString(@"Sensor Dampening", nil), @"rows" : rows}];
		}
		
		//ECM Jamming
		if (self.type.effectsDictionary[@(1871)] || self.type.effectsDictionary[@(1752)] || self.type.effectsDictionary[@(3710)] || self.type.effectsDictionary[@(4656)]) {
			NSMutableArray* rows = [[NSMutableArray alloc] init];
			
			EVEDBDgmTypeAttribute* scanGravimetricStrengthBonusAttribute = self.type.attributesDictionary[@(238)];
			if (scanGravimetricStrengthBonusAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = scanGravimetricStrengthBonusAttribute.attribute.displayName;
				cellData.value = [NSString stringWithFormat:@"%.2f", scanGravimetricStrengthBonusAttribute.value];
				cellData.icon = scanGravimetricStrengthBonusAttribute.attribute.icon.iconImageName;
				[rows addObject:cellData];
			}
			
			EVEDBDgmTypeAttribute* scanLadarStrengthBonusAttribute = self.type.attributesDictionary[@(239)];
			if (scanLadarStrengthBonusAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = scanLadarStrengthBonusAttribute.attribute.displayName;
				cellData.value = [NSString stringWithFormat:@"%.2f", scanLadarStrengthBonusAttribute.value];
				cellData.icon = scanLadarStrengthBonusAttribute.attribute.icon.iconImageName;
				[rows addObject:cellData];
			}

			EVEDBDgmTypeAttribute* scanMagnetometricStrengthBonusAttribute = self.type.attributesDictionary[@(240)];
			if (scanMagnetometricStrengthBonusAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = scanMagnetometricStrengthBonusAttribute.attribute.displayName;
				cellData.value = [NSString stringWithFormat:@"%.2f", scanMagnetometricStrengthBonusAttribute.value];
				cellData.icon = scanMagnetometricStrengthBonusAttribute.attribute.icon.iconImageName;
				[rows addObject:cellData];
			}

			EVEDBDgmTypeAttribute* scanRadarStrengthBonusAttribute = self.type.attributesDictionary[@(241)];
			if (scanLadarStrengthBonusAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = scanRadarStrengthBonusAttribute.attribute.displayName;
				cellData.value = [NSString stringWithFormat:@"%.2f", scanRadarStrengthBonusAttribute.value];
				cellData.icon = scanRadarStrengthBonusAttribute.attribute.icon.iconImageName;
				[rows addObject:cellData];
			}

			EVEDBDgmTypeAttribute* targetJamRangeAttribute = self.type.attributesDictionary[@(936)];
			if (targetJamRangeAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Optimal Range", nil);
				cellData.value = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:targetJamRangeAttribute.value]];
				cellData.icon = @"Icons/icon22_15.png";
				[rows addObject:cellData];
			}
			
			EVEDBDgmTypeAttribute* targetJamFalloffAttribute = self.type.attributesDictionary[@(953)];
			if (targetJamFalloffAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Accuracy Falloff", nil);
				cellData.value = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:targetJamFalloffAttribute.value]];
				cellData.icon = @"Icons/icon22_23.png";
				[rows addObject:cellData];
			}
			
			EVEDBDgmTypeAttribute* targetJamDurationAttribute = self.type.attributesDictionary[@(929)];
			if (targetJamDurationAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Duration", nil);
				cellData.value = [NSString stringWithFormat:NSLocalizedString(@"%.2f s", nil), targetJamDurationAttribute.value / 1000];
				cellData.icon = @"Icons/icon22_16.png";
				[rows addObject:cellData];
			}
			
			EVEDBDgmTypeAttribute* targetJamChanceAttribute = self.type.attributesDictionary[@(930)];
			if (targetJamChanceAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Chance", nil);
				cellData.value = [NSString stringWithFormat:@"%.0f %%", targetJamChanceAttribute.value * 100];
				cellData.icon = targetJamChanceAttribute.attribute.icon.iconImageName;
				[rows addObject:cellData];
			}
			
			if (rows.count > 0)
				[self.sections addObject:@{@"title" : NSLocalizedString(@"ECM Jamming", nil), @"rows" : rows}];
		}

		//Energy Vampire
		if (self.type.effectsDictionary[@(1872)]) {
			NSMutableArray* rows = [[NSMutableArray alloc] init];
			
			EVEDBDgmTypeAttribute* capacitorDrainAmountAttribute = self.type.attributesDictionary[@(946)];
			if (!capacitorDrainAmountAttribute)
				capacitorDrainAmountAttribute = self.type.attributesDictionary[@(90)];
			
			EVEDBDgmTypeAttribute* capacitorDrainDurationAttribute = self.type.attributesDictionary[@(942)];
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
				
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Amount", nil);
				cellData.value = value;
				cellData.icon = @"Icons/icon22_08.png";
				[rows addObject:cellData];
			}
			
			EVEDBDgmTypeAttribute* capacitorDrainRangeAttribute = self.type.attributesDictionary[@(937)];
			if (capacitorDrainRangeAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Optimal Range", nil);
				cellData.value = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:capacitorDrainRangeAttribute.value]];
				cellData.icon = @"Icons/icon22_15.png";
				[rows addObject:cellData];
			}
			
			if (capacitorDrainDurationAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Duration", nil);
				cellData.value = [NSString stringWithFormat:NSLocalizedString(@"%.2f s", nil), capacitorDrainDurationAttribute.value / 1000];
				cellData.icon = @"Icons/icon22_16.png";
				[rows addObject:cellData];
			}
			
			EVEDBDgmTypeAttribute* capacitorDrainChanceAttribute = self.type.attributesDictionary[@(931)];
			if (capacitorDrainChanceAttribute) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Chance", nil);
				cellData.value = [NSString stringWithFormat:@"%.0f %%", capacitorDrainChanceAttribute.value * 100];
				cellData.icon = capacitorDrainChanceAttribute.attribute.icon.iconImageName;
				[rows addObject:cellData];
			}
			
			if (rows.count > 0)
				[self.sections addObject:@{@"title" : NSLocalizedString(@"Energy Vampire", nil), @"rows" : rows}];
		}
		
		[self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
	}];
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) loadBlueprintAttributes {
	EUOperation* operation = [EUOperation operationWithIdentifier:@"ItemInfoViewController+load" name:@"Loading Attributes"];
	[operation addExecutionBlock:^{
		EVEAccount *account = [EVEAccount currentAccount];
		[account updateSkillpoints];
		
		NSMutableArray *rows = [NSMutableArray array];
		ItemInfoCellData* cellData;
		
		EVEDBInvType* productType = self.type.blueprintType.productType;
		
		cellData = [[ItemInfoCellData alloc] init];
		cellData.title = NSLocalizedString(@"Product", nil);
		cellData.value = productType.typeName;
		cellData.icon = productType.typeSmallImageName;
		cellData.selector = @selector(onTypeInfo:);
		cellData.object = productType;
		[rows addObject:cellData];
		
		cellData = [[ItemInfoCellData alloc] init];
		cellData.title = NSLocalizedString(@"Waste Factor", nil);
		cellData.value = [NSString stringWithFormat:@"%d %%", self.type.blueprintType.wasteFactor];
		[rows addObject:cellData];
		
		cellData = [[ItemInfoCellData alloc] init];
		cellData.title = NSLocalizedString(@"Production Limit", nil);
		cellData.value = [NSNumberFormatter neocomLocalizedStringFromInteger:self.type.blueprintType.maxProductionLimit];
		[rows addObject:cellData];
		
		cellData = [[ItemInfoCellData alloc] init];
		cellData.title = NSLocalizedString(@"Productivity Modifier", nil);
		cellData.value = [NSNumberFormatter neocomLocalizedStringFromInteger:self.type.blueprintType.productivityModifier];
		[rows addObject:cellData];

		cellData = [[ItemInfoCellData alloc] init];
		cellData.title = NSLocalizedString(@"Manufacturing Time", nil);
		cellData.value = [NSString stringWithTimeLeft:self.type.blueprintType.productionTime];
		[rows addObject:cellData];

		cellData = [[ItemInfoCellData alloc] init];
		cellData.title = NSLocalizedString(@"Research Manufacturing Time", nil);
		cellData.value = [NSString stringWithTimeLeft:self.type.blueprintType.researchProductivityTime];
		[rows addObject:cellData];
		
		cellData = [[ItemInfoCellData alloc] init];
		cellData.title = NSLocalizedString(@"Research Material Time", nil);
		cellData.value = [NSString stringWithTimeLeft:self.type.blueprintType.researchMaterialTime];
		[rows addObject:cellData];
		
		cellData = [[ItemInfoCellData alloc] init];
		cellData.title = NSLocalizedString(@"Research Copy Time", nil);
		cellData.value = [NSString stringWithTimeLeft:self.type.blueprintType.researchCopyTime];
		[rows addObject:cellData];

		
		cellData = [[ItemInfoCellData alloc] init];
		cellData.title = NSLocalizedString(@"Research Tech Time", nil);
		cellData.value = [NSString stringWithTimeLeft:self.type.blueprintType.researchTechTime];
		[rows addObject:cellData];
		
		[self.sections addObject:@{@"title" : NSLocalizedString(@"Blueprint", nil), @"rows" : rows}];


		
		for (EVEDBInvTypeAttributeCategory *category in self.type.attributeCategories) {
			NSString* title = nil;
			NSMutableArray *rows = [NSMutableArray array];
			
			if (category.categoryID == 8 && self.trainingTime > 0)
				title = [NSString stringWithFormat:@"%@ (%@)", category.categoryName, [NSString stringWithTimeLeft:self.trainingTime]];
			else
				title = category.categoryID == 9 ? @"Other" : category.categoryName;
			
			for (EVEDBDgmTypeAttribute *attribute in category.publishedAttributes) {
				NSString *unit = attribute.attribute.unit.displayName;

				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = attribute.attribute.displayName;
				cellData.value = [NSString stringWithFormat:@"%@ %@", [NSNumberFormatter neocomLocalizedStringFromNumber:@(attribute.value)], unit ? unit : @""];
				cellData.icon = attribute.attribute.icon.iconImageName;
				[rows addObject:cellData];
			}
			if (rows.count > 0)
				[self.sections addObject:@{@"title" : title, @"rows" : rows}];
		}
		
		NSArray* activities = [[self.type.blueprintType activities] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"activityID" ascending:YES]]];
		for (EVEDBRamActivity* activity in activities) {
			NSArray* requiredSkills = [self.type.blueprintType requiredSkillsForActivity:activity.activityID];
			TrainingQueue* requiredSkillsQueue = [TrainingQueue trainingQueueWithRequiredSkills:requiredSkills];
			NSTimeInterval queueTrainingTime = [requiredSkillsQueue trainingTime];
			
			NSMutableArray *rows = [NSMutableArray array];
			NSString* title = nil;
			
			if (queueTrainingTime > 0)
				title = [NSString stringWithFormat:NSLocalizedString(@"%@ - Skills (%@)", nil), activity.activityName, [NSString stringWithTimeLeft:queueTrainingTime]];
			else
				title = [NSString stringWithFormat:NSLocalizedString(@"%@ - Skills", nil), activity.activityName];

												   
			if (requiredSkillsQueue.skills.count && account && account.skillPlan) {
				ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
				cellData.title = NSLocalizedString(@"Add required skills to training plan", nil);
				cellData.value = [NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:requiredSkillsQueue.trainingTime]];
				cellData.icon = @"Icons/icon50_13.png";
				cellData.selector = @selector(onTrain:);
				cellData.object = requiredSkillsQueue;
				[rows addObject:cellData];
			}


			for (EVEDBInvTypeRequiredSkill* skill in requiredSkills) {
				SkillTree *skillTree = [SkillTree skillTreeWithRootSkill:skill skillLevel:skill.requiredLevel];
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
			}
			if (rows.count > 0)
				[self.sections addObject:@{@"title" : title, @"rows" : rows}];

			rows = [NSMutableArray array];

			for (id requirement in [self.type.blueprintType requiredMaterialsForActivity:activity.activityID]) {
				if ([requirement isKindOfClass:[EVEDBRamTypeRequirement class]]) {
					ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
					cellData.title = [requirement requiredType].typeName;
					cellData.value = [NSNumberFormatter neocomLocalizedStringFromInteger:[requirement quantity]];
					cellData.icon = [[requirement requiredType] typeSmallImageName];
					cellData.selector = @selector(onTypeInfo:);
					cellData.object = [requirement requiredType];
					[rows addObject:cellData];
				}
				else {
					EVEDBInvTypeMaterial* material = requirement;
					float waste = self.type.blueprintType.wasteFactor / 100.0;
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
					
					ItemInfoCellData* cellData = [[ItemInfoCellData alloc] init];
					cellData.title = material.materialType.typeName;
					cellData.value = value;
					cellData.icon = [material.materialType typeSmallImageName];
					cellData.selector = @selector(onTypeInfo:);
					cellData.object = material.materialType;
					[rows addObject:cellData];
				}
			}

			if (rows.count > 0)
				[self.sections addObject:@{@"title" : [NSString stringWithFormat:NSLocalizedString(@"%@ - Material / Mineral", nil), activity.activityName], @"rows" : rows}];
		}
		
		[self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
	}];
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) onTypeInfo:(EVEDBInvType*) type {
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	controller.type = type;
	[controller setActivePage:ItemViewControllerActivePageInfo];
	[self.navigationController pushViewController:controller animated:YES];
}

- (void) onGroupInfo:(EVEDBInvGroup*) group {
	ItemsDBViewController *controller = [[ItemsDBViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"ItemsDBViewControllerModal" : @"ItemsDBViewController")
																				bundle:nil];
	controller.modalMode = YES;
	controller.group = group;
	controller.category = controller.group.category;
	[self.navigationController pushViewController:controller animated:YES];
}

- (void) onTrain:(TrainingQueue*) trainingQueue {
	[[UIAlertView alertViewWithTitle:NSLocalizedString(@"Add to skill plan?", nil)
							 message:[NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:trainingQueue.trainingTime]]
				   cancelButtonTitle:NSLocalizedString(@"No", nil)
				   otherButtonTitles:@[NSLocalizedString(@"Yes", nil)]
					 completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
						 if (selectedButtonIndex != alertView.cancelButtonIndex) {
							 SkillPlan* skillPlan = [[EVEAccount currentAccount] skillPlan];
							 for (EVEDBInvTypeRequiredSkill* skill in trainingQueue.skills)
								 [skillPlan addSkill:skill];
							 [skillPlan save];
						 }
					 }
						 cancelBlock:nil] show];
}

- (void) onVariations:(EVEDBInvType*) type {
	VariationsViewController* controller = [[VariationsViewController alloc] initWithNibName:@"VariationsViewController" bundle:nil];
	controller.type = type;
	[self.navigationController pushViewController:controller animated:YES];
}

@end
