//
//  NCJumpClonesViewController.m
//  Neocom
//
//  Created by Artem Shimanski on 22.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCJumpClonesViewController.h"
#import "NCTreeSection.h"
#import "NCTreeRow.h"
#import "NCDataManager.h"
#import "NCManagedObjectObserver.h"
#import "NCProgressHandler.h"
#import "NCTableViewDefaultCell.h"
#import "NCTimeIntervalFormatter.h"
#import "NCCharacterAttributes.h"
#import "NSAttributedString+NC.h"

@interface NCJumpClonesViewController ()
@property (nonatomic, strong) NCManagedObjectObserver* characterSheetObserver;
@property (nonatomic, strong) NSArray<NCTreeSection*>* sections;
@property (nonatomic, strong) EVECharacterSheet* characterSheet;
@property (nonatomic, strong) NSDictionary* locationNames;

@end

@implementation NCJumpClonesViewController

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

- (BOOL) treeController:(nonnull ASTreeController *)treeController isItemExpanded:(nonnull id)item {
	return YES;
}

- (void) treeController:(nonnull ASTreeController *)treeController didSelectCell:(nonnull __kindof UITableViewCell*) cell withItem:(nonnull id)item {
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForCell:cell] animated:YES];
}

#pragma mark - Private

- (void) reloadWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	NCProgressHandler* progressHandler = [NCProgressHandler progressHandlerForViewController:self withTotalUnitCount:2];
	
	NCAccount* account = NCAccount.currentAccount;
	NCDataManager* dataManager = [NCDataManager defaultManager];
	
	[progressHandler.progress becomeCurrentWithPendingUnitCount:1];
	[dataManager characterSheetForAccount:account cachePolicy:cachePolicy completionHandler:^(EVECharacterSheet *result, NSError *error, NSManagedObjectID *cacheRecordID) {
		self.characterSheet = result;
		__weak typeof(self) weakSelf = self;
		self.characterSheetObserver = [NCManagedObjectObserver observerWithObjectID:cacheRecordID block:^(NCManagedObjectObserverAction action) {
			NCCacheRecord* record = [NCCache.sharedCache.viewContext existingObjectWithID:cacheRecordID error:nil];
			if (record.object) {
				weakSelf.characterSheet = record.object;
				[self reloadData];
			}
		}];
		
		
		[progressHandler.progress becomeCurrentWithPendingUnitCount:1];
		[dataManager locationWithLocationIDs:[result.jumpClones valueForKey:@"locationID"] cachePolicy:NSURLRequestUseProtocolCachePolicy completionHandler:^(NSDictionary<NSNumber *,NCLocation *> *result, NSError *error) {
			self.locationNames = result;
			[self.refreshControl endRefreshing];
			[progressHandler finish];
			[self reloadData];
		}];
		[progressHandler.progress resignCurrent];
		
	}];
	[progressHandler.progress resignCurrent];
}

- (IBAction)onRefresh:(id)sender {
	[self reloadWithCachePolicy:NSURLRequestReloadIgnoringCacheData];
}

- (void) reloadData {
	if (!self.characterSheet) {
		self.sections = nil;
	}
	else {
		NSMutableArray* sections = [NSMutableArray new];
		__weak typeof(self) weakSelf = self;

		[sections addObject:[NCTreeRow rowWithCellIdentifier:@"Cell" configurationHandler:^(__kindof NCTableViewDefaultCell *cell) {
			NSDate* date = [[weakSelf.characterSheet.eveapi localTimeWithServerTime:weakSelf.characterSheet.cloneJumpDate] dateByAddingTimeInterval:3600 * 24];
			NSTimeInterval t = [date timeIntervalSinceNow];
			cell.titleLabel.text = NSLocalizedString(@"NEXT CLONE JUMP AVAILABILITY", nil);
			cell.subtitleLabel.text = t > 0 ? [NCTimeIntervalFormatter localizedStringFromTimeInterval:t precision:NCTimeIntervalFormatterPrecisionMinuts] : NSLocalizedString(@"Now", nil);
			cell.iconView.image = nil;
		}]];
		
		[sections addObjectsFromArray:[self jumpClones]];
		self.sections = sections;
	}
	[self.treeController reloadData];
}

- (NSArray*) jumpClones {
	NSMutableArray* rows = [NSMutableArray new];
	__weak typeof(self) weakSelf = self;
	
	for (EVECharacterSheetJumpClone* jumpClone in weakSelf.characterSheet.jumpClones) {
		NCLocation* location = self.locationNames[@(jumpClone.locationID)];
		NSArray* implats = [self.characterSheet.jumpCloneImplants filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"jumpCloneID == %d", jumpClone.jumpCloneID]];
		[rows addObject:[NCTreeSection sectionWithNodeIdentifier:[NSString stringWithFormat:@"%d", jumpClone.jumpCloneID] cellIdentifier:@"NCTableViewHeaderCell" attributedTitle:[location.displayName uppercaseString] children:[self implantsWithTypeIDs:[implats valueForKey:@"typeID"]]]];
	}
	return rows;
}


- (NSArray*) implantsWithTypeIDs:(NSArray*) typeIDs {
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
	
	return rows;
}

@end
