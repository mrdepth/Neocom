//
//  NCDatabaseTypeInfoViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 15.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseTypeInfoViewController.h"
#import "NCDatabase.h"
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
#import "UIColor+Neocom.h"
#import "NSArray+Neocom.h"
#import "NCDatabaseTypeRequirementsViewController.h"
#import "NCPriceManager.h"
#import "NCShoppingList.h"
#import "NCShoppingItem+Neocom.h"
#import "NCShoppingGroup+Neocom.h"
#import "NCNewShoppingItemViewController.h"
#import "NCDatabaseFetchedResultsViewController.h"

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
@property (nonatomic, strong) NCDBEveIcon* icon;
@property (nonatomic, strong) NCDBEveIcon* accessoryIcon;
@property (nonatomic, strong) UIImage* image;
@property (nonatomic, strong) id object;
@property (nonatomic, strong) NSString* cellIdentifier;
@property (nonatomic, assign) NSInteger indentationLevel;

@end

@interface NCDatabaseTypeInfoViewController ()
@property (nonatomic, strong) NSArray* sections;
@property (nonatomic, assign) BOOL needsLayout;
@property (nonatomic, strong) NCDBEveIcon* defaultAttributeIcon;
@property (nonatomic, strong) NCDBEveIcon* defaultIcon;
- (void) reload;
- (void) loadItemAttributes;
- (void) loadBlueprintAttributes;
- (void) loadNPCAttributes;
- (void) loadWHAttributes;
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
	self.tableView.tableHeaderView.backgroundColor = [UIColor appearanceTableViewBackgroundColor];
	if (self.navigationController.viewControllers[0] != self)
		self.navigationItem.leftBarButtonItem = nil;
	self.title = self.type.typeName;
	[self reload];
	self.refreshControl = nil;
	if (self.type.marketGroup.marketGroupID == 0)
		self.navigationItem.rightBarButtonItem = nil;
	self.defaultAttributeIcon = [NCDBEveIcon eveIconWithIconFile:@"105_32"];
	self.defaultIcon = [NCDBEveIcon defaultTypeIcon];
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
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	NSIndexPath* indexPath;
	NCDatabaseTypeInfoViewControllerRow* row;
	if ([sender isKindOfClass:[UITableViewCell class]]) {
		indexPath = [self.tableView indexPathForCell:sender];
		row = self.sections[indexPath.section][@"rows"][indexPath.row];
	}
	
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
		if ([row.object isKindOfClass:[NCDBInvGroup class]])
			destinationViewController.group = row.object;
		else if ([row.object isKindOfClass:[NCDBInvCategory class]])
			destinationViewController.category = row.object;
	}
	else if ([segue.identifier isEqualToString:@"NCDatabaseTypeVariationsViewController"]) {
		NCDatabaseTypeVariationsViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.type = self.type.parentType ? self.type.parentType : self.type;
	}
	else if ([segue.identifier isEqualToString:@"NCDatabaseTypeMarketInfoViewController"]) {
		NCDatabaseTypeMarketInfoViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.type = self.type;
		destinationViewController.navigationItem.rightBarButtonItem = nil;
	}
	else if ([segue.identifier isEqualToString:@"NCDatabaseTypeMasteryViewController"]) {
		NCDatabaseTypeMasteryViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.type = self.type;
		destinationViewController.masteryLevel = row.object;
	}
	else if ([segue.identifier isEqualToString:@"NCDatabaseTypeRequirementsViewController"]) {
		NCDatabaseTypeRequirementsViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.type = self.type;
	}
	else if ([segue.identifier isEqualToString:@"NCNewShoppingItemViewController"]) {
		NCNewShoppingItemViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		controller.shoppingGroup = sender;
	}
	else if ([segue.identifier isEqualToString:@"NCDatabaseFetchedResultsViewController"]) {
		NCDatabaseFetchedResultsViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		controller.result = row.object;
		controller.title = row.title;
	}
}

