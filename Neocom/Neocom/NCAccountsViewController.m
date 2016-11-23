//
//  NCAccountsViewController.m
//  Neocom
//
//  Created by Artem Shimanski on 14.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCAccountsViewController.h"
#import "NCSlideDownAnimationController.h"
#import "NCSlideDownInteractiveTransition.h"
#import "NCStorage.h"
#import "NCDataManager.h"
#import "NCAccountsCell.h"
#import "NCTimeIntervalFormatter.h"
#import "NCUnitFormatter.h"
#import "NCSkill.h"
#import "NCProgressHandler.h"
#import "NSAttributedString+NC.h"
#import "NCDispatchGroup.h"
#import "NCAPIKeyInfoViewController.h"
#import "NCTableViewBackgroundLabel.h"
#import "NCManagedObjectObserver.h"
#import "NCImageFromDataValueTransformer.h"
#import "ASValueTransformer.h"
@import EVEAPI;

@interface NCAccountsViewController ()<UIViewControllerTransitioningDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic, strong) NSFetchedResultsController* results;
@property (nonatomic, strong) NSMutableDictionary<NSManagedObjectID*, NSMutableDictionary<NSString*, NCCacheRecord*>*>* extraInfo;
@property (nonatomic, strong) NSDateFormatter* dateFormatter;
@property (nonatomic, assign, getter=isInteractive) BOOL interactive;
@end

@implementation NCAccountsViewController

- (void) awakeFromNib {
	[super awakeFromNib];
	//self.navigationController.transitioningDelegate = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.clearsSelectionOnViewWillAppear = NO;
	self.dateFormatter = [NSDateFormatter new];
	self.dateFormatter.timeStyle = NSDateFormatterNoStyle;
	self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;
	
	self.tableView.estimatedRowHeight = self.tableView.rowHeight;
	self.tableView.rowHeight = UITableViewAutomaticDimension;
	self.refreshControl = [UIRefreshControl new];
	[self.refreshControl addTarget:self action:@selector(onRefresh:) forControlEvents:UIControlEventValueChanged];
	
	NSFetchRequest* request = [NCAccount fetchRequest];
	request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]];
	self.results = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:NCStorage.sharedStorage.viewContext sectionNameKeyPath:@"order" cacheName:nil];
	self.results.delegate = self;
	[self.results performFetch:nil];
	self.extraInfo = [NSMutableDictionary new];
	//[self.refreshControl beginRefreshing];
	//[self reloadWithCachePolicy:NSURLRequestUseProtocolCachePolicy];
	
	NSIndexPath* indexPath = NCAccount.currentAccount ? [self.results indexPathForObject:NCAccount.currentAccount] : nil;
	if (indexPath)
		[self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
	
	self.tableView.backgroundView = self.results.fetchedObjects.count == 0 ? [NCTableViewBackgroundLabel labelWithText:NSLocalizedString(@"No Accounts", nil)] : nil;
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	self.navigationController.transitioningDelegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onClose:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCAPIKeyInfoViewController"]) {
		NCAPIKeyInfoViewController* controller = segue.destinationViewController;
		controller.account = [sender object];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.results.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.results.sections[section] numberOfObjects];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCAccount* account = [self.results objectAtIndexPath:indexPath];
	NCAccountsCell* cell = [tableView dequeueReusableCellWithIdentifier:account.eveAPIKey.corporate ? @"CorporationCell" : @"CharacterCell" forIndexPath:indexPath];
	
	NSDictionary* info = self.extraInfo[account.objectID];
	if (!info)
		[self loadDataForCellAtIndexPath:indexPath withCachePolicy:NSURLRequestUseProtocolCachePolicy completionBlock:^(NSDictionary *info, NSError *error) {
		}];
	[self configureCell:cell atIndexPath:indexPath];
    return cell;
}


