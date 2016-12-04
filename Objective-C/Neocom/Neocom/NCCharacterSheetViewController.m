//
//  NCCharacterSheetViewController.m
//  Neocom
//
//  Created by Artem Shimanski on 21.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCCharacterSheetViewController.h"
#import "NCProgressHandler.h"
#import "NCDataManager.h"
#import "NCManagedObjectObserver.h"
#import "NCTableViewHeaderCell.h"
#import "NCTableViewDefaultCell.h"
#import "NCUnitFormatter.h"
#import "NCTimeIntervalFormatter.h"
#import "NCCharacterAttributes.h"
#import "NCDispatchGroup.h"
#import "NCTreeSection.h"
#import "NCTreeRow.h"
#import "EVECharacterSheet+NC.h"



@interface NCCharacterSheetViewController ()
@property (nonatomic, strong) NCManagedObjectObserver* observer;
@property (nonatomic, strong) NCCacheRecord<EVECharacterSheet*>* characterSheet;
@property (nonatomic, strong) NCCacheRecord<EVECharacterInfo*>* characterInfo;
@property (nonatomic, strong) UIImage* characterImage;
@property (nonatomic, strong) UIImage* corporationImage;	
@property (nonatomic, strong) UIImage* allianceImage;
@property (nonatomic, strong) NSArray<NCTreeSection*>* sections;
@end

@implementation NCCharacterSheetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.tableView.estimatedRowHeight = self.tableView.rowHeight;
	self.tableView.rowHeight = UITableViewAutomaticDimension;
	self.refreshControl = [UIRefreshControl new];
	[self.refreshControl addTarget:self action:@selector(onRefresh:) forControlEvents:UIControlEventValueChanged];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (!self.sections)
		[self reloadWithCachePolicy:NSURLRequestUseProtocolCachePolicy];
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if ([NCStorage.sharedStorage.viewContext hasChanges])
		[NCStorage.sharedStorage.viewContext save:nil];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	if (!self.isViewLoaded || !self.view.window) {
		self.sections = nil;
		self.characterSheet = nil;
		self.characterInfo = nil;
		self.characterImage = nil;
		self.corporationImage = nil;
		self.allianceImage = nil;
		self.observer = nil;
	}
}

#pragma mark - ASTreeControllerDelegate

- (nonnull id)treeController:(nonnull ASTreeController *)treeController child:(NSInteger)index ofItem:(nullable NCTreeNode*)item {
	return item ? item.children[index] : self.sections[index];
}

- (NSInteger) treeController:(nonnull ASTreeController *)treeController numberOfChildrenOfItem:(nullable NCTreeNode*)item {
	return item ? item.children.count : self.sections.count;
}

- (nonnull NSString*) treeController:(nonnull ASTreeController *)treeController cellIdentifierForItem:(nonnull NCTreeNode*) item {
	return item.cellIdentifier;
}

- (void) treeController:(nonnull ASTreeController *)treeController configureCell:(nonnull __kindof UITableViewCell*) cell withItem:(nonnull NCTreeNode*) item {
	[item configure:cell];
}

- (BOOL) treeController:(nonnull ASTreeController *)treeController isItemExpandable:(nonnull NCTreeNode*)item {
	return item.canExpand;
}

- (BOOL) treeController:(nonnull ASTreeController *)treeController isItemExpanded:(nonnull NCTreeNode*)item {
	if (item.nodeIdentifier) {
		NSString* key = [NSString stringWithFormat:@"%@.%@", NSStringFromClass(self.class), item.nodeIdentifier];
		NCSetting* setting = [NCSetting settingForKey:key];
		return ![(id) setting.value boolValue];
	}
	return YES;
}

- (void) treeController:(nonnull ASTreeController *)treeController didSelectCell:(nonnull __kindof UITableViewCell*) cell withItem:(nonnull id)item {
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForCell:cell] animated:YES];
}