- (IBAction) unwindFromNewShoppingItem:(UIStoryboardSegue*)segue {
	
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

- (NSString *)tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCDatabaseTypeInfoViewControllerRow* row = self.sections[indexPath.section][@"rows"][indexPath.row];
	NSString *cellIdentifier = row.cellIdentifier;
	if (!cellIdentifier)
		cellIdentifier = @"Cell";
	return cellIdentifier;
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell *)tableViewCell forRowAtIndexPath:(NSIndexPath *)indexPath {
	NCDatabaseTypeInfoViewControllerRow* row = self.sections[indexPath.section][@"rows"][indexPath.row];
	
	NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
	cell.titleLabel.text = row.title;
	cell.subtitleLabel.text = row.detail;
	if (row.image)
		cell.iconView.image = row.image;
	else if (row.icon)
		cell.iconView.image = row.icon.image.image;
	else
		cell.iconView.image = self.defaultAttributeIcon.image.image;
	
	cell.indentationLevel = row.indentationLevel;
	cell.indentationWidth = 16;
	
	cell.accessoryView = row.accessoryIcon.image.image ? [[UIImageView alloc] initWithImage:row.accessoryIcon.image.image] : nil;
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

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NCDatabaseTypeInfoViewControllerRow* row = self.sections[indexPath.section][@"rows"][indexPath.row];
	if ([row.object isKindOfClass:[NCTrainingQueue class]]) {
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
	else if ([row.object isKindOfClass:[NCShoppingList class]]) {
		NCShoppingGroup* shoppingGroup = [[NCShoppingGroup alloc] initWithEntity:[NSEntityDescription entityForName:@"ShoppingGroup" inManagedObjectContext:[[NCStorage sharedStorage] managedObjectContext]]
												  insertIntoManagedObjectContext:nil];
		NCDBInvMarketGroup* marketGroup;
		for (marketGroup = self.type.marketGroup; marketGroup.parentGroup; marketGroup = marketGroup.parentGroup);
		shoppingGroup.name = marketGroup.marketGroupName;
		shoppingGroup.immutable = NO;
		NCShoppingItem* shoppingItem = [NCShoppingItem shoppingItemWithType:self.type quantity:1];
		shoppingItem.shoppingGroup = shoppingGroup;
		shoppingGroup.iconFile = marketGroup.icon.iconFile;
		[shoppingGroup addShoppingItemsObject:shoppingItem];
		shoppingGroup.identifier = [shoppingGroup defaultIdentifier];
		
		[self performSegueWithIdentifier:@"NCNewShoppingItemViewController" sender:shoppingGroup];
	}
}

#pragma mark - Private

- (void) reload {
	NCDBInvType* type = self.type;

	NSMutableAttributedString* title = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %d", type.typeName, type.typeID]];
	NSRange typeIDRange = NSMakeRange(type.typeName.length + 1, title.length - type.typeName.length - 1);
	[title addAttributes:@{NSFontAttributeName: [self.titleLabel.font fontWithSize:self.titleLabel.font.pointSize * 0.6],
									  (__bridge NSString*) (kCTSuperscriptAttributeName): @(-1),
									  NSForegroundColorAttributeName: [UIColor lightTextColor]}
							  range:typeIDRange];
	
	self.titleLabel.attributedText = title;
	self.imageView.image = type.icon.image.image ? type.icon.image.image : self.defaultIcon.image.image;
	
	/*if (type.typeDescription.text.length > 0) {
		NSMutableAttributedString* descriptionAttributesString = [[NSMutableAttributedString alloc] initWithString:type.typeDescription.text
																								   attributes:@{NSFontAttributeName: self.descriptionLabel.font,
																												NSForegroundColorAttributeName: self.descriptionLabel.textColor}];
		
		
		
		NSRegularExpression* expression = [NSRegularExpression regularExpressionWithPattern:@"(<b>)([^<]*)(</b>)"
																					options:NSRegularExpressionCaseInsensitive
																					  error:nil];
		
		NSDictionary* boldAttributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:self.descriptionLabel.font.pointSize], NSForegroundColorAttributeName: [UIColor whiteColor]};
		[expression enumerateMatchesInString:type.typeDescription.text
									 options:0
									   range:NSMakeRange(0, type.typeDescription.text.length)
								  usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
									  if (result.numberOfRanges == 4) {
										  NSRange r = [result rangeAtIndex:2];
										  [descriptionAttributesString addAttributes:boldAttributes
																			   range:r];
									  }
								  }];
		
		expression = [NSRegularExpression regularExpressionWithPattern:@"(</?b>)"
															   options:NSRegularExpressionCaseInsensitive
																 error:nil];
		[expression replaceMatchesInString:descriptionAttributesString.mutableString options:0 range:NSMakeRange(0, descriptionAttributesString.length) withTemplate:@""];
		self.descriptionLabel.attributedText = descriptionAttributesString;
	}
	else
		self.descriptionLabel.text = nil;*/
	self.descriptionLabel.attributedText = type.typeDescription.text;

	
	
	self.needsLayout = YES;
	[self.view setNeedsLayout];
	
	if (type.group.category.categoryID == 9)
		[self loadBlueprintAttributes];
	else if (type.group.category.categoryID == 11)
		[self loadNPCAttributes];
	else if (type.group.groupID == 988)
		[self loadWHAttributes];
	else
		[self loadItemAttributes];
}

- (void) loadItemAttributes {
	NCAccount *account = [NCAccount currentAccount];
	NCCharacterAttributes* attributes = [account characterAttributes];
	if (!attributes)
		attributes = [NCCharacterAttributes defaultCharacterAttributes];
	
	NSMutableArray* sections = [NSMutableArray new];
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
									   title:NCTaskManagerDefaultTitle
									   block:^(NCTask *task) {
										   NCDatabase* database = [NCDatabase sharedDatabase];
										   [database.backgroundManagedObjectContext performBlockAndWait:^{
											   NCDBInvType* type = (NCDBInvType*) [database.backgroundManagedObjectContext objectWithID:self.type.objectID];
											   
											   NCTrainingQueue* trainingQueue = [[NCTrainingQueue alloc] initWithAccount:account];
											   [trainingQueue addRequiredSkillsForType:type];
											   
											   if (type.marketGroup) {
												   NSMutableDictionary *section = [NSMutableDictionary dictionary];
												   section[@"title"] = NSLocalizedString(@"Shopping List", nil);
												   NSMutableArray* rows = [NSMutableArray array];
												   section[@"rows"] = rows;
												   
												   NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
												   row.title = NSLocalizedString(@"Add to Shopping List", nil);
												   
												   NCTask* priceTask = [[self taskManager] addTaskWithIndentifier:nil
																											title:NCTaskManagerDefaultTitle
																											block:^(NCTask *task) {
																												NSDictionary* price = [[NCPriceManager sharedManager] pricesWithTypes:@[@(type.typeID)]];
																												EVECentralMarketStatType* marketStat = price[@(type.typeID)];
																												if (marketStat)
																													row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(marketStat.sell.percentile)]];
																											} completionHandler:^(NCTask *task) {
																												if ([self.tableView numberOfSections] > 0 && [self.tableView numberOfRowsInSection:0] > 0)
																													[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
																											}];
												   [priceTask addDependency:task];
												   
												   row.cellIdentifier = @"Cell";
												   row.image = [UIImage imageNamed:@"note.png"];
												   row.object = [NCShoppingList currentShoppingList];
												   [rows addObject:row];
												   [sections addObject:section];
											   }
											   
											   NSInteger count = type.parentType ? type.parentType.variations.count : type.variations.count;
											   if (count > 0) {
												   NSMutableDictionary *section = [NSMutableDictionary dictionary];
												   section[@"title"] = NSLocalizedString(@"Variations", nil);
												   NSMutableArray* rows = [NSMutableArray array];
												   section[@"rows"] = rows;
												   
												   NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
												   row.title = NSLocalizedString(@"Variations", nil);
												   row.detail = [NSString stringWithFormat:@"%d", (int32_t) count + 1];
												   row.icon = [NCDBEveIcon eveIconWithIconFile:@"09_07"];
												   row.cellIdentifier = @"VariationsCell";
												   [rows addObject:row];
												   [sections addObject:section];
											   }
											   
											   if (account && account.activeSkillPlan) {
												   NSMutableDictionary *section = [NSMutableDictionary dictionary];
												   section[@"title"] = NSLocalizedString(@"Skill Plan", nil);
												   NSMutableArray* rows = [NSMutableArray array];
												   section[@"rows"] = rows;
												   
												   if (type.group.category.categoryID == 16) {
													   EVECharacterSheetSkill* characterSkill = account.characterSheet.skillsMap[@(type.typeID)];
													   for (int32_t level = characterSkill.level + 1; level <= 5; level++) {
														   NCTrainingQueue* trainingQueue = [[NCTrainingQueue alloc] initWithAccount:account];
														   [trainingQueue addSkill:type withLevel:level];
														   
														   NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
														   row.title = [NSString stringWithFormat:NSLocalizedString(@"Train to level %d", nil), level];
														   row.detail = [NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:trainingQueue.trainingTime]];
														   row.icon = [NCDBEveIcon eveIconWithIconFile:@"50_13"];
														   row.object = trainingQueue;
														   
														   [rows addObject:row];
													   }
												   }
												   else if (trainingQueue.skills.count > 0){
													   NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													   row.title = NSLocalizedString(@"Add required skills to training plan", nil);
													   row.detail = [NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:trainingQueue.trainingTime]];
													   row.icon = [NCDBEveIcon eveIconWithIconFile:@"50_13"];
													   row.object = trainingQueue;
													   [rows addObject:row];
												   }
												   if (rows.count > 0)
													   [sections addObject:section];
											   }
											   
											   if (type.certificates.count > 0) {
												   NSMutableDictionary *section = [NSMutableDictionary dictionary];
												   
												   section[@"title"] = NSLocalizedString(@"Mastery", nil);
												   NSMutableArray* rows = [NSMutableArray array];
												   section[@"rows"] = rows;
												   
												   NSMutableDictionary* masteries = [NSMutableDictionary new];
												   for (NCDBCertCertificate* certificate in type.certificates) {
													   for (NCDBCertMastery* mastery in certificate.masteries) {
														   NSMutableArray* array = masteries[@(mastery.level.level)];
														   if (!array)
															   masteries[@(mastery.level.level)] = array = [NSMutableArray new];
														   [array addObject:mastery];
													   }
												   }
												   NCDBEveIcon* unlcaimedIcon = [NCDBEveIcon certificateUnclaimedIcon];
												   for (NSString* key in [[masteries allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
													   NSArray* array = masteries[key];
													   NCTrainingQueue* trainingQueue = [[NCTrainingQueue alloc] initWithAccount:account];
													   NCDBCertMasteryLevel* level = [(NCDBCertMastery*) array[0] level];
													   for (NCDBCertMastery* mastery in array)
														   [trainingQueue addMastery:mastery];
													   NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													   row.title = [NSString stringWithFormat:NSLocalizedString(@"Mastery %d", nil), [key intValue] + 1];
													   if (trainingQueue.trainingTime > 0) {
														   row.detail = [NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:trainingQueue.trainingTime]];
														   row.icon = unlcaimedIcon;
													   }
													   else
														   row.icon = level.icon;
													   row.cellIdentifier = @"MasteryCell";
													   row.object = level;
													   [rows addObject:row];
												   }
												   if (rows.count > 0)
													   [sections addObject:section];
											   }
											   
											   if (type.products) {
												   NSMutableDictionary *section = [NSMutableDictionary dictionary];
												   NSMutableArray *rows = [NSMutableArray array];
												   for (NCDBIndProduct* product in type.products) {
													   NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													   row.title = NSLocalizedString(@"Blueprint", nil);
													   row.detail = [product.activity.blueprintType.type typeName];
													   row.icon = product.activity.blueprintType.type.icon ? product.activity.blueprintType.type.icon : self.defaultIcon;
													   row.object = product.activity.blueprintType.type;
													   row.cellIdentifier = @"TypeCell";
													   [rows addObject:row];
												   }
												   if (rows.count > 0) {
													   section[@"title"] = NSLocalizedString(@"Manufacturing", nil);
													   section[@"rows"] = rows;
													   [sections addObject:section];
												   }
											   }
											   
											   NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"DgmTypeAttribute"];
											   request.predicate = [NSPredicate predicateWithFormat:@"type == %@ AND attributeType.published == TRUE", type];
											   request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"attributeType.attributeCategory.categoryName" ascending:YES],
																		   [NSSortDescriptor sortDescriptorWithKey:@"attributeType.displayName" ascending:YES]];
											   NSFetchedResultsController* controller = [[NSFetchedResultsController alloc] initWithFetchRequest:request
																															managedObjectContext:database.backgroundManagedObjectContext
																															  sectionNameKeyPath:@"attributeType.attributeCategory.categoryName"
																																	   cacheName:nil];
											   [controller performFetch:nil];
											   
											   for (id<NSFetchedResultsSectionInfo> sectionInfo in controller.sections) {
												   NSMutableDictionary *section = [NSMutableDictionary dictionary];
												   NSMutableArray *rows = [NSMutableArray array];
												   
												   NCDBDgmAttributeCategory* category = [[(NCDBDgmTypeAttribute*) sectionInfo.objects[0] attributeType] attributeCategory];
												   
												   if (category.categoryID == 8 && trainingQueue.trainingTime > 0) {
													   NSString *title = [NSString stringWithFormat:@"%@ (%@)", category.categoryName, [NSString stringWithTimeLeft:trainingQueue.trainingTime]];
													   section[@"title"] = title;
												   }
												   else
													   section[@"title"] = category.categoryID == 9 ? @"Other" : category.categoryName;
												   
												   section[@"rows"] = rows;
												   
												   NCDBEveIcon* skillIcon = [NCDBEveIcon eveIconWithIconFile:@"50_11"];
												   for (NCDBDgmTypeAttribute *attribute in sectionInfo.objects) {
													   if (attribute.attributeType.unit.unitID == EVEDBUnitIDTypeID) {
														   int32_t typeID = attribute.value;
														   for (NCDBInvTypeRequiredSkill* requiredSkill in type.requiredSkills) {
															   if (requiredSkill.skillType.typeID == typeID) {
																   NCSkillHierarchy* hierarchy = [[NCSkillHierarchy alloc] initWithSkill:requiredSkill account:account];
																   
																   for (NCSkillHierarchySkill* skill in hierarchy.skills) {
																	   NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
																	   row.title = [NSString stringWithFormat:@"%@ %d", skill.type.typeName, skill.targetLevel];
																	   row.object = skill.type;
																	   row.cellIdentifier = @"TypeCell";
																	   row.indentationLevel = skill.nestingLevel;
																	   row.icon = skillIcon;
																	   
																	   switch (skill.availability) {
																		   case NCSkillHierarchyAvailabilityLearned:
																			   row.accessoryIcon = [NCDBEveIcon eveIconWithIconFile:@"38_193"];
																			   break;
																		   case NCSkillHierarchyAvailabilityNotLearned:
																			   row.accessoryIcon = [NCDBEveIcon eveIconWithIconFile:@"38_194"];
																			   break;
																		   case NCSkillHierarchyAvailabilityLowLevel:
																			   row.accessoryIcon = [NCDBEveIcon eveIconWithIconFile:@"38_195"];
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
													   else {
														   if (attribute.attributeType.displayName.length == 0 && attribute.attributeType.attributeName.length == 0)
															   continue;
														   NSNumber* modifiedValue = self.attributes[@(attribute.attributeType.attributeID)];
														   float value = modifiedValue ? [modifiedValue floatValue] : attribute.value;
														   
														   NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
														   row.title = attribute.attributeType.displayName.length > 0 ? attribute.attributeType.displayName : attribute.attributeType.attributeName;
														   
														   if (attribute.attributeType.unit.unitID == EVEDBUnitIDAttributeID) {
															   NCDBDgmAttributeType *attributeType = [NCDBDgmAttributeType dgmAttributeTypeWithAttributeTypeID:attribute.value];
															   row.detail = attributeType.displayName;
															   row.icon = attributeType.icon;
															   [rows addObject:row];
														   }
														   else if (attribute.attributeType.unit.unitID == EVEDBUnitIDGroupID) {
															   NCDBInvGroup *group = [NCDBInvGroup invGroupWithGroupID:attribute.value];
															   row.detail = group.groupName;
															   row.icon = attribute.attributeType.icon ? attribute.attributeType.icon : group.icon;
															   row.object = group;
															   row.cellIdentifier = @"GroupCell";
															   [rows addObject:row];
														   }
														   else if (attribute.attributeType.unit.unitID == EVEDBUnitIDSizeClass) {
															   row.icon = attribute.attributeType.icon;
															   
															   int size = attribute.value;
															   if (size == 1)
																   row.detail = NSLocalizedString(@"Small", nil);
															   else if (size == 2)
																   row.detail = NSLocalizedString(@"Medium", nil);
															   else
																   row.detail = NSLocalizedString(@"Large", nil);
															   
															   [rows addObject:row];
														   }
														   else if (attribute.attributeType.unit.unitID == EVEDBUnitIDBoolean) {
															   row.icon = attribute.attributeType.icon;
															   row.detail = value == 0.0 ? NSLocalizedString(@"Yes", nil) : NSLocalizedString(@"No", nil);
															   [rows addObject:row];
														   }
														   else if (attribute.attributeType.unit.unitID == EVEDBUnitIDBonus) {
															   row.icon = attribute.attributeType.icon;
															   row.detail = [NSString stringWithFormat:@"+%@",
																			 [NSNumberFormatter neocomLocalizedStringFromNumber:@(value)]];
															   [rows addObject:row];
														   }
														   else {
															   row.icon = attribute.attributeType.icon;
															   
															   if (attribute.attributeType.attributeID == EVEDBAttributeIDSKillLevel) {
																   int32_t level = 0;
																   EVECharacterSheetSkill *skill = account.characterSheet.skillsMap[@(type.typeID)];
																   if (skill)
																	   level = skill.level;
																   row.detail = [NSString stringWithFormat:@"%d", level];
															   }
															   else {
																   NSString *unit;
																   
																   if (attribute.attributeType.attributeID == EVEDBAttributeIDBaseWarpSpeed) {
																	   value = [(NCDBDgmTypeAttribute*) type.attributesDictionary[@(EVEDBAttributeIDWarpSpeedMultiplier)] value];
																	   unit = NSLocalizedString(@"AU/sec", nil);
																   }
																   else if (attribute.attributeType.unit.unitID == EVEDBUnitIDInverseAbsolutePercentID || attribute.attributeType.unit.unitID == EVEDBUnitIDInversedModifierPercentID) {
																	   value = (1 - value) * 100;
																	   unit = attribute.attributeType.unit.displayName;
																   }
																   else if (attribute.attributeType.unit.unitID == EVEDBUnitIDModifierPercentID) {
																	   value = (value - 1) * 100;
																	   unit = attribute.attributeType.unit.displayName;
																   }
																   else if (attribute.attributeType.unit.unitID == EVEDBUnitIDAbsolutePercentID) {
																	   value = value * 100;
																	   unit = attribute.attributeType.unit.displayName;
																   }
																   else if (attribute.attributeType.unit.unitID == EVEDBUnitIDMillisecondsID) {
																	   value = value / 1000.0;
																	   unit = attribute.attributeType.unit.displayName;
																   }
																   else {
																	   value = value;
																	   unit = attribute.attributeType.unit.displayName;
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
												   NSInteger requiredForCount = type.requiredForSkill.count;
												   if (requiredForCount > 0) {
													   NSMutableDictionary *section = [NSMutableDictionary dictionary];
													   NSMutableArray *rows = [NSMutableArray array];
													   section[@"title"] = NSLocalizedString(@"Required for", nil);
													   section[@"rows"] = rows;
													   
													   NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													   row.title = [NSString stringWithFormat:NSLocalizedString(@"%ld items", nil), (long) requiredForCount];
													   row.icon = [NCDBEveIcon eveIconWithIconFile:@"09_07"];
													   row.cellIdentifier = @"RequirementsCell";
													   [rows addObject:row];
													   [sections addObject:section];
												   }
												   
												   NSMutableDictionary *section = [NSMutableDictionary dictionary];
												   NSMutableArray *rows = [NSMutableArray array];
												   section[@"title"] = NSLocalizedString(@"Training time", nil);
												   section[@"rows"] = rows;
												   
												   float startSP = 0;
												   float endSP;
												   NCSkillData* skillData = [[NCSkillData alloc] initWithInvType:type];
												   NCDBEveIcon* skillIcon = [NCDBEveIcon eveIconWithIconFile:@"50_13"];
												   for (int32_t i = 1; i <= 5; i++) {
													   endSP = [skillData skillPointsAtLevel:i];
													   NSTimeInterval needsTime = (endSP - startSP) / [attributes skillpointsPerSecondForSkill:type];
													   NSString *text = [NSString stringWithFormat:NSLocalizedString(@"SP: %@ (%@)", nil),
																		 [NSNumberFormatter neocomLocalizedStringFromInteger:endSP],
																		 [NSString stringWithTimeLeft:needsTime]];
													   
													   NSString* rank = [NSString stringWithFormat:NSLocalizedString(@"Level %d", nil), i];
													   
													   NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													   row.title = rank;
													   row.detail = text;
													   row.icon = skillIcon;
													   [rows addObject:row];
													   startSP = endSP;
												   }
												   [sections addObject:section];
											   }

											   
										   }];
									   }
						   completionHandler:^(NCTask *task) {
							   if (![task isCancelled]) {
								   self.sections = sections;
								   [self update];
							   }
						   }];
}

- (void) loadBlueprintAttributes {
	NCAccount *account = [NCAccount currentAccount];
	NCCharacterAttributes* attributes = [account characterAttributes];
	if (!attributes)
		attributes = [NCCharacterAttributes defaultCharacterAttributes];
	
	NSMutableArray* sections = [NSMutableArray new];
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NCDatabase* database = [NCDatabase sharedDatabase];
											 [database.backgroundManagedObjectContext performBlockAndWait:^{
												 NCDBInvType* type = (NCDBInvType*) [database.backgroundManagedObjectContext objectWithID:self.type.objectID];
												 NCDBIndBlueprintType* blueprintType = type.blueprintType;
												 NCDBEveIcon* skillIcon = [NCDBEveIcon eveIconWithIconFile:@"50_11"];

												 for (NCDBIndActivity* activity in [blueprintType.activities sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"activity.activityID" ascending:YES]]]) {
													 NSMutableArray* rows = [NSMutableArray new];
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Time", nil);
													 row.detail = [NSString stringWithTimeLeft:activity.time];
													 [rows addObject:row];

													 if (activity.products.count > 0) {
														 for (NCDBIndProduct* product in [activity.products sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"productType.typeName" ascending:YES]]]) {
															 row = [NCDatabaseTypeInfoViewControllerRow new];
															 row.title = NSLocalizedString(@"Product", nil);
															 row.detail = product.productType.typeName;
															 row.icon = product.productType.icon;
															 row.object = product.productType;
															 row.cellIdentifier = @"TypeCell";
															 [rows addObject:row];
														 }
													 }
													 if (rows.count > 0)
														 [sections addObject:@{@"title" : activity.activity.activityName, @"rows" : rows}];
													 
													 if (activity.requiredMaterials.count > 0) {
														 rows = [NSMutableArray new];
														 for (NCDBIndRequiredMaterial* material in activity.requiredMaterials) {
															 row = [NCDatabaseTypeInfoViewControllerRow new];
															 row.title = material.materialType.typeName;
															 row.detail = [NSNumberFormatter neocomLocalizedStringFromInteger:material.quantity];
															 row.icon = material.materialType.icon;
															 row.object = material.materialType;
															 row.cellIdentifier = @"TypeCell";
															 [rows addObject:row];
														 }
														 [sections addObject:@{@"title" : [NSString stringWithFormat:NSLocalizedString(@"%@ - Material / Mineral", nil), activity.activity.activityName], @"rows" : rows}];
													 }
													 
													 if (activity.requiredSkills.count > 0) {
														 rows = [NSMutableArray new];
														 
														 NCTrainingQueue* requiredSkillsQueue = [[NCTrainingQueue alloc] initWithAccount:account];
														 for (NCDBIndRequiredSkill* skill in activity.requiredSkills)
															 [requiredSkillsQueue addSkill:skill.skillType withLevel:skill.skillLevel];
														 
														 NSString* title = nil;
														 
														 if (requiredSkillsQueue.trainingTime > 0)
															 title = [NSString stringWithFormat:NSLocalizedString(@"%@ - Skills (%@)", nil), activity.activity.activityName, [NSString stringWithTimeLeft:requiredSkillsQueue.trainingTime]];
														 else
															 title = [NSString stringWithFormat:NSLocalizedString(@"%@ - Skills", nil), activity.activity.activityName];
														 
														 
														 if (requiredSkillsQueue.skills.count && account && account.activeSkillPlan) {
															 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
															 row.title = NSLocalizedString(@"Add required skills to training plan", nil);
															 row.detail = [NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:requiredSkillsQueue.trainingTime]];
															 row.icon = [NCDBEveIcon eveIconWithIconFile:@"50_13"];
															 row.object = requiredSkillsQueue;
															 [rows addObject:row];
														 }

														 
														 for (NCDBIndRequiredSkill* skill in [activity.requiredSkills sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"skillType.typeName" ascending:YES]]]) {
															 NCSkillHierarchy* hierarchy = [[NCSkillHierarchy alloc] initWithSkillType:skill.skillType level:skill.skillLevel account:account];
															 
															 for (NCSkillHierarchySkill* skill in hierarchy.skills) {
																 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
																 row.title = [NSString stringWithFormat:@"%@ %d", skill.type.typeName, skill.targetLevel];
																 row.object = skill.type;
																 row.cellIdentifier = @"TypeCell";
																 row.indentationLevel = skill.nestingLevel;
																 row.icon = skillIcon;
																 
																 switch (skill.availability) {
																	 case NCSkillHierarchyAvailabilityLearned:
																		 row.accessoryIcon = [NCDBEveIcon eveIconWithIconFile:@"38_193"];
																		 break;
																	 case NCSkillHierarchyAvailabilityNotLearned:
																		 row.accessoryIcon = [NCDBEveIcon eveIconWithIconFile:@"38_194"];
																		 break;
																	 case NCSkillHierarchyAvailabilityLowLevel:
																		 row.accessoryIcon = [NCDBEveIcon eveIconWithIconFile:@"38_195"];
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

													 }
												 }
												 
/*												 NSMutableArray *rows = [NSMutableArray new];
												 NCDatabaseTypeInfoViewControllerRow* row;
												 
												 NCDBInvType* productType = type.blueprintType.productType;
												 NCDBInvBlueprintType* blueprintType = type.blueprintType;
												 
												 row = [NCDatabaseTypeInfoViewControllerRow new];
												 row.title = NSLocalizedString(@"Product", nil);
												 row.detail = productType.typeName;
												 row.icon = productType.icon;
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
												 
												 NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"DgmTypeAttribute"];
												 request.predicate = [NSPredicate predicateWithFormat:@"type == %@ AND attributeType.published == TRUE", type];
												 request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"attributeType.attributeCategory.categoryName" ascending:YES],
																			 [NSSortDescriptor sortDescriptorWithKey:@"attributeType.displayName" ascending:YES]];
												 NSFetchedResultsController* controller = [[NSFetchedResultsController alloc] initWithFetchRequest:request
																															  managedObjectContext:database.backgroundManagedObjectContext
																																sectionNameKeyPath:@"attributeType.attributeCategory.categoryName"
																																		 cacheName:nil];
												 [controller performFetch:nil];
												 
												 for (id<NSFetchedResultsSectionInfo> sectionInfo in controller.sections) {
													 NSMutableArray *rows = [NSMutableArray array];
													 
													 NCDBDgmAttributeCategory* category = [[(NCDBDgmTypeAttribute*) sectionInfo.objects[0] attributeType] attributeCategory];
													 
													 NSString* title = nil;
													 
													 if (category.categoryID == 8 && trainingQueue.trainingTime > 0)
														 title = [NSString stringWithFormat:@"%@ (%@)", category.categoryName, [NSString stringWithTimeLeft:trainingQueue.trainingTime]];
													 else
														 title = category.categoryID == 9 ? @"Other" : category.categoryName;
													 
													 for (NCDBDgmTypeAttribute *attribute in sectionInfo.objects) {
														 NSString *unit = attribute.attributeType.unit.displayName;
														 
														 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
														 row.title = attribute.attributeType.displayName;
														 row.detail = [NSString stringWithFormat:@"%@ %@", [NSNumberFormatter neocomLocalizedStringFromNumber:@(attribute.value)], unit ? unit : @""];
														 row.icon = attribute.attributeType.icon;
														 [rows addObject:row];
													 }
													 if (rows.count > 0)
														 [sections addObject:@{@"title" : title, @"rows" : rows}];
												 }
												 
												 NSArray* activities = [[blueprintType activities] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"activityID" ascending:YES]]];;
												 NCDBEveIcon* skillIcon = [NCDBEveIcon eveIconWithIconFile:@"50_11"];
												 for (NCDBRamActivity* activity in activities) {
													 NSArray* requiredSkills = [[type.blueprintType requiredSkillsForActivity:activity] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"requiredType.typeName" ascending:YES]]];
													 NCTrainingQueue* requiredSkillsQueue = [[NCTrainingQueue alloc] initWithAccount:account];
													 for (NCDBRamTypeRequirement* skill in requiredSkills)
														 [requiredSkillsQueue addSkill:skill.requiredType withLevel:skill.quantity];
													 
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
														 row.icon = [NCDBEveIcon eveIconWithIconFile:@"50_13"];
														 row.object = requiredSkillsQueue;
														 [rows addObject:row];
													 }
													 
													 
													 for (NCDBRamTypeRequirement* skill in requiredSkills) {
														 NCSkillHierarchy* hierarchy = [[NCSkillHierarchy alloc] initWithSkillType:skill.requiredType level:skill.quantity account:account];
														 
														 for (NCSkillHierarchySkill* skill in hierarchy.skills) {
															 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
															 row.title = [NSString stringWithFormat:@"%@ %d", skill.type.typeName, skill.targetLevel];
															 row.object = skill.type;
															 row.cellIdentifier = @"TypeCell";
															 row.indentationLevel = skill.nestingLevel;
															 row.icon = skillIcon;
															 
															 switch (skill.availability) {
																 case NCSkillHierarchyAvailabilityLearned:
																	 row.accessoryIcon = [NCDBEveIcon eveIconWithIconFile:@"38_193"];
																	 break;
																 case NCSkillHierarchyAvailabilityNotLearned:
																	 row.accessoryIcon = [NCDBEveIcon eveIconWithIconFile:@"38_194"];
																	 break;
																 case NCSkillHierarchyAvailabilityLowLevel:
																	 row.accessoryIcon = [NCDBEveIcon eveIconWithIconFile:@"38_195"];
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
													 
													 for (NCDBRamTypeRequirement* requirement in [[type.blueprintType requiredMaterialsForActivity:activity] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"requiredType.typeName" ascending:YES]]]) {
														 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
														 row.title = [requirement requiredType].typeName;
														 row.detail = [NSNumberFormatter neocomLocalizedStringFromInteger:[[requirement valueForKey:@"quantity"] intValue]];
														 row.icon = requirement.requiredType.icon;
														 row.object = [requirement requiredType];
														 row.cellIdentifier = @"TypeCell";
														 [rows addObject:row];
													 }
													 if (activity.activityID == 1) {//Manufacturing
														 for (NCDBInvTypeMaterial* material in [blueprintType.materials sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"quantity" ascending:NO]]]) {
															 float waste = blueprintType.wasteFactor / 100.0;
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
															 row.icon = material.materialType.icon;
															 row.object = material.materialType;
															 row.cellIdentifier = @"TypeCell";
															 [rows addObject:row];
														 }
													 }
													 
													 if (rows.count > 0)
														 [sections addObject:@{@"title" : [NSString stringWithFormat:NSLocalizedString(@"%@ - Material / Mineral", nil), activity.activityName], @"rows" : rows}];
												 }*/

											 }];
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.sections = sections;
									 [self update];
								 }
							 }];
}