#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NCAccount.currentAccount = [self.results objectAtIndexPath:indexPath];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (nullable NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewRowAction* deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:NSLocalizedString(@"Delete", nil) handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
		NCAccount* account = [self.results objectAtIndexPath:indexPath];
		NSManagedObjectContext* context = account.managedObjectContext;
		[context deleteObject:account];
		if ([context hasChanges])
			[context save:nil];
	}];
	
	UITableViewRowAction* keyInfoAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:NSLocalizedString(@"API Key Info", nil) handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
		[self performSegueWithIdentifier:@"NCAPIKeyInfoViewController" sender:[tableView cellForRowAtIndexPath:indexPath]];
	}];

	return @[deleteAction, keyInfoAction];
}

#pragma mark - UIScrollViewDelegate

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
	CGFloat bottom = MAX(scrollView.contentSize.height - scrollView.bounds.size.height, 0);
	CGFloat y = scrollView.contentOffset.y - bottom;
	if (y > 40 && !self.transitionCoordinator && scrollView.tracking) {
		self.interactive = YES;
		[self dismissViewControllerAnimated:YES completion:nil];
		self.interactive = NO;
	}
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	[self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
 
	switch(type) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
						  withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
						  withRowAnimation:UITableViewRowAnimationFade];
		default:
			break;
	}
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
    atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath {
 
	UITableView *tableView = self.tableView;
 
	switch(type) {
			
		case NSFetchedResultsChangeInsert:
			[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
							 withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeDelete:
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
							 withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeUpdate:
			[self configureCell:[tableView cellForRowAtIndexPath:indexPath]
					atIndexPath:indexPath];
			break;
			
		case NSFetchedResultsChangeMove:
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
							 withRowAnimation:UITableViewRowAnimationFade];
			[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
							 withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	[self.tableView endUpdates];
	self.tableView.backgroundView = self.results.fetchedObjects.count == 0 ? [NCTableViewBackgroundLabel labelWithText:NSLocalizedString(@"No Accounts", nil)] : nil;

}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UIViewControllerTransitioningDelegate

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
	return nil;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
	return [NCSlideDownAnimationController new];
}

- (nullable id <UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id <UIViewControllerAnimatedTransitioning>)animator {
	return self.interactive ? [[NCSlideDownInteractiveTransition alloc] initWithScrollView:self.tableView] : nil;
}

#pragma mark - Private

- (IBAction) onRefresh:(UIRefreshControl*) sender {
	NCProgressHandler* progressHandler = [NCProgressHandler progressHandlerForViewController:self withTotalUnitCount:self.results.fetchedObjects.count];
	
	NCDispatchGroup* dispatchGroup = [NCDispatchGroup new];
	for (NCAccount* account in self.results.fetchedObjects) {
		[progressHandler.progress becomeCurrentWithPendingUnitCount:1];
		id token = [dispatchGroup enter];
		[self loadDataForCellAtIndexPath:[self.results indexPathForObject:account] withCachePolicy:NSURLRequestReloadIgnoringCacheData completionBlock:^(NSDictionary *info, NSError *error) {
			[dispatchGroup leave:token];
		}];
		[progressHandler.progress resignCurrent];
	}
	
	[dispatchGroup notify:^{
		[self.refreshControl endRefreshing];
		[progressHandler finish];
	}];
}

- (void) loadDataForCellAtIndexPath:(NSIndexPath*) indexPath withCachePolicy:(NSURLRequestCachePolicy) cachePolicy completionBlock:(void(^)(NSDictionary* info, NSError* error)) block {
	NCAccount* account = [self.results objectAtIndexPath:indexPath];
	EVEAPIKey* apiKey = account.eveAPIKey;
	
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:apiKey.corporate ? 4 : 6];
	
	NSMutableDictionary<NSString*, NCCacheRecord*>* info = self.extraInfo[account.objectID];
	/*NCManagedObjectObserver* observer = info[@"observer"];
	if (!info) {
		self.extraInfo[account.objectID] = info = [NSMutableDictionary new];
		info[@"observer"] = observer = [NCManagedObjectObserver observerWithHandler:^(NSSet<NSManagedObjectID *> *updated, NSSet<NSManagedObjectID *> *deleted) {
			NSIndexPath* indexPath = [self.results indexPathForObject:account];
			if (indexPath)
				[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
		}];
	}
	else
		observer = info[@"observer"];*/
	
	
	NCDataManager* dataManager = [NCDataManager defaultManager];
	NCDispatchGroup* dispatchGroup = [NCDispatchGroup new];

	id token = nil;
	__block NSError* lastError = nil;
	
	token = [dispatchGroup enter];
	[dataManager apiKeyInfoWithKeyID:apiKey.keyID vCode:apiKey.vCode completionBlock:^(EVEAPIKeyInfo *apiKeyInfo, NSError *error) {
		progress.completedUnitCount++;
		if (apiKeyInfo) {
			account.apiKey.apiKeyInfo = apiKeyInfo;
			if ([account.managedObjectContext hasChanges])
				[account.managedObjectContext save:nil];
		}
		[dispatchGroup leave:token];
	}];
	
	token = [dispatchGroup enter];
	[dataManager accountStatusForAccount:account cachePolicy:cachePolicy completionHandler:^(EVEAccountStatus *result, NSError *error, NSManagedObjectID *cacheRecordID) {
//		if (cacheRecordID)
//			[observer addObjectID:cacheRecordID];
		
		progress.completedUnitCount++;
		if (cacheRecordID)
			info[@"EVEAccountStatus"] = [NCCache.sharedCache.viewContext objectWithID:cacheRecordID];
		[self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
		[dispatchGroup leave:token];
	}];

	
	if (apiKey.corporate) {
		EVEAPIKeyInfoCharactersItem* character = account.character;
		token = [dispatchGroup enter];
		[dataManager accountBalanceForAccount:account cachePolicy:cachePolicy completionHandler:^(EVEAccountBalance *result, NSError *error, NSManagedObjectID *cacheRecordID) {
			progress.completedUnitCount++;
			if (cacheRecordID)
				info[@"EVEAccountBalance"] = [NCCache.sharedCache.viewContext objectWithID:cacheRecordID];
			[self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
			[dispatchGroup leave:token];
		}];
		
		token = [dispatchGroup enter];
		[dataManager imageWithCorporationID:character.corporationID preferredSize:CGSizeMake(80, 80) scale:UIScreen.mainScreen.scale cachePolicy:cachePolicy completionBlock:^(UIImage *image, NSError *error, NSManagedObjectID *cacheRecordID) {
			progress.completedUnitCount++;
			if (cacheRecordID)
				info[@"image"] = [NCCache.sharedCache.viewContext objectWithID:cacheRecordID];
			[self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
			[dispatchGroup leave:token];
		}];
	}
	else {
		token = [dispatchGroup enter];
		[dataManager characterInfoForAccount:account cachePolicy:cachePolicy completionHandler:^(EVECharacterInfo *result, NSError *error, NSManagedObjectID *cacheRecordID) {
			lastError = error;
			progress.completedUnitCount++;
			if (cacheRecordID)
				info[@"EVECharacterInfo"] = [NCCache.sharedCache.viewContext objectWithID:cacheRecordID];
			[self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
			[dispatchGroup leave:token];
		}];
		
		token = [dispatchGroup enter];
		[dataManager skillQueueForAccount:account cachePolicy:cachePolicy completionHandler:^(EVESkillQueue *result, NSError *error, NSManagedObjectID *cacheRecordID) {
			progress.completedUnitCount++;
			if (cacheRecordID)
				info[@"EVESkillQueue"] = [NCCache.sharedCache.viewContext objectWithID:cacheRecordID];
			[self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
			[dispatchGroup leave:token];
		}];
		
		token = [dispatchGroup enter];
		[dataManager imageWithCharacterID:account.characterID preferredSize:CGSizeMake(80, 80) scale:UIScreen.mainScreen.scale cachePolicy:cachePolicy completionBlock:^(UIImage *image, NSError *error, NSManagedObjectID *cacheRecordID) {
			progress.completedUnitCount++;
			if (cacheRecordID)
				info[@"image"] = [NCCache.sharedCache.viewContext objectWithID:cacheRecordID];
			[self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
			[dispatchGroup leave:token];
		}];

	}
	
	[dispatchGroup notify:^{
		block(info, lastError);
	}];
}

- (void) configureCell:(NCAccountsCell*) cell atIndexPath:(NSIndexPath*) indexPath {
	if (!cell)
		return;
	cell.characterNameLabel.text = @" ";
	cell.characterImageView.image = nil;
	cell.corporationLabel.text = @" ";
	cell.allianceLabel.text = @" ";
	cell.corporationImageView.image = nil;
	cell.allianceImageView.image = nil;
	cell.spLabel.text = @" ";
	cell.wealthLabel.text = @" ";
	cell.locationLabel.text = @" ";
	cell.subscriptionLabel.text = @" ";
	cell.skillLabel.text = @" ";
	cell.trainingTimeLabel.text = @" ";
	cell.trainingProgressView.progress = 0.0;
	cell.skillQueueLabel.text = @" ";
	
	NCAccount* account = [self.results objectAtIndexPath:indexPath];
	cell.object = account;
	
	EVEAPIKeyInfoCharactersItem* apiKeyCharacterItem = account.character;
	
	NSDictionary<NSString*, NCCacheRecord*>* info = self.extraInfo[account.objectID];
	if (!info)
		return;

	NCCacheRecord<EVEAccountStatus*>* accountStatus = info[@"EVEAccountStatus"];
	if (account.eveAPIKey.corporate) {
		[cell.binder bind:@"corporationLabel.text" toObject:account withKeyPath:@"character.corporationName" transformer:nil];
		[cell.binder bind:@"allianceLabel.text" toObject:account withKeyPath:@"character.allianceName" transformer:nil];

		NCCacheRecord<NSData*>* image = info[@"image"];
		[cell.binder bind:@"corporationImageView.image" toObject:image withKeyPath:@"object" transformer:[NCImageFromDataValueTransformer new]];
		
		NCCacheRecord<EVEAccountBalance*>* balance = info[@"EVEAccountBalance"];
		[cell.binder bind:@"wealthLabel.text" toObject:balance withKeyPath:@"object" transformer:[ASValueTransformer valueTransformerWithHandler:^id(EVEAccountBalance* value) {
			double isk = 0;
			for (EVEAccountBalanceItem* account in value.accounts)
				isk += account.balance;
			return [NCUnitFormatter localizedStringFromNumber:@(isk) unit:NCUnitNone style:NCUnitFormatterStyleShort];
		}]];
	}
	else {
		NCCacheRecord<EVECharacterInfo*>* characterInfo = info[@"EVECharacterInfo"];
		ASValueTransformer* appendSpace = [ASValueTransformer valueTransformerWithHandler:^id(id value) {
			return value ?: @" ";
		}];
		
		[cell.binder bind:@"characterNameLabel.text" toObject:characterInfo withKeyPath:@"object.characterName" transformer:appendSpace];
		[cell.binder bind:@"corporationLabel.text" toObject:characterInfo withKeyPath:@"object.corporation" transformer:appendSpace];

		NCCacheRecord<NSData*>* image = info[@"image"];
		[cell.binder bind:@"characterImageView.image" toObject:image withKeyPath:@"object" transformer:[NCImageFromDataValueTransformer new]];

		[cell.binder bind:@"spLabel.text" toObject:characterInfo withKeyPath:@"object.skillPoints" transformer:[ASValueTransformer valueTransformerWithHandler:^id(id value) {
			return [NCUnitFormatter localizedStringFromNumber:value unit:NCUnitNone style:NCUnitFormatterStyleShort] ?: @" ";
		}]];

		[cell.binder bind:@"wealthLabel.text" toObject:characterInfo withKeyPath:@"object.accountBalance" transformer:[ASValueTransformer valueTransformerWithHandler:^id(id value) {
			return [NCUnitFormatter localizedStringFromNumber:value unit:NCUnitNone style:NCUnitFormatterStyleShort] ?: @" ";
		}]];

		[cell.binder bind:@"locationLabel.attributedText" toObject:characterInfo withKeyPath:@"object" transformer:[ASValueTransformer valueTransformerWithHandler:^id(EVECharacterInfo* value) {
			
			if (value.lastKnownLocation && value.shipTypeName) {
				NSMutableAttributedString* s = [NSMutableAttributedString new];
				[s appendAttributedString:[[NSAttributedString alloc] initWithString:value.shipTypeName attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}]];
				[s appendAttributedString:[[NSAttributedString alloc] initWithString:[@", " stringByAppendingString:value.lastKnownLocation] attributes:@{NSForegroundColorAttributeName:[UIColor lightTextColor]}]];
				return s;
			}
			else if (value.lastKnownLocation)
				return [[NSAttributedString alloc] initWithString:value.lastKnownLocation attributes:@{NSForegroundColorAttributeName:[UIColor lightTextColor]}];
			else if (value.shipName )
				return [[NSAttributedString alloc] initWithString:value.shipTypeName attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
			else
				return [[NSAttributedString alloc] initWithString:@" " attributes:nil];
		}]];
		
		NCCacheRecord<EVESkillQueue*>* skillQueue = info[@"EVESkillQueue"];

		[cell.binder bind:@"skillLabel.attributedText" toObject:skillQueue withKeyPath:@"object" transformer:[ASValueTransformer valueTransformerWithHandler:^id(EVESkillQueue* value) {
			if (value.skillQueue.count > 0) {
				EVESkillQueueItem* firstSkill = value.skillQueue[0];
				NCDBInvType* type = [NCDBInvType invTypesWithManagedObjectContext:NCDatabase.sharedDatabase.viewContext][firstSkill.typeID];
				NCSkill* skill = [[NCSkill alloc] initWithInvType:type skill:firstSkill inQueue:value];
				if (skill)
					return [NSAttributedString attributedStringWithSkillName:type.typeName level:firstSkill.level];
				else
					return [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Unknown typeID %d", nil), firstSkill.typeID] attributes:nil];
			}
			else
				return [[NSAttributedString alloc] initWithString:NSLocalizedString(@"No skills in training", nil) attributes:nil];
		}]];
		
		[cell.binder bind:@"skillLabel.textColor" toObject:characterInfo withKeyPath:@"object.accountBalance" transformer:[ASValueTransformer valueTransformerWithHandler:^id(EVESkillQueue* value) {
			return value.skillQueue.count > 0 ? [UIColor whiteColor] : [UIColor lightTextColor];
		}]];

		
		[cell.binder bind:@"trainingTimeLabel.textColor" toObject:skillQueue withKeyPath:@"object" transformer:[ASValueTransformer valueTransformerWithHandler:^id(EVESkillQueue* value) {
			if (value.skillQueue.count > 0) {
				EVESkillQueueItem* firstSkill = value.skillQueue[0];
				NCDBInvType* type = [NCDBInvType invTypesWithManagedObjectContext:NCDatabase.sharedDatabase.viewContext][firstSkill.typeID];
				NCSkill* skill = [[NCSkill alloc] initWithInvType:type skill:firstSkill inQueue:value];
				if (skill) {
					NSDate* endTime = skill.trainingEndDate;
					return [NCTimeIntervalFormatter localizedStringFromTimeInterval:[endTime timeIntervalSinceNow] precision:NCTimeIntervalFormatterPrecisionMinuts];;
				}
				else
					return @" ";
			}
			else
				return @" ";
		}]];

		[cell.binder bind:@"skillQueueLabel.text" toObject:skillQueue withKeyPath:@"object" transformer:[ASValueTransformer valueTransformerWithHandler:^id(EVESkillQueue* value) {
			if (value.skillQueue.count > 0) {
				EVESkillQueueItem* lastSkill = [value.skillQueue lastObject];
				NSDate* endTime = [value.eveapi localTimeWithServerTime:lastSkill.endTime];
				
				return [NSString stringWithFormat:NSLocalizedString(@"%d skills in queue (%@)" , nil), (int) value.skillQueue.count, [NCTimeIntervalFormatter localizedStringFromTimeInterval:[endTime timeIntervalSinceNow] precision:NCTimeIntervalFormatterPrecisionMinuts]];
			}
			else
				return @" ";
		}]];
		
		
		if ([characterInfo isKindOfClass:[NSError class]]) {
			cell.characterNameLabel.text = [(NSError*) characterInfo localizedDescription];
		}
		else {
			EVESkillQueue* skillQueue = info[@"EVESkillQueue"];
			cell.skillLabel.text = skillQueue ? NSLocalizedString(@"No skills in training", nil) : @" ";
			cell.skillLabel.textColor = [UIColor lightTextColor];
			
			
			if (skillQueue) {
				NSArray* skills = [skillQueue.skillQueue sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"queuePosition" ascending:YES]]];
				
				if (skills.count > 0) {
					EVESkillQueueItem* firstSkill = skills[0];
					EVESkillQueueItem* lastSkill = [skills lastObject];
					
					NCDBInvType* type = [NCDBInvType invTypesWithManagedObjectContext:NCDatabase.sharedDatabase.viewContext][firstSkill.typeID];
					NCSkill* skill = [[NCSkill alloc] initWithInvType:type skill:firstSkill inQueue:skillQueue];
					if (skill) {
						NSDate* endTime = skill.trainingEndDate;
						cell.skillLabel.textColor = [UIColor whiteColor];
						cell.skillLabel.attributedText = [NSAttributedString attributedStringWithSkillName:type.typeName level:firstSkill.level];
						cell.trainingTimeLabel.text = [NCTimeIntervalFormatter localizedStringFromTimeInterval:[endTime timeIntervalSinceNow] precision:NCTimeIntervalFormatterPrecisionMinuts];
						cell.trainingProgressView.progress = skill.trainingProgress;
					}
					else {
						cell.skillLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Unknown typeID %d", nil), firstSkill.typeID];
					}
					
					NSDate* endTime = [skillQueue.eveapi localTimeWithServerTime:lastSkill.endTime];
					cell.skillQueueLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d skills in queue (%@)" , nil), (int) skills.count, [NCTimeIntervalFormatter localizedStringFromTimeInterval:[endTime timeIntervalSinceNow] precision:NCTimeIntervalFormatterPrecisionMinuts]];
					;
				}
			}
		}
	}
	
	
	if ([accountStatus isKindOfClass:[EVEAccountStatus class]]) {
		NSDate* paidUntil = [accountStatus.object.eveapi localTimeWithServerTime:accountStatus.object.paidUntil];
		if (paidUntil) {
			NSTimeInterval t = [paidUntil timeIntervalSinceNow];
			if (t > 0)
				cell.subscriptionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ (%@)", nil), [self.dateFormatter stringFromDate:paidUntil], [NCTimeIntervalFormatter localizedStringFromTimeInterval:t precision:NCTimeIntervalFormatterPrecisionDays]];
			else
				cell.subscriptionLabel.text = NSLocalizedString(@"expired", nil);
		}
	}
	else if ([accountStatus isKindOfClass:[NSError class]])
		cell.subscriptionLabel.text = [(NSError*) accountStatus localizedDescription];
}

@end