- (void) treeController:(nonnull ASTreeController *)treeController didExpandCell:(nonnull __kindof UITableViewCell*) cell withItem:(nonnull NCTreeNode*)item {
	if (item.nodeIdentifier) {
		NSString* key = [NSString stringWithFormat:@"%@.%@", NSStringFromClass(self.class), item.nodeIdentifier];
		NCSetting* setting = [NCSetting settingForKey:key];
		setting.value = @(NO);
	}
}

- (void) treeController:(nonnull ASTreeController *)treeController didCollapseCell:(nonnull __kindof UITableViewCell*) cell withItem:(nonnull NCTreeNode*)item {
	if (item.nodeIdentifier) {
		NSString* key = [NSString stringWithFormat:@"%@.%@", NSStringFromClass(self.class), item.nodeIdentifier];
		NCSetting* setting = [NCSetting settingForKey:key];
		setting.value = @(YES);
	}
}

#pragma mark - Private

- (void) reloadWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	NCProgressHandler* progressHandler = [NCProgressHandler progressHandlerForViewController:self withTotalUnitCount:2];
	
	NCAccount* account = NCAccount.currentAccount;
	NCDataManager* dataManager = [NCDataManager defaultManager];
	NCDispatchGroup* dispatchGroup = [NCDispatchGroup new];
	
	__weak typeof(self) weakSelf = self;
	self.observer = [NCManagedObjectObserver observerWithHandler:^(NSSet<NSManagedObjectID *> *updated, NSSet<NSManagedObjectID *> *deleted) {
		if ([updated containsObject:weakSelf.characterSheet.objectID])
			[weakSelf reloadImagesWithCachePolicy:NSURLRequestUseProtocolCachePolicy];
		[weakSelf reloadData];
	}];
	
	id token = [dispatchGroup enter];
	[progressHandler.progress becomeCurrentWithPendingUnitCount:1];
	[dataManager characterSheetForAccount:account cachePolicy:cachePolicy completionHandler:^(EVECharacterSheet *result, NSError *error, NSManagedObjectID *cacheRecordID) {
		if (cacheRecordID) {
			self.characterSheet = cacheRecordID ? [NCCache.sharedCache.viewContext objectWithID:cacheRecordID] : nil;
			[self.observer addObjectID:cacheRecordID];
			[self reloadImagesWithCachePolicy:cachePolicy];
		}
		[dispatchGroup leave:token];
	}];
	[progressHandler.progress resignCurrent];
	
	token = [dispatchGroup enter];
	[progressHandler.progress becomeCurrentWithPendingUnitCount:1];
	[dataManager characterInfoForAccount:account cachePolicy:cachePolicy completionHandler:^(EVECharacterInfo *result, NSError *error, NSManagedObjectID *cacheRecordID) {
		if (cacheRecordID) {
			self.characterInfo = cacheRecordID ? [NCCache.sharedCache.viewContext objectWithID:cacheRecordID] : nil;
			[self.observer addObjectID:cacheRecordID];
		}
		[dispatchGroup leave:token];
	}];
	[progressHandler.progress resignCurrent];
	
	[dispatchGroup notify:^{
		[self reloadData];
		[progressHandler finish];
		[self.refreshControl endRefreshing];
	}];
}

- (IBAction)onRefresh:(id)sender {
	[self reloadWithCachePolicy:NSURLRequestReloadIgnoringCacheData];
}