- (void) loadNPCAttributes {
	NSMutableArray* sections = [NSMutableArray new];
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NCDatabase* database = [NCDatabase sharedDatabase];
											 [database.backgroundManagedObjectContext performBlockAndWait:^{
												 NCDBInvType* type = (NCDBInvType*) [database.backgroundManagedObjectContext objectWithID:self.type.objectID];

											 NCDBDgmTypeAttribute* emDamageAttribute = type.attributesDictionary[@(114)];
											 NCDBDgmTypeAttribute* explosiveDamageAttribute = type.attributesDictionary[@(116)];
											 NCDBDgmTypeAttribute* kineticDamageAttribute = type.attributesDictionary[@(117)];
											 NCDBDgmTypeAttribute* thermalDamageAttribute = type.attributesDictionary[@(118)];
											 NCDBDgmTypeAttribute* damageMultiplierAttribute = type.attributesDictionary[@(64)];
											 NCDBDgmTypeAttribute* missileDamageMultiplierAttribute = type.attributesDictionary[@(212)];
											 NCDBDgmTypeAttribute* missileTypeIDAttribute = type.attributesDictionary[@(507)];
											 NCDBDgmTypeAttribute* missileVelocityMultiplierAttribute = type.attributesDictionary[@(645)];
											 NCDBDgmTypeAttribute* missileFlightTimeMultiplierAttribute = type.attributesDictionary[@(646)];
											 
											 NCDBDgmTypeAttribute* armorEmDamageResonanceAttribute = type.attributesDictionary[@(267)];
											 NCDBDgmTypeAttribute* armorExplosiveDamageResonanceAttribute = type.attributesDictionary[@(268)];
											 NCDBDgmTypeAttribute* armorKineticDamageResonanceAttribute = type.attributesDictionary[@(269)];
											 NCDBDgmTypeAttribute* armorThermalDamageResonanceAttribute = type.attributesDictionary[@(270)];
											 
											 NCDBDgmTypeAttribute* shieldEmDamageResonanceAttribute = type.attributesDictionary[@(271)];
											 NCDBDgmTypeAttribute* shieldExplosiveDamageResonanceAttribute = type.attributesDictionary[@(272)];
											 NCDBDgmTypeAttribute* shieldKineticDamageResonanceAttribute = type.attributesDictionary[@(273)];
											 NCDBDgmTypeAttribute* shieldThermalDamageResonanceAttribute = type.attributesDictionary[@(274)];
											 
											 NCDBDgmTypeAttribute* structureEmDamageResonanceAttribute = type.attributesDictionary[@(113)];
											 NCDBDgmTypeAttribute* structureExplosiveDamageResonanceAttribute = type.attributesDictionary[@(111)];
											 NCDBDgmTypeAttribute* structureKineticDamageResonanceAttribute = type.attributesDictionary[@(109)];
											 NCDBDgmTypeAttribute* structureThermalDamageResonanceAttribute = type.attributesDictionary[@(110)];
											 
											 NCDBDgmTypeAttribute* armorHPAttribute = type.attributesDictionary[@(265)];
											 NCDBDgmTypeAttribute* hpAttribute = type.attributesDictionary[@(9)];
											 NCDBDgmTypeAttribute* shieldCapacityAttribute = type.attributesDictionary[@(263)];
											 NCDBDgmTypeAttribute* shieldRechargeRate = type.attributesDictionary[@(479)];
											 
											 NCDBDgmTypeAttribute* optimalAttribute = type.attributesDictionary[@(54)];
											 NCDBDgmTypeAttribute* falloffAttribute = type.attributesDictionary[@(158)];
											 NCDBDgmTypeAttribute* trackingSpeedAttribute = type.attributesDictionary[@(160)];
											 
											 NCDBDgmTypeAttribute* turretFireSpeedAttribute = type.attributesDictionary[@(51)];
											 NCDBDgmTypeAttribute* missileLaunchDurationAttribute = type.attributesDictionary[@(506)];
											 
											 
											 //NPC Info
											 {
												 NSMutableArray* rows = [[NSMutableArray alloc] init];
												 
												 NCDBDgmTypeAttribute* bountyAttribute = type.attributesDictionary[@(481)];
												 if (bountyAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = bountyAttribute.attributeType.displayName;
													 row.icon = bountyAttribute.attributeType.icon;
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(bountyAttribute.value)]];
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* securityStatusBonusAttribute = type.attributesDictionary[@(252)];
												 if (securityStatusBonusAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Security Increase", nil);
													 row.icon = securityStatusBonusAttribute.attributeType.icon;
													 row.detail = [NSString stringWithFormat:@"%f", securityStatusBonusAttribute.value];
													 [rows addObject:row];
												 }
												 
												 
												 NCDBDgmTypeAttribute* factionLossAttribute = type.attributesDictionary[@(562)];
												 if (factionLossAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Faction Stading Loss", nil);
													 row.icon = factionLossAttribute.attributeType.icon;
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
												 NSString* icons[] = {@"22_12", @"22_11", @"22_09", @"22_10", @"12_09", @"22_21", @"22_15", @"22_23", @"22_22"};
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
													 row.icon = [NCDBEveIcon eveIconWithIconFile:icons[i]];
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
												 NCDBInvType* missile = [NCDBInvType invTypeWithTypeID:(int32_t)[missileTypeIDAttribute value]];
												 if (missile) {
													 NSMutableArray* rows = [[NSMutableArray alloc] init];
													 
													 NCDBDgmTypeAttribute* emDamageAttribute = missile.attributesDictionary[@(114)];
													 NCDBDgmTypeAttribute* explosiveDamageAttribute = missile.attributesDictionary[@(116)];
													 NCDBDgmTypeAttribute* kineticDamageAttribute = missile.attributesDictionary[@(117)];
													 NCDBDgmTypeAttribute* thermalDamageAttribute = missile.attributesDictionary[@(118)];
													 NCDBDgmTypeAttribute* maxVelocityAttribute = missile.attributesDictionary[@(37)];
													 NCDBDgmTypeAttribute* explosionDelayAttribute = missile.attributesDictionary[@(281)];
													 NCDBDgmTypeAttribute* agilityAttribute = missile.attributesDictionary[@(70)];
													 
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
													 NSString* icons[] = {@"22_12", @"22_11", @"22_09", @"22_10", @"12_12", @"22_21", @"22_15"};
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
													 row.icon = missile.icon;
													 row.object = missile;
													 row.cellIdentifier = @"TypeCell";
													 [rows addObject:row];
													 
													 for (int i = 0; i < 7; i++) {
														 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
														 row.title = titles[i];
														 row.icon = [NCDBEveIcon eveIconWithIconFile:icons[i]];
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
												 NSString* icons[] = {@"22_12", @"22_11", @"22_09", @"22_10", @"22_21"};
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
													 row.icon = [NCDBEveIcon eveIconWithIconFile:icons[i]];
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
												 NSString* icons[] = {@"01_13", @"22_12", @"22_11", @"22_09", @"22_10", @"22_16", @"01_15"};
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
													 row.icon = [NCDBEveIcon eveIconWithIconFile:icons[i]];
													 [rows addObject:row];
												 }
												 
												 if (type.effectsDictionary[@(2192)] || type.effectsDictionary[@(2193)] || type.effectsDictionary[@(2194)] || type.effectsDictionary[@(876)]) {
													 NCDBDgmTypeAttribute* shieldBoostAmountAttribute = type.attributesDictionary[@(637)];
													 NCDBDgmTypeAttribute* shieldBoostDurationAttribute = type.attributesDictionary[@(636)];
													 NCDBDgmTypeAttribute* shieldBoostDelayChanceAttribute = type.attributesDictionary[@(639)];
													 
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
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"02_03"];
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
												 NSString* icons[] = {@"01_09", @"22_12", @"22_11", @"22_09", @"22_10"};
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
													 row.icon = [NCDBEveIcon eveIconWithIconFile:icons[i]];
													 [rows addObject:row];
												 }
												 
												 if (type.effectsDictionary[@(2195)] || type.effectsDictionary[@(2196)] || type.effectsDictionary[@(2197)] || type.effectsDictionary[@(878)]) {
													 NCDBDgmTypeAttribute* armorRepairAmountAttribute = type.attributesDictionary[@(631)];
													 NCDBDgmTypeAttribute* armorRepairDurationAttribute = type.attributesDictionary[@(630)];
													 NCDBDgmTypeAttribute* armorRepairDelayChanceAttribute = type.attributesDictionary[@(638)];
													 
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
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"01_11"];;
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
												 NSString* icons[] = {@"02_09", @"22_12", @"22_11", @"22_09", @"22_10"};
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
													 row.icon = [NCDBEveIcon eveIconWithIconFile:icons[i]];
													 [rows addObject:row];
												 }
												 [sections addObject:@{@"title" : NSLocalizedString(@"Structure", nil), @"rows" : rows}];
											 }
											 
											 //Targeting
											 {
												 NSMutableArray* rows = [[NSMutableArray alloc] init];
												 
												 NCDBDgmTypeAttribute* attackRangeAttribute = type.attributesDictionary[@(247)];
												 if (attackRangeAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Attack Range", nil);
													 row.detail = [NSString stringWithFormat:@"%@ m", [NSNumberFormatter neocomLocalizedStringFromInteger:attackRangeAttribute.value]];
													 row.icon = attackRangeAttribute.attributeType.icon;
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* signatureRadiusAttribute = type.attributesDictionary[@(552)];
												 if (signatureRadiusAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = signatureRadiusAttribute.attributeType.displayName;
													 row.detail = [NSString stringWithFormat:@"%@ m", [NSNumberFormatter neocomLocalizedStringFromInteger:signatureRadiusAttribute.value]];
													 row.icon = signatureRadiusAttribute.attributeType.icon;
													 [rows addObject:row];
												 }
												 
												 
												 NCDBDgmTypeAttribute* scanResolutionAttribute = type.attributesDictionary[@(564)];
												 if (scanResolutionAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = scanResolutionAttribute.attributeType.displayName;
													 row.detail = [NSString stringWithFormat:@"%@ m", [NSNumberFormatter neocomLocalizedStringFromInteger:scanResolutionAttribute.value]];
													 row.icon = scanResolutionAttribute.attributeType.icon;
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* sensorStrengthAttribute = type.attributesDictionary[@(208)];
												 if (sensorStrengthAttribute.value == 0)
													 sensorStrengthAttribute = type.attributesDictionary[@(209)];
												 if (sensorStrengthAttribute.value == 0)
													 sensorStrengthAttribute = type.attributesDictionary[@(210)];
												 if (sensorStrengthAttribute.value == 0)
													 sensorStrengthAttribute = type.attributesDictionary[@(211)];
												 if (sensorStrengthAttribute.value > 0) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = sensorStrengthAttribute.attributeType.displayName;
													 row.detail = [NSString stringWithFormat:@"%.0f", sensorStrengthAttribute.value];
													 row.icon = sensorStrengthAttribute.attributeType.icon;
													 [rows addObject:row];
												 }
												 
												 if (rows.count > 0)
													 [sections addObject:@{@"title" : NSLocalizedString(@"Targeting", nil), @"rows" : rows}];
											 }
											 
											 //Movement
											 {
												 NSMutableArray* rows = [[NSMutableArray alloc] init];
												 
												 NCDBDgmTypeAttribute* maxVelocityAttribute = type.attributesDictionary[@(37)];
												 if (maxVelocityAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = maxVelocityAttribute.attributeType.displayName;
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ m/s", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:maxVelocityAttribute.value]];
													 row.icon = maxVelocityAttribute.attributeType.icon;
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* orbitVelocityAttribute = type.attributesDictionary[@(508)];
												 if (orbitVelocityAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = orbitVelocityAttribute.attributeType.displayName;
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ m/s", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:orbitVelocityAttribute.value]];
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"22_13"];
													 [rows addObject:row];
												 }
												 
												 
												 NCDBDgmTypeAttribute* entityFlyRangeAttribute = type.attributesDictionary[@(416)];
												 if (entityFlyRangeAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Orbit Range", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:entityFlyRangeAttribute.value]];
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"22_15"];
													 [rows addObject:row];
												 }
												 
												 if (rows.count > 0)
													 [sections addObject:@{@"title" : NSLocalizedString(@"Movement", nil), @"rows" : rows}];
											 }
											 
											 //Stasis Webifying
											 if (type.effectsDictionary[@(575)] || type.effectsDictionary[@(3714)]) {
												 NSMutableArray* rows = [[NSMutableArray alloc] init];
												 
												 NCDBDgmTypeAttribute* speedFactorAttribute = type.attributesDictionary[@(20)];
												 if (speedFactorAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = speedFactorAttribute.attributeType.displayName;
													 row.detail = [NSString stringWithFormat:@"%.0f %%", speedFactorAttribute.value];
													 row.icon = speedFactorAttribute.attributeType.icon;
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* modifyTargetSpeedRangeAttribute = type.attributesDictionary[@(514)];
												 if (modifyTargetSpeedRangeAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Range", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:modifyTargetSpeedRangeAttribute.value]];
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"22_15"];
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* modifyTargetSpeedDurationAttribute = type.attributesDictionary[@(513)];
												 if (modifyTargetSpeedDurationAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Duration", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%.2f s", nil), modifyTargetSpeedDurationAttribute.value / 1000.0];
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"22_16"];
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* modifyTargetSpeedChanceAttribute = type.attributesDictionary[@(512)];
												 if (modifyTargetSpeedChanceAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Webbing Chance", nil);
													 row.detail = [NSString stringWithFormat:@"%.0f %%", modifyTargetSpeedChanceAttribute.value * 100];
													 row.icon = modifyTargetSpeedChanceAttribute.attributeType.icon;
													 [rows addObject:row];
												 }
												 
												 if (rows.count > 0)
													 [sections addObject:@{@"title" : NSLocalizedString(@"Stasis Webifying", nil), @"rows" : rows}];
											 }
											 
											 //Warp Scramble
											 if (type.effectsDictionary[@(39)] || type.effectsDictionary[@(563)] || type.effectsDictionary[@(3713)]) {
												 NSMutableArray* rows = [[NSMutableArray alloc] init];
												 
												 NCDBDgmTypeAttribute* warpScrambleStrengthAttribute = type.attributesDictionary[@(105)];
												 if (warpScrambleStrengthAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = warpScrambleStrengthAttribute.attributeType.displayName;
													 row.detail = [NSString stringWithFormat:@"%.0f", warpScrambleStrengthAttribute.value];
													 row.icon = warpScrambleStrengthAttribute.attributeType.icon;
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* warpScrambleRangeAttribute = type.attributesDictionary[@(103)];
												 if (warpScrambleRangeAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = warpScrambleRangeAttribute.attributeType.displayName;
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:warpScrambleRangeAttribute.value]];
													 row.icon = warpScrambleRangeAttribute.attributeType.icon;
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* warpScrambleDurationAttribute = type.attributesDictionary[@(505)];
												 if (warpScrambleDurationAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = warpScrambleDurationAttribute.attributeType.displayName;
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%.2f s", nil), warpScrambleDurationAttribute.value / 1000];
													 row.icon = warpScrambleDurationAttribute.attributeType.icon;
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* warpScrambleChanceAttribute = type.attributesDictionary[@(504)];
												 if (warpScrambleChanceAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Scrambling Chance", nil);
													 row.detail = [NSString stringWithFormat:@"%.0f %%", warpScrambleChanceAttribute.value * 100];
													 row.icon = warpScrambleChanceAttribute.attributeType.icon;
													 [rows addObject:row];
												 }
												 
												 if (rows.count > 0)
													 [sections addObject:@{@"title" : NSLocalizedString(@"Warp Scramble", nil), @"rows" : rows}];
											 }
											 
											 //Target Painting
											 if (type.effectsDictionary[@(1879)]) {
												 NSMutableArray* rows = [[NSMutableArray alloc] init];
												 
												 NCDBDgmTypeAttribute* signatureRadiusBonusAttribute = type.attributesDictionary[@(554)];
												 if (signatureRadiusBonusAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = signatureRadiusBonusAttribute.attributeType.displayName;
													 row.detail = [NSString stringWithFormat:@"%.0f %%", signatureRadiusBonusAttribute.value];
													 row.icon = signatureRadiusBonusAttribute.attributeType.icon;
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* targetPaintRangeAttribute = type.attributesDictionary[@(941)];
												 if (targetPaintRangeAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Optimal Range", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:targetPaintRangeAttribute.value]];
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"22_15"];
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* targetPaintFalloffAttribute = type.attributesDictionary[@(954)];
												 if (targetPaintFalloffAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Accuracy Falloff", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:targetPaintFalloffAttribute.value]];
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"22_23"];
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* targetPaintDurationAttribute = type.attributesDictionary[@(945)];
												 if (targetPaintDurationAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Duration", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%.2f s", nil), targetPaintDurationAttribute.value / 1000];
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"22_16"];
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* targetPaintChanceAttribute = type.attributesDictionary[@(935)];
												 if (targetPaintChanceAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Chance", nil);
													 row.detail = [NSString stringWithFormat:@"%.0f %%", targetPaintChanceAttribute.value * 100];
													 row.icon = targetPaintChanceAttribute.attributeType.icon;
													 [rows addObject:row];
												 }
												 
												 if (rows.count > 0)
													 [sections addObject:@{@"title" : NSLocalizedString(@"Target Painting", nil), @"rows" : rows}];
											 }
											 
											 //Tracking Disruption
											 if (type.effectsDictionary[@(1877)]) {
												 NSMutableArray* rows = [[NSMutableArray alloc] init];
												 
												 NCDBDgmTypeAttribute* trackingDisruptMultiplierAttribute = type.attributesDictionary[@(948)];
												 if (trackingDisruptMultiplierAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Tracking Speed Bonus", nil);
													 row.detail = [NSString stringWithFormat:@"%.0f %%", (trackingDisruptMultiplierAttribute.value - 1) * 100];
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"22_22"];
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* trackingDisruptRangeAttribute = type.attributesDictionary[@(940)];
												 if (trackingDisruptRangeAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Optimal Range", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:trackingDisruptRangeAttribute.value]];
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"22_15"];
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* trackingDisruptFalloffAttribute = type.attributesDictionary[@(951)];
												 if (trackingDisruptFalloffAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Accuracy Falloff", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:trackingDisruptFalloffAttribute.value]];
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"22_23"];
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* trackingDisruptDurationAttribute = type.attributesDictionary[@(944)];
												 if (trackingDisruptDurationAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Duration", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%.2f s", nil), trackingDisruptDurationAttribute.value / 1000];
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"22_16"];
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* trackingDisruptChanceAttribute = type.attributesDictionary[@(933)];
												 if (trackingDisruptChanceAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Chance", nil);
													 row.detail = [NSString stringWithFormat:@"%.0f %%", trackingDisruptChanceAttribute.value * 100];
													 row.icon = trackingDisruptChanceAttribute.attributeType.icon;
													 [rows addObject:row];
												 }
												 
												 if (rows.count > 0)
													 [sections addObject:@{@"title" : NSLocalizedString(@"Tracking Disruption", nil), @"rows" : rows}];
											 }
											 
											 //Sensor Dampening
											 if (type.effectsDictionary[@(1878)]) {
												 NSMutableArray* rows = [[NSMutableArray alloc] init];
												 
												 NCDBDgmTypeAttribute* maxTargetRangeMultiplierAttribute = type.attributesDictionary[@(237)];
												 if (maxTargetRangeMultiplierAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Max Targeting Range Bonus", nil);
													 row.detail = [NSString stringWithFormat:@"%.0f %%", (maxTargetRangeMultiplierAttribute.value - 1) * 100];
													 row.icon = maxTargetRangeMultiplierAttribute.attributeType.icon;
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* scanResolutionMultiplierAttribute = type.attributesDictionary[@(565)];
												 if (scanResolutionMultiplierAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Scan Resolution Bonus", nil);
													 row.detail = [NSString stringWithFormat:@"%.0f %%", (scanResolutionMultiplierAttribute.value - 1) * 100];
													 row.icon = scanResolutionMultiplierAttribute.attributeType.icon;
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* sensorDampenRangeAttribute = type.attributesDictionary[@(938)];
												 if (sensorDampenRangeAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Optimal Range", nil);
													 row.detail = [NSString stringWithFormat:@"%@ m", [NSNumberFormatter neocomLocalizedStringFromInteger:sensorDampenRangeAttribute.value]];
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"22_15"];
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* sensorDampenFalloffAttribute = type.attributesDictionary[@(950)];
												 if (sensorDampenFalloffAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Accuracy Falloff", nil);
													 row.detail = [NSString stringWithFormat:@"%@ m", [NSNumberFormatter neocomLocalizedStringFromInteger:sensorDampenFalloffAttribute.value]];
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"22_23"];
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* sensorDampenDurationAttribute = type.attributesDictionary[@(943)];
												 if (sensorDampenDurationAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Duration", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%.2f s", nil), sensorDampenDurationAttribute.value / 1000];
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"22_16"];
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* sensorDampenChanceAttribute = type.attributesDictionary[@(932)];
												 if (sensorDampenChanceAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Chance", nil);
													 row.detail = [NSString stringWithFormat:@"%.0f %%", sensorDampenChanceAttribute.value * 100];
													 row.icon = sensorDampenChanceAttribute.attributeType.icon;
													 [rows addObject:row];
												 }
												 
												 if (rows.count > 0)
													 [sections addObject:@{@"title" : NSLocalizedString(@"Sensor Dampening", nil), @"rows" : rows}];
											 }
											 
											 //ECM Jamming
											 if (type.effectsDictionary[@(1871)] || type.effectsDictionary[@(1752)] || type.effectsDictionary[@(3710)] || type.effectsDictionary[@(4656)]) {
												 NSMutableArray* rows = [[NSMutableArray alloc] init];
												 
												 NCDBDgmTypeAttribute* scanGravimetricStrengthBonusAttribute = type.attributesDictionary[@(238)];
												 if (scanGravimetricStrengthBonusAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = scanGravimetricStrengthBonusAttribute.attributeType.displayName;
													 row.detail = [NSString stringWithFormat:@"%.2f", scanGravimetricStrengthBonusAttribute.value];
													 row.icon = scanGravimetricStrengthBonusAttribute.attributeType.icon;
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* scanLadarStrengthBonusAttribute = type.attributesDictionary[@(239)];
												 if (scanLadarStrengthBonusAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = scanLadarStrengthBonusAttribute.attributeType.displayName;
													 row.detail = [NSString stringWithFormat:@"%.2f", scanLadarStrengthBonusAttribute.value];
													 row.icon = scanLadarStrengthBonusAttribute.attributeType.icon;
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* scanMagnetometricStrengthBonusAttribute = type.attributesDictionary[@(240)];
												 if (scanMagnetometricStrengthBonusAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = scanMagnetometricStrengthBonusAttribute.attributeType.displayName;
													 row.detail = [NSString stringWithFormat:@"%.2f", scanMagnetometricStrengthBonusAttribute.value];
													 row.icon = scanMagnetometricStrengthBonusAttribute.attributeType.icon;
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* scanRadarStrengthBonusAttribute = type.attributesDictionary[@(241)];
												 if (scanLadarStrengthBonusAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = scanRadarStrengthBonusAttribute.attributeType.displayName;
													 row.detail = [NSString stringWithFormat:@"%.2f", scanRadarStrengthBonusAttribute.value];
													 row.icon = scanRadarStrengthBonusAttribute.attributeType.icon;
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* targetJamRangeAttribute = type.attributesDictionary[@(936)];
												 if (targetJamRangeAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Optimal Range", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:targetJamRangeAttribute.value]];
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"22_15"];
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* targetJamFalloffAttribute = type.attributesDictionary[@(953)];
												 if (targetJamFalloffAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Accuracy Falloff", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:targetJamFalloffAttribute.value]];
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"22_23"];
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* targetJamDurationAttribute = type.attributesDictionary[@(929)];
												 if (targetJamDurationAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Duration", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%.2f s", nil), targetJamDurationAttribute.value / 1000];
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"22_16"];
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* targetJamChanceAttribute = type.attributesDictionary[@(930)];
												 if (targetJamChanceAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Chance", nil);
													 row.detail = [NSString stringWithFormat:@"%.0f %%", targetJamChanceAttribute.value * 100];
													 row.icon = targetJamChanceAttribute.attributeType.icon;
													 [rows addObject:row];
												 }
												 
												 if (rows.count > 0)
													 [sections addObject:@{@"title" : NSLocalizedString(@"ECM Jamming", nil), @"rows" : rows}];
											 }
											 
											 //Energy Vampire
											 if (type.effectsDictionary[@(1872)]) {
												 NSMutableArray* rows = [[NSMutableArray alloc] init];
												 
												 NCDBDgmTypeAttribute* capacitorDrainAmountAttribute = type.attributesDictionary[@(946)];
												 if (!capacitorDrainAmountAttribute)
													 capacitorDrainAmountAttribute = type.attributesDictionary[@(90)];
												 
												 NCDBDgmTypeAttribute* capacitorDrainDurationAttribute = type.attributesDictionary[@(942)];
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
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"22_08"];
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* capacitorDrainRangeAttribute = type.attributesDictionary[@(937)];
												 if (capacitorDrainRangeAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Optimal Range", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:capacitorDrainRangeAttribute.value]];
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"22_15"];
													 [rows addObject:row];
												 }
												 
												 if (capacitorDrainDurationAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Duration", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%.2f s", nil), capacitorDrainDurationAttribute.value / 1000];
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"22_16"];
													 [rows addObject:row];
												 }
												 
												 NCDBDgmTypeAttribute* capacitorDrainChanceAttribute = type.attributesDictionary[@(931)];
												 if (capacitorDrainChanceAttribute) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Chance", nil);
													 row.detail = [NSString stringWithFormat:@"%.0f %%", capacitorDrainChanceAttribute.value * 100];
													 row.icon = capacitorDrainChanceAttribute.attributeType.icon;
													 [rows addObject:row];
												 }
												 
												 if (rows.count > 0)
													 [sections addObject:@{@"title" : NSLocalizedString(@"Energy Vampire", nil), @"rows" : rows}];
											 }
											 }];
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.sections = sections;
									 [self update];
								 }
							 }];
}

