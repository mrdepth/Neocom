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
#import "NCDefaultTableViewCell.h"
#import "NCUnitFormatter.h"
#import "NCCharacterAttributes.h"
#import "NCDispatchGroup.h"

@interface NCCharacterSheetViewControllerRow : NSObject
@property (nonatomic, strong) NSString* cellIdentifier;
@property (nonatomic, strong) void (^configurationBlock) (__kindof UITableViewCell* cell);
@end

@implementation NCCharacterSheetViewControllerRow

- (instancetype) initWithCellIdentifier:(NSString*) cellIdentifier configurationBlock:(void(^)(__kindof UITableViewCell* cell)) block {
	if (self = [super init]) {
		self.cellIdentifier = cellIdentifier;
		self.configurationBlock = block;
	}
	return self;
}

@end

@interface NCCharacterSheetViewControllerSection : NSObject
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSArray* rows;
@end

@implementation NCCharacterSheetViewControllerSection

- (instancetype) initWithTitle:(NSString*) title rows:(NSArray*) rows {
	if (self = [super init]) {
		self.title = title;
		self.rows = rows;
	}
	return self;
}

@end

@interface NCCharacterSheetViewController ()
@property (nonatomic, strong) NCManagedObjectObserver* characterSheetObserver;
@property (nonatomic, strong) NCManagedObjectObserver* characterInfoObserver;
@property (nonatomic, strong) EVECharacterSheet* characterSheet;
@property (nonatomic, strong) EVECharacterInfo* characterInfo;
@property (nonatomic, strong) UIImage* characterImage;
@property (nonatomic, strong) UIImage* corporationImage;	
@property (nonatomic, strong) UIImage* allianceImage;
@property (nonatomic, strong) NSArray<NCCharacterSheetViewControllerSection*>* sections;
@end

@implementation NCCharacterSheetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.tableView.estimatedRowHeight = self.tableView.rowHeight;
	self.tableView.rowHeight = UITableViewAutomaticDimension;
	self.refreshControl = [UIRefreshControl new];
	[self.refreshControl addTarget:self action:@selector(onRefresh:) forControlEvents:UIControlEventValueChanged];
	
	[self reloadWithCachePolicy:NSURLRequestUseProtocolCachePolicy];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ASTreeControllerDelegate

- (nonnull id)treeController:(nonnull ASTreeController *)treeController child:(NSInteger)index ofItem:(nullable id)item {
	if ([item isKindOfClass:[NCCharacterSheetViewControllerSection class]]) {
		return [(NCCharacterSheetViewControllerSection*) item rows][index];
	}
	else
		return self.sections[index];
}

- (NSInteger) treeController:(nonnull ASTreeController *)treeController numberOfChildrenOfItem:(nullable id)item {
	if ([item isKindOfClass:[NCCharacterSheetViewControllerSection class]])
		return [(NCCharacterSheetViewControllerSection*) item rows].count;
	else if (!item)
		return self.sections.count;
	else
		return 0;
}

- (nonnull NSString*) treeController:(nonnull ASTreeController *)treeController cellIdentifierForItem:(nonnull id) item {
	if ([item isKindOfClass:[NCCharacterSheetViewControllerSection class]])
		return @"NCTableViewHeaderCell";
	else if ([item isKindOfClass:[NCCharacterSheetViewControllerRow class]])
		return [(NCCharacterSheetViewControllerRow*) item cellIdentifier];
	else
		return nil;
}

- (void) treeController:(nonnull ASTreeController *)treeController configureCell:(nonnull __kindof UITableViewCell*) cell withItem:(nonnull id) item {
	if ([item isKindOfClass:[NCCharacterSheetViewControllerSection class]]) {
		NCTableViewHeaderCell* tableHeaderCell = (NCTableViewHeaderCell*) cell;
		tableHeaderCell.titleLabel.text = [(NCCharacterSheetViewControllerSection*) item title];
	}
	else {
		[(NCCharacterSheetViewControllerRow*) item configurationBlock](cell);
	}
}

- (BOOL) treeController:(nonnull ASTreeController *)treeController isItemExpandable:(nonnull id)item {
	return [item isKindOfClass:[NCCharacterSheetViewControllerSection class]];
}