- (void) reloadImagesWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	if (!self.characterSheet)
		return;
	
	EVECharacterSheet* characterSheet = self.characterSheet.object;
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:characterSheet.allianceID ? 3 : 2];
	NCDataManager* dataManager = [NCDataManager defaultManager];
	[progress becomeCurrentWithPendingUnitCount:progress.totalUnitCount];
	[dataManager imageWithCharacterID:characterSheet.characterID preferredSize:CGSizeMake(512, 512) scale:UIScreen.mainScreen.scale cachePolicy:cachePolicy completionBlock:^(UIImage *image, NSError *error, NSManagedObjectID *cacheRecordID) {
		self.characterImage = image;
		[self.tableView reloadData];
	}];
	
	[dataManager imageWithCorporationID:characterSheet.corporationID preferredSize:CGSizeMake(32, 32) scale:UIScreen.mainScreen.scale cachePolicy:cachePolicy completionBlock:^(UIImage *image, NSError *error, NSManagedObjectID *cacheRecordID) {
		self.corporationImage = image;
		[self.tableView reloadData];
	}];
	
	if (characterSheet.allianceID)
		[dataManager imageWithAllianceID:characterSheet.allianceID preferredSize:CGSizeMake(32, 32) scale:UIScreen.mainScreen.scale cachePolicy:cachePolicy completionBlock:^(UIImage *image, NSError *error, NSManagedObjectID *cacheRecordID) {
			self.allianceImage = image;
			[self.tableView reloadData];
		}];
	[progress resignCurrent];
}

- (void) reloadData {
	if (!self.characterSheet) {
		self.sections = nil;
	}
	else {
		NSMutableArray* sections = [NSMutableArray new];
		[sections addObject:[self bioSection]];
		[sections addObject:[self accountSection]];
		[sections addObject:[self skillsSection]];
		[sections addObject:[self neuralRemapSection]];
		[sections addObject:[self attributesSection]];
		[sections addObject:[self implantsSectionWithTypeIDs:[self.characterSheet.object.implants valueForKey:@"typeID"]]];
		self.sections = sections;
	}
	[self.treeController reloadData];
}

- (NCTreeSection*) bioSection {
	NSMutableArray* rows = [NSMutableArray new];
	__weak typeof(self) weakSelf = self;
	
	[rows addObject:[NCTreeRow rowWithCellIdentifier:@"PortraitCell" configurationHandler:^(__kindof NCTableViewDefaultCell *cell) {
		cell.iconView.image = weakSelf.characterImage;
	}]];
	[rows addObject:[NCTreeRow rowWithCellIdentifier:@"Cell" configurationHandler:^(__kindof NCTableViewDefaultCell *cell) {
		cell.titleLabel.text = NSLocalizedString(@"CORPORATION", nil);
		cell.subtitleLabel.text = weakSelf.characterSheet.object.corporationName;
		cell.iconView.image = weakSelf.corporationImage;
	}]];
	if (self.characterSheet.object.allianceID)
		[rows addObject:[NCTreeRow rowWithCellIdentifier:@"Cell" configurationHandler:^(__kindof NCTableViewDefaultCell *cell) {
			cell.titleLabel.text = NSLocalizedString(@"ALLIANCE", nil);
			cell.subtitleLabel.text = weakSelf.characterSheet.object.allianceName;
			cell.iconView.image = weakSelf.allianceImage;
		}]];

	[rows addObject:[NCTreeRow rowWithCellIdentifier:@"Cell" configurationHandler:^(__kindof NCTableViewDefaultCell *cell) {
		cell.titleLabel.text = NSLocalizedString(@"DATE OF BIRTH", nil);
		cell.subtitleLabel.text = [NSDateFormatter localizedStringFromDate:weakSelf.characterSheet.object.DoB dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle];
		cell.iconView.image = nil;
	}]];

	[rows addObject:[NCTreeRow rowWithCellIdentifier:@"Cell" configurationHandler:^(__kindof NCTableViewDefaultCell *cell) {
		cell.titleLabel.text = NSLocalizedString(@"BLOODLINE", nil);
		cell.subtitleLabel.text = [NSString stringWithFormat:@"%@ / %@ / %@", weakSelf.characterSheet.object.race, weakSelf.characterSheet.object.bloodLine, weakSelf.characterSheet.object.ancestry];
		cell.iconView.image = nil;
	}]];

	
	return [NCTreeSection sectionWithNodeIdentifier:@"BIO" cellIdentifier:@"NCTableViewHeaderCell" title:NSLocalizedString(@"BIO", nil) children:rows];
}