- (void) loadWHAttributes {
	NCAccount *account = [NCAccount currentAccount];
	NCCharacterAttributes* attributes = [account characterAttributes];
	if (!attributes)
		attributes = [NCCharacterAttributes defaultCharacterAttributes];
	
	NSMutableArray* sections = [NSMutableArray new];
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NCDatabase* database = [NCDatabase sharedDatabase];
											 [database.backgroundManagedObjectContext performBlockAndWait:^{
												 NCDBInvType* type = (NCDBInvType*) [database.backgroundManagedObjectContext objectWithID:self.type.objectID];
												 
												 NSMutableArray* rows = [[NSMutableArray alloc] init];
												 
												 NCDBDgmTypeAttribute* targetSystemClass = type.attributesDictionary[@(1381)];
												 NCDBDgmTypeAttribute* maxStableTime = type.attributesDictionary[@(1382)];
												 NCDBDgmTypeAttribute* maxStableMass = type.attributesDictionary[@(1383)];
												 NCDBDgmTypeAttribute* maxRegeneration = type.attributesDictionary[@(1384)];
												 NCDBDgmTypeAttribute* maxJumpMass = type.attributesDictionary[@(1385)];
												 
												 
												 
												 if (targetSystemClass) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Leads into", nil);
													 int32_t target = targetSystemClass.value;
													 if (target >= 1 && target <= 6)
														 row.detail = [NSString stringWithFormat:NSLocalizedString(@"W-Space Class %d", nil), target];
													 else if (target == 7)
														 row.detail = NSLocalizedString(@"High-sec", nil);
													 else if (target == 8)
														 row.detail = NSLocalizedString(@"Low-sec", nil);
													 else if (target == 9)
														 row.detail = NSLocalizedString(@"0.0 system", nil);
													 else if (target == 12)
														 row.detail = NSLocalizedString(@"Thera", nil);
													 else if (target == 13)
														 row.detail = NSLocalizedString(@"W-Frig", nil);
													 else
														 row.detail = [NSString stringWithFormat:NSLocalizedString(@"Unknown Class %d", nil), target];
													 
													 row.icon = self.defaultIcon;
													 [rows addObject:row];
												 }
												 if (maxStableTime) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Maximum Stable Time", nil);
													 int32_t time = maxStableTime.value / 60;
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%d h", nil), time];
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"22_16"];
													 [rows addObject:row];
												 }
												 if (maxStableMass) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Maximum Stable Mass", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ kg", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(maxStableMass.value)]];
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"02_10"];
													 [rows addObject:row];
												 }
												 if (maxJumpMass) {
													 NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvGroup"];
													 request.predicate = [NSPredicate predicateWithFormat:@"ANY types.mass <= %f AND category.categoryID = 6", maxJumpMass.value];
													 request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"category.categoryName" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"groupName" ascending:YES]];
													 NSFetchedResultsController* controller = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:type.managedObjectContext sectionNameKeyPath:@"category.categoryName" cacheName:nil];
													 [controller performFetch:nil];
													 
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.cellIdentifier = @"ResultsCell";
													 row.title = NSLocalizedString(@"Maximum Jump Mass", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ kg", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(maxJumpMass.value)]];
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"36_13"];
													 row.object = controller;
													 [rows addObject:row];
												 }
												 if (maxRegeneration) {
													 NCDatabaseTypeInfoViewControllerRow* row = [NCDatabaseTypeInfoViewControllerRow new];
													 row.title = NSLocalizedString(@"Maximum Mass Regeneration", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"%@ kg", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(maxRegeneration.value)]];
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"23_03"];
													 [rows addObject:row];
												 }
												 if (rows.count > 0)
													 [sections addObject:@{@"title" : NSLocalizedString(@"Details", nil), @"rows" : rows}];

											 }];
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.sections = sections;
									 [self update];
								 }
							 }];
}

@end
