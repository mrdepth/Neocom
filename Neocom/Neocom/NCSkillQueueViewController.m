//
//  NCSkillQueueViewController.m
//  Neocom
//
//  Created by Artem Shimanski on 22.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCSkillQueueViewController.h"
#import "NCTreeSection.h"
#import "NCTreeRow.h"
#import "NCCache.h"
#import "NCDatabase.h"
#import "NCStorage.h"
#import "NCTableViewHeaderCell.h"
#import "ASBinder.h"
#import "NCManagedObjectObserver.h"
#import "NCSkill.h"
#import "NCProgressHandler.h"
#import "NCDataManager.h"
#import "NCDispatchGroup.h"
#import "NCTableViewSkillCell.h"
#import "NCUnitFormatter.h"
#import "NCTimeIntervalFormatter.h"
#import "NCTrainingQueue.h"
#import "NSString+NC.h"

@interface NSArray(NC)

@end

@implementation NSArray(NC)

- (void) transitionTo:(NSArray*) to handler:(void(^)(NSInteger oldIndex, NSInteger newIndex, NSFetchedResultsChangeType changeType)) handler {
	NSArray* from = self;
	NSInteger n = from.count;
	NSMutableArray* arr = [from mutableCopy];
	
	for (NSInteger i = n - 1; i >= 0; i--) {
		NSInteger j = [to indexOfObject:from[i]];
		if (j == NSNotFound) {
			handler(i, NSNotFound, NSFetchedResultsChangeDelete);
			[arr removeObjectAtIndex:i];
		}
	}
	
	n = to.count;
	for (NSInteger i = 0; i < n; i++) {
		id obj = to[i];
		NSInteger j = [arr indexOfObject:obj];
		if (j == NSNotFound) {
			handler(NSNotFound, i, NSFetchedResultsChangeInsert);
			[arr insertObject:obj atIndex:i];
		}
		else if (j != i)
			handler([from indexOfObject:obj], i, NSFetchedResultsChangeMove);
		else
			handler([from indexOfObject:obj], i, NSFetchedResultsChangeUpdate);
	}
}

@end


@import EVEAPI;

@interface NCSkillQueueRow : NCTreeRow
@property (nonatomic, strong) NCSkill* skill;
@end

@implementation NCSkillQueueRow

- (id) initWithSkill:(NCSkill*) skill {
	if (self = [super initWithNodeIdentifier:nil cellIdentifier:@"NCTableViewSkillCell"]) {
		self.skill = skill;
	}
	return self;
}

- (BOOL) isEqual:(id)object {
	return [self.skill isEqual:[object skill]];
}

- (NSUInteger) hash {
	return self.skill.hash;
}

- (void) configure:(__kindof UITableViewCell *)tableViewCell {
	NCTableViewSkillCell* cell = tableViewCell;
	cell.titleLabel.text = [NSString stringWithFormat:@"%@ (x%d)", self.skill.typeName, self.skill.rank];
	cell.levelLabel.text = [NSString stringWithFormat:NSLocalizedString(@"LEVEL %@", nil), [NSString stringWithRomanNumber:MIN(self.skill.level + 1, 5)]];
	cell.progressView.progress = self.skill.trainingProgress;
	cell.spLabel.text = [NSString stringWithFormat:@"%@ / %@",
						 [NCUnitFormatter localizedStringFromNumber:@(self.skill.skillPoints) unit:NCUnitNone style:NCUnitFormatterStyleFull],
						 [NCUnitFormatter localizedStringFromNumber:@([self.skill skillPointsAtLevel:self.skill.level + 1]) unit:NCUnitSP style:NCUnitFormatterStyleFull]];
	cell.trainingTimeLabel.text = [NCTimeIntervalFormatter localizedStringFromTimeInterval:MAX([self.skill.trainingEndDate timeIntervalSinceNow], 0) precision:NCTimeIntervalFormatterPrecisionMinuts];
}

@end

@interface NCSkillQueueSection : NCTreeSection
@property (nonatomic, strong) NCCacheRecord<EVESkillQueue*>* skillQueue;
@end

@implementation NCSkillQueueSection