- (NCTreeSection*) accountSection {
	NSMutableArray* rows = [NSMutableArray new];
	__weak typeof(self) weakSelf = self;
	
	[rows addObject:[NCTreeRow rowWithCellIdentifier:@"Cell" configurationHandler:^(__kindof NCTableViewDefaultCell *cell) {
		cell.titleLabel.text = NSLocalizedString(@"BALANCE", nil);
		cell.subtitleLabel.text = [NCUnitFormatter localizedStringFromNumber:@(weakSelf.characterSheet.object.balance) unit:NCUnitISK style:NCUnitFormatterStyleFull];
		cell.iconView.image = nil;
	}]];


	return [NCTreeSection sectionWithNodeIdentifier:@"ACCOUNT" cellIdentifier:@"NCTableViewHeaderCell" title:NSLocalizedString(@"ACCOUNT", nil) children:rows];
}

- (NCTreeSection*) skillsSection {
	NSMutableArray* rows = [NSMutableArray new];
	__weak typeof(self) weakSelf = self;
	
	if (self.characterInfo.object && self.characterSheet.objectID)
		[rows addObject:[NCTreeRow rowWithCellIdentifier:@"Cell" configurationHandler:^(__kindof NCTableViewDefaultCell *cell) {
			cell.titleLabel.text = NSLocalizedString(@"SKILL POINTS", nil);
			cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ (%d skills)", nil), [NCUnitFormatter localizedStringFromNumber:@(weakSelf.characterInfo.object.skillPoints) unit:NCUnitNone style:NCUnitFormatterStyleFull], (int) weakSelf.characterSheet.object.skills.count];
			cell.iconView.image = nil;
		}]];
	
	if (self.characterSheet.object.freeSkillPoints > 0)
		[rows addObject:[NCTreeRow rowWithCellIdentifier:@"Cell" configurationHandler:^(__kindof NCTableViewDefaultCell *cell) {
			cell.titleLabel.text = NSLocalizedString(@"UNALLOCATED SKILL POINTS", nil);
			cell.subtitleLabel.text = [NCUnitFormatter localizedStringFromNumber:@(weakSelf.characterSheet.object.freeSkillPoints) unit:NCUnitNone style:NCUnitFormatterStyleFull];
			cell.iconView.image = nil;
		}]];
	
	return [NCTreeSection sectionWithNodeIdentifier:@"SKILLS" cellIdentifier:@"NCTableViewHeaderCell" title:NSLocalizedString(@"SKILLS", nil) children:rows];
}

- (NCTreeSection*) attributesSection {
	NSMutableArray* rows = [NSMutableArray new];
	
	NCCharacterAttributes* attributes = [NCCharacterAttributes characterAttributesWithCharacterSheet:self.characterSheet.object];
	
	[rows addObject:[NCTreeRow rowWithCellIdentifier:@"Cell" configurationHandler:^(__kindof NCTableViewDefaultCell *cell) {
		cell.titleLabel.text = NSLocalizedString(@"INTELLIGENCE", nil);
		cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d points", nil), (int) attributes.intelligence];
		cell.iconView.image = [UIImage imageNamed:@"intelligence"];
	}]];
	
	[rows addObject:[NCTreeRow rowWithCellIdentifier:@"Cell" configurationHandler:^(__kindof NCTableViewDefaultCell *cell) {
		cell.titleLabel.text = NSLocalizedString(@"MEMORY", nil);
		cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d points", nil), (int) attributes.memory];
		cell.iconView.image = [UIImage imageNamed:@"memory"];
	}]];
	
	[rows addObject:[NCTreeRow rowWithCellIdentifier:@"Cell" configurationHandler:^(__kindof NCTableViewDefaultCell *cell) {
		cell.titleLabel.text = NSLocalizedString(@"PERCEPTION", nil);
		cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d points", nil), (int) attributes.perception];
		cell.iconView.image = [UIImage imageNamed:@"perception"];
	}]];

	[rows addObject:[NCTreeRow rowWithCellIdentifier:@"Cell" configurationHandler:^(__kindof NCTableViewDefaultCell *cell) {
		cell.titleLabel.text = NSLocalizedString(@"WILLPOWER", nil);
		cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d points", nil), (int) attributes.willpower];
		cell.iconView.image = [UIImage imageNamed:@"willpower"];
	}]];

	[rows addObject:[NCTreeRow rowWithCellIdentifier:@"Cell" configurationHandler:^(__kindof NCTableViewDefaultCell *cell) {
		cell.titleLabel.text = NSLocalizedString(@"CHARISMA", nil);
		cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d points", nil), (int) attributes.charisma];
		cell.iconView.image = [UIImage imageNamed:@"charisma"];
	}]];
	
	return [NCTreeSection sectionWithNodeIdentifier:@"ATTRIBUTES" cellIdentifier:@"NCTableViewHeaderCell" title:NSLocalizedString(@"ATTRIBUTES", nil) children:rows];
}