- (BOOL) treeController:(nonnull ASTreeController *)treeController isItemExpanded:(nonnull id)item {
	return YES;
}

- (void) treeController:(nonnull ASTreeController *)treeController didSelectCell:(nonnull __kindof UITableViewCell*) cell withItem:(nonnull id)item {
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForCell:cell] animated:YES];
}

- (CGFloat) treeController:(nonnull ASTreeController *)treeController estimatedHeightForRowWithItem:(nonnull id) item {
	return -1;
}

#pragma mark - Private

- (void) reloadWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	NCProgressHandler* progressHandler = [NCProgressHandler progressHandlerForViewController:self withTotalUnitCount:2];
	
	NCAccount* account = NCAccount.currentAccount;
	NCDataManager* dataManager = [NCDataManager defaultManager];
	NCDispatchGroup* dispatchGroup = [NCDispatchGroup new];
	
	id token = [dispatchGroup enter];
	[progressHandler.progress becomeCurrentWithPendingUnitCount:1];
	[dataManager characterSheetForAccount:account cachePolicy:cachePolicy completionHandler:^(EVECharacterSheet *result, NSError *error, NSManagedObjectID *cacheRecordID) {
		self.characterSheet = result;
		[self reloadImagesWithCachePolicy:cachePolicy];
		__weak typeof(self) weakSelf = self;
		self.characterSheetObserver = [NCManagedObjectObserver observerWithObjectID:cacheRecordID block:^(NCManagedObjectObserverAction action) {
			NCCacheRecord* record = [NCCache.sharedCache.viewContext existingObjectWithID:cacheRecordID error:nil];
			if (record.object) {
				weakSelf.characterSheet = record.object;
				[self reloadImagesWithCachePolicy:NSURLRequestUseProtocolCachePolicy];
				[self reloadData];
			}
		}];
		[dispatchGroup leave:token];
	}];
	[progressHandler.progress resignCurrent];
	
	token = [dispatchGroup enter];
	[progressHandler.progress becomeCurrentWithPendingUnitCount:1];
	[dataManager characterInfoForAccount:account cachePolicy:cachePolicy completionHandler:^(EVECharacterInfo *result, NSError *error, NSManagedObjectID *cacheRecordID) {
		self.characterInfo = result;
		__weak typeof(self) weakSelf = self;
		self.characterInfoObserver = [NCManagedObjectObserver observerWithObjectID:cacheRecordID block:^(NCManagedObjectObserverAction action) {
			NCCacheRecord* record = [NCCache.sharedCache.viewContext existingObjectWithID:cacheRecordID error:nil];
			if (record.object) {
				weakSelf.characterInfo = record.object;
				[self reloadData];
			}
		}];
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
	
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:self.characterSheet.allianceID ? 3 : 2];
	NCDataManager* dataManager = [NCDataManager defaultManager];
	[progress becomeCurrentWithPendingUnitCount:progress.totalUnitCount];
	[dataManager imageWithCharacterID:self.characterSheet.characterID preferredSize:CGSizeMake(512, 512) scale:UIScreen.mainScreen.scale cachePolicy:cachePolicy completionBlock:^(UIImage *image, NSError *error) {
		self.characterImage = image;
		[self.tableView reloadData];
	}];
	
	[dataManager imageWithCorporationID:self.characterSheet.corporationID preferredSize:CGSizeMake(32, 32) scale:UIScreen.mainScreen.scale cachePolicy:cachePolicy completionBlock:^(UIImage *image, NSError *error) {
		self.corporationImage = image;
		[self.tableView reloadData];
	}];
	
	if (self.characterSheet.allianceID)
		[dataManager imageWithAllianceID:self.characterSheet.allianceID preferredSize:CGSizeMake(32, 32) scale:UIScreen.mainScreen.scale cachePolicy:cachePolicy completionBlock:^(UIImage *image, NSError *error) {
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
		[sections addObject:[self implantsSectionWithTypeIDs:[self.characterSheet.implants valueForKey:@"typeID"]]];
		self.sections = sections;
	}
	[self.treeController reloadData];
}

- (NCCharacterSheetViewControllerSection*) bioSection {
	NSMutableArray* rows = [NSMutableArray new];
	__weak typeof(self) weakSelf = self;
	
	[rows addObject:[[NCCharacterSheetViewControllerRow alloc] initWithCellIdentifier:@"PortraitCell" configurationBlock:^(NCDefaultTableViewCell* cell) {
		cell.iconView.image = weakSelf.characterImage;
	}]];
	
	[rows addObject:[[NCCharacterSheetViewControllerRow alloc] initWithCellIdentifier:@"Cell" configurationBlock:^(__kindof NCDefaultTableViewCell *cell) {
		cell.titleLabel.text = NSLocalizedString(@"CORPORATION", nil);
		cell.subtitleLabel.text = weakSelf.characterSheet.corporationName;
		cell.iconView.image = weakSelf.corporationImage;
	}]];
	
	if (self.characterSheet.allianceID)
		[rows addObject:[[NCCharacterSheetViewControllerRow alloc] initWithCellIdentifier:@"Cell" configurationBlock:^(__kindof NCDefaultTableViewCell *cell) {
			cell.titleLabel.text = NSLocalizedString(@"ALLIANCE", nil);
			cell.subtitleLabel.text = weakSelf.characterSheet.allianceName;
			cell.iconView.image = weakSelf.allianceImage;
		}]];
	
	[rows addObject:[[NCCharacterSheetViewControllerRow alloc] initWithCellIdentifier:@"Cell" configurationBlock:^(__kindof NCDefaultTableViewCell *cell) {
		cell.titleLabel.text = NSLocalizedString(@"DATE OF BIRTH", nil);
		cell.subtitleLabel.text = [NSDateFormatter localizedStringFromDate:weakSelf.characterSheet.DoB dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle];
		cell.iconView.image = nil;
	}]];

	[rows addObject:[[NCCharacterSheetViewControllerRow alloc] initWithCellIdentifier:@"Cell" configurationBlock:^(__kindof NCDefaultTableViewCell *cell) {
		cell.titleLabel.text = NSLocalizedString(@"BLOODLINE", nil);
		cell.subtitleLabel.text = [NSString stringWithFormat:@"%@ / %@ / %@", weakSelf.characterSheet.race, weakSelf.characterSheet.bloodLine, weakSelf.characterSheet.ancestry];
		cell.iconView.image = nil;
	}]];

	return [[NCCharacterSheetViewControllerSection alloc] initWithTitle:NSLocalizedString(@"BIO", nil) rows:rows];
}

- (NCCharacterSheetViewControllerSection*) accountSection {
	NSMutableArray* rows = [NSMutableArray new];
	__weak typeof(self) weakSelf = self;
	
	[rows addObject:[[NCCharacterSheetViewControllerRow alloc] initWithCellIdentifier:@"Cell" configurationBlock:^(__kindof NCDefaultTableViewCell *cell) {
		cell.titleLabel.text = NSLocalizedString(@"BALANCE", nil);
		cell.subtitleLabel.text = [NCUnitFormatter localizedStringFromNumber:@(weakSelf.characterSheet.balance) unit:NCUnitISK style:NCUnitFormatterStyleFull];
		cell.iconView.image = nil;
	}]];

	return [[NCCharacterSheetViewControllerSection alloc] initWithTitle:NSLocalizedString(@"ACCOUNT", nil) rows:rows];
}

- (NCCharacterSheetViewControllerSection*) skillsSection {
	NSMutableArray* rows = [NSMutableArray new];
	__weak typeof(self) weakSelf = self;
	
	if (self.characterInfo && self.characterSheet)
		[rows addObject:[[NCCharacterSheetViewControllerRow alloc] initWithCellIdentifier:@"Cell" configurationBlock:^(__kindof NCDefaultTableViewCell *cell) {
			cell.titleLabel.text = NSLocalizedString(@"SKILL POINTS", nil);
			cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ (%d skills)", nil), [NCUnitFormatter localizedStringFromNumber:@(weakSelf.characterInfo.skillPoints) unit:NCUnitNone style:NCUnitFormatterStyleFull], (int) weakSelf.characterSheet.skills.count];
			cell.iconView.image = nil;
		}]];
	
	if (self.characterSheet.freeSkillPoints > 0)
		[rows addObject:[[NCCharacterSheetViewControllerRow alloc] initWithCellIdentifier:@"Cell" configurationBlock:^(__kindof NCDefaultTableViewCell *cell) {
			cell.titleLabel.text = NSLocalizedString(@"UNALLOCATED SKILL POINTS", nil);
			cell.subtitleLabel.text = [NCUnitFormatter localizedStringFromNumber:@(weakSelf.characterSheet.freeSkillPoints) unit:NCUnitNone style:NCUnitFormatterStyleFull];
			cell.iconView.image = nil;
		}]];
	
	return [[NCCharacterSheetViewControllerSection alloc] initWithTitle:NSLocalizedString(@"SKILLS", nil) rows:rows];
}


- (NCCharacterSheetViewControllerSection*) implantsSectionWithTypeIDs:(NSArray*) typeIDs {
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
		[rows addObject:[[NCCharacterSheetViewControllerRow alloc] initWithCellIdentifier:@"Cell" configurationBlock:^(__kindof NCDefaultTableViewCell *cell) {
			cell.titleLabel.text = intelligenceEnhancer.typeName;
			cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Intelligence +%d", nil), intelligenceBonus];
			cell.iconView.image = (id) intelligenceEnhancer.icon.image.image ?: NCDBEveIcon.defaultTypeIcon.image.image;
		}]];
	
	if (memoryEnhancer)
		[rows addObject:[[NCCharacterSheetViewControllerRow alloc] initWithCellIdentifier:@"Cell" configurationBlock:^(__kindof NCDefaultTableViewCell *cell) {
			cell.titleLabel.text = memoryEnhancer.typeName;
			cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Memory +%d", nil), memoryBonus];
			cell.iconView.image = (id) memoryEnhancer.icon.image.image ?: NCDBEveIcon.defaultTypeIcon.image.image;
		}]];

	if (perceptionEnhancer)
		[rows addObject:[[NCCharacterSheetViewControllerRow alloc] initWithCellIdentifier:@"Cell" configurationBlock:^(__kindof NCDefaultTableViewCell *cell) {
			cell.titleLabel.text = perceptionEnhancer.typeName;
			cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Perception +%d", nil), perceptionBonus];
			cell.iconView.image = (id) perceptionEnhancer.icon.image.image ?: NCDBEveIcon.defaultTypeIcon.image.image;
		}]];

	if (willpowerEnhancer)
		[rows addObject:[[NCCharacterSheetViewControllerRow alloc] initWithCellIdentifier:@"Cell" configurationBlock:^(__kindof NCDefaultTableViewCell *cell) {
			cell.titleLabel.text = willpowerEnhancer.typeName;
			cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Willpower +%d", nil), willpowerBonus];
			cell.iconView.image = (id) willpowerEnhancer.icon.image.image ?: NCDBEveIcon.defaultTypeIcon.image.image;
		}]];

	if (charismaEnhancer)
		[rows addObject:[[NCCharacterSheetViewControllerRow alloc] initWithCellIdentifier:@"Cell" configurationBlock:^(__kindof NCDefaultTableViewCell *cell) {
			cell.titleLabel.text = charismaEnhancer.typeName;
			cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Charisma +%d", nil), charismaBonus];
			cell.iconView.image = (id) charismaEnhancer.icon.image.image ?: NCDBEveIcon.defaultTypeIcon.image.image;
		}]];
	if (rows.count == 0)
		[rows addObject:[[NCCharacterSheetViewControllerRow alloc] initWithCellIdentifier:@"PlaceholderCell" configurationBlock:^(__kindof NCDefaultTableViewCell *cell) {
			cell.titleLabel.text = NSLocalizedString(@"NO IMPLANTS", nil);
		}]];

	return [[NCCharacterSheetViewControllerSection alloc] initWithTitle:NSLocalizedString(@"IMPLANTS", nil) rows:rows];
}

@end