- (instancetype) initWithSkillQueue:(NCCacheRecord<EVESkillQueue*>*) skillQueue {
	if (self = [super initWithNodeIdentifier:@"SkillQueue" cellIdentifier:@"NCTableViewHeaderCell"]) {
		self.skillQueue = skillQueue;
		[NCManagedObjectObserver observerWithObjectID:skillQueue.data.objectID handler:^(NSSet<NSManagedObjectID *> *updated, NSSet<NSManagedObjectID *> *deleted) {
			NSMutableArray<NCSkillQueueRow*>* from = [self mutableArrayValueForKey:@"children"];
			
			EVESkillQueue* queue = skillQueue.object;
			
			NCFetchedCollection<NCDBInvType*>* invTypes = NCDatabase.sharedDatabase.invTypes;
			NSMutableArray* to = [NSMutableArray new];
			for (EVESkillQueueItem* item in queue.skillQueue) {
				NCDBInvType* type = invTypes[item.typeID];
				NCSkill* skill = [[NCSkill alloc] initWithInvType:type skill:item inQueue:queue];
				if (type)
					[to addObject:[[NCSkillQueueRow alloc] initWithSkill:skill]];
			}
			
			[[from copy] transitionTo:to handler:^(NSInteger oldIndex, NSInteger newIndex, NSFetchedResultsChangeType changeType) {
				switch (changeType) {
					case NSFetchedResultsChangeInsert:
						[from insertObject:to[newIndex] atIndex:newIndex];
						break;
					case NSFetchedResultsChangeDelete:
						[from removeObjectAtIndex:oldIndex];
						break;
					case NSFetchedResultsChangeMove:
						[from removeObjectAtIndex:oldIndex];
						[from insertObject:to[newIndex] atIndex:newIndex];
						break;
					default:
						break;
				}
			}];
		}];
		
		EVESkillQueue* queue = skillQueue.object;
		
		NCFetchedCollection<NCDBInvType*>* invTypes = NCDatabase.sharedDatabase.invTypes;
		NSMutableArray* rows = [NSMutableArray new];
		for (EVESkillQueueItem* item in queue.skillQueue) {
			NCDBInvType* type = invTypes[item.typeID];
			NCSkill* skill = [[NCSkill alloc] initWithInvType:type skill:item inQueue:queue];
			if (type)
				[rows addObject:[[NCSkillQueueRow alloc] initWithSkill:skill]];
		}
		self.children = rows;
	}
	return self;
}

- (void) configure:(__kindof UITableViewCell *)tableViewCell {
	NCTableViewHeaderCell* cell = tableViewCell;
	EVESkillQueueItem* lastSkill = [self.skillQueue.object.skillQueue lastObject];
	if (lastSkill) {
		NSDate* endDate = [self.skillQueue.object.eveapi localTimeWithServerTime:lastSkill.endTime];
		cell.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ (%d skills)", nil),
								[NCTimeIntervalFormatter localizedStringFromTimeInterval:MAX([endDate timeIntervalSinceNow], 0) precision:NCTimeIntervalFormatterPrecisionMinuts],
								(int) self.skillQueue.object.skillQueue.count];
	}
	else
		cell.titleLabel.text = NSLocalizedString(@"No skills in training", nil);
}

@end




@interface NCSkillQueueViewController ()
@property (nonatomic, strong) NSArray<NCSkillQueueSection*>* sections;
@end

@implementation NCSkillQueueViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.tableView.estimatedRowHeight = self.tableView.rowHeight;
	self.tableView.rowHeight = UITableViewAutomaticDimension;
	self.refreshControl = [UIRefreshControl new];
	[self.refreshControl addTarget:self action:@selector(onRefresh:) forControlEvents:UIControlEventValueChanged];
	
	self.treeController.childrenKeyPath = @"children";
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
    // Dispose of any resources that can be recreated.
}

#pragma mark - ASTreeControllerDelegate

- (nonnull NSString*) treeController:(nonnull ASTreeController *)treeController cellIdentifierForItem:(nonnull NCTreeNode*) item {
	return item.cellIdentifier;
}

- (void) treeController:(nonnull ASTreeController *)treeController configureCell:(nonnull __kindof UITableViewCell*) cell withItem:(nonnull NCTreeNode*) item {
	[item configure:cell];
}

#pragma mark - Private

- (void) reloadWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	NCProgressHandler* progressHandler = [NCProgressHandler progressHandlerForViewController:self withTotalUnitCount:2];
	
	NCAccount* account = NCAccount.currentAccount;
	NCDataManager* dataManager = [NCDataManager defaultManager];
	
	
	[dataManager skillQueueForAccount:account cachePolicy:cachePolicy completionHandler:^(EVESkillQueue *result, NSError *error, NSManagedObjectID *cacheRecordID) {
		[progressHandler finish];
		NCSkillQueueSection* section = [[NCSkillQueueSection alloc] initWithSkillQueue:[NCCache.sharedCache.viewContext objectWithID:cacheRecordID]];
		[self.refreshControl endRefreshing];
		self.sections = @[section];
		self.treeController.content = self.sections;
		[self.treeController reloadData];
	}];
}

- (IBAction)onRefresh:(id)sender {
	[self reloadWithCachePolicy:NSURLRequestReloadIgnoringCacheData];
}

@end