- (NCTreeSection*) neuralRemapSection {
	NSMutableArray* rows = [NSMutableArray new];
	__weak typeof(self) weakSelf = self;
	
	[rows addObject:[NCTreeRow rowWithCellIdentifier:@"Cell" configurationHandler:^(__kindof NCTableViewDefaultCell *cell) {
		NSDate* date = [weakSelf.characterSheet.object.eveapi localTimeWithServerTime:weakSelf.characterSheet.object.nextRespecDate];
		
		NSTimeInterval t = [[weakSelf.characterSheet.object.eveapi localTimeWithServerTime:date] timeIntervalSinceNow];
		cell.titleLabel.text = NSLocalizedString(@"NEURAL REMAP AVAILABLE", nil);
		if (t <= 0)
			cell.subtitleLabel.text = NSLocalizedString(@"Now", nil);
		else if (t < 3600 * 24 * 7)
			cell.subtitleLabel.text = [NCTimeIntervalFormatter localizedStringFromTimeInterval:t precision:NCTimeIntervalFormatterPrecisionMinuts];
		else
			cell.subtitleLabel.text = [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle];
		
		cell.iconView.image = nil;
	}]];
	
	[rows addObject:[NCTreeRow rowWithCellIdentifier:@"Cell" configurationHandler:^(__kindof NCTableViewDefaultCell *cell) {
		cell.titleLabel.text = NSLocalizedString(@"BONUS REMAPS AVAILABLE", nil);
		cell.subtitleLabel.text = [NSString stringWithFormat:@"%d", weakSelf.characterSheet.object.freeRespecs];
		cell.iconView.image = nil;
	}]];
	
	
	return [NCTreeSection sectionWithNodeIdentifier:@"NEURAL REMAP" cellIdentifier:@"NCTableViewHeaderCell" title:NSLocalizedString(@"NEURAL REMAP", nil) children:rows];
}

- (NCTreeSection*) implantsSectionWithTypeIDs:(NSArray*) typeIDs {
	NCFetchedCollection<NCDBInvType*>* invTypes = NCDatabase.sharedDatabase.invTypes;
	NCDBInvType* charismaEnhancer = nil;
	NCDBInvType* intelligenceEnhancer = nil;
	NCDBInvType* memoryEnhancer = nil;
	NCDBInvType* perceptionEnhancer = nil;
	NCDBInvType* willpowerEnhancer = nil;
	int charismaBonus = 0;
	int intelligenceBonus = 0;
	int memoryBonus = 0;
	int perceptionBonus = 0;
	int willpowerBonus = 0;
	
	for (id typeID in typeIDs) {
		NCDBInvType* type = invTypes[[typeID integerValue]];
		if (!type)
			continue;
		NCFetchedCollection<NCDBDgmTypeAttribute*>* attributes = type.allAttributes;
		int bonus = 0;
		if ((bonus = attributes[NCCharismaBonusAttributeID].value) > 0) {
			charismaEnhancer = type;
			charismaBonus = bonus;
		}
		else if ((bonus = attributes[NCIntelligenceBonusAttributeID].value) > 0) {
			intelligenceEnhancer = type;
			intelligenceBonus = bonus;
		}
		else if ((bonus = attributes[NCMemoryBonusAttributeID].value) > 0) {
			memoryEnhancer = type;
			memoryBonus = bonus;
		}
		else if ((bonus = attributes[NCPerceptionBonusAttributeID].value) > 0) {
			perceptionEnhancer = type;
			perceptionBonus = bonus;
		}
		else if ((bonus = attributes[NCWillpowerBonusAttributeID].value) > 0) {
			willpowerEnhancer = type;
			willpowerBonus = bonus;
		}
	}
	
	NSMutableArray* rows = [NSMutableArray new];
	
	if (intelligenceEnhancer)
		[rows addObject:[NCTreeRow rowWithCellIdentifier:@"Cell" configurationHandler:^(__kindof NCTableViewDefaultCell *cell) {
			cell.titleLabel.text = intelligenceEnhancer.typeName;
			cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Intelligence +%d", nil), intelligenceBonus];
			cell.iconView.image = (id) intelligenceEnhancer.icon.image.image ?: NCDBEveIcon.defaultTypeIcon.image.image;
		}]];
	
	if (memoryEnhancer)
		[rows addObject:[NCTreeRow rowWithCellIdentifier:@"Cell" configurationHandler:^(__kindof NCTableViewDefaultCell *cell) {
			cell.titleLabel.text = memoryEnhancer.typeName;
			cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Memory +%d", nil), memoryBonus];
			cell.iconView.image = (id) memoryEnhancer.icon.image.image ?: NCDBEveIcon.defaultTypeIcon.image.image;
		}]];

	if (perceptionEnhancer)
		[rows addObject:[NCTreeRow rowWithCellIdentifier:@"Cell" configurationHandler:^(__kindof NCTableViewDefaultCell *cell) {
			cell.titleLabel.text = perceptionEnhancer.typeName;
			cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Perception +%d", nil), perceptionBonus];
			cell.iconView.image = (id) perceptionEnhancer.icon.image.image ?: NCDBEveIcon.defaultTypeIcon.image.image;
		}]];

	if (willpowerEnhancer)
		[rows addObject:[NCTreeRow rowWithCellIdentifier:@"Cell" configurationHandler:^(__kindof NCTableViewDefaultCell *cell) {
			cell.titleLabel.text = willpowerEnhancer.typeName;
			cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Willpower +%d", nil), willpowerBonus];
			cell.iconView.image = (id) willpowerEnhancer.icon.image.image ?: NCDBEveIcon.defaultTypeIcon.image.image;
		}]];

	if (charismaEnhancer)
		[rows addObject:[NCTreeRow rowWithCellIdentifier:@"Cell" configurationHandler:^(__kindof NCTableViewDefaultCell *cell) {
			cell.titleLabel.text = charismaEnhancer.typeName;
			cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Charisma +%d", nil), charismaBonus];
			cell.iconView.image = (id) charismaEnhancer.icon.image.image ?: NCDBEveIcon.defaultTypeIcon.image.image;
		}]];
	if (rows.count == 0)
		[rows addObject:[NCTreeRow rowWithCellIdentifier:@"PlaceholderCell" configurationHandler:^(__kindof NCTableViewDefaultCell *cell) {
			cell.titleLabel.text = NSLocalizedString(@"NO IMPLANTS INSTALLED", nil);
		}]];

	return [NCTreeSection sectionWithNodeIdentifier:@"IMPLANTS" cellIdentifier:@"NCTableViewHeaderCell" title:NSLocalizedString(@"IMPLANTS", nil) children:rows];
}

@end
