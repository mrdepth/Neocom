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
@import EVEAPI;

@interface NCAccountsViewController ()<UIViewControllerTransitioningDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic, strong) NSFetchedResultsController* results;
@property (nonatomic, strong) NSMutableDictionary* extraInfo;
@property (nonatomic, strong) NSDateFormatter* dateFormatter;
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
	self.tableView.refreshControl = [UIRefreshControl new];
	[self.tableView.refreshControl addTarget:self action:@selector(onRefresh:) forControlEvents:UIControlEventValueChanged];
	
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.results.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.results.sections[section] numberOfObjects];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCAccountsCell* cell = [tableView dequeueReusableCellWithIdentifier:@"CharacterCell" forIndexPath:indexPath];
	
	NSDictionary* info = self.extraInfo[indexPath];
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
		
	}];

	return @[deleteAction, keyInfoAction];
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
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UIScrollViewDelegate

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
	CGFloat bottom = MAX(scrollView.contentSize.height - scrollView.bounds.size.height, 0);
	CGFloat y = scrollView.contentOffset.y - bottom;
	if (y > 40 && !self.transitionCoordinator && scrollView.tracking)
		[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIViewControllerTransitioningDelegate

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
	return nil;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
	return [NCSlideDownAnimationController new];
}

- (nullable id <UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id <UIViewControllerAnimatedTransitioning>)animator {
	return self.tableView.tracking ? [[NCSlideDownInteractiveTransition alloc] initWithScrollView:self.tableView] : nil;
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
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:5];
	
	NSMutableDictionary* info = self.extraInfo[indexPath];
	if (!info)
		self.extraInfo[indexPath] = info = [NSMutableDictionary new];
	
	
	NCDataManager* dataManager = [NCDataManager defaultManager];
	NCDispatchGroup* dispatchGroup = [NCDispatchGroup new];

	id token = nil;
	
	token = [dispatchGroup enter];
	__block NSError* lastError = nil;
	[dataManager characterInfoForAccount:account cachePolicy:cachePolicy completionHandler:^(EVECharacterInfo *result, NSError *error, NSManagedObjectID *cacheRecordID) {
		lastError = error;
		progress.completedUnitCount++;
		if (result)
			info[@"EVECharacterInfo"] = result;
		else if (error)
			info[@"EVECharacterInfo"] = error;
		[self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
		[dispatchGroup leave:token];
	}];
	
	token = [dispatchGroup enter];
	[dataManager accountStatusForAccount:account cachePolicy:cachePolicy completionHandler:^(EVEAccountStatus *result, NSError *error, NSManagedObjectID *cacheRecordID) {
		progress.completedUnitCount++;
		if (result)
			info[@"EVEAccountStatus"] = result;
		[self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
		[dispatchGroup leave:token];
	}];
	
	token = [dispatchGroup enter];
	[dataManager skillQueueForAccount:account cachePolicy:cachePolicy completionHandler:^(EVESkillQueue *result, NSError *error, NSManagedObjectID *cacheRecordID) {
		progress.completedUnitCount++;
		if (result)
			info[@"EVESkillQueue"] = result;
		[self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
		[dispatchGroup leave:token];
	}];
	
	token = [dispatchGroup enter];
	[dataManager imageWithCharacterID:account.characterID preferredSize:CGSizeMake(80, 80) scale:UIScreen.mainScreen.scale cachePolicy:cachePolicy completionBlock:^(UIImage *image, NSError *error) {
		progress.completedUnitCount++;
		if (image)
			info[@"image"] = image;
		[self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
		[dispatchGroup leave:token];
	}];
	
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
	
	NCAccount* account = [self.results objectAtIndexPath:indexPath];
	cell.object = account;
	
	EVEAPIKeyInfoCharactersItem* apiKeyCharacterItem = account.character;
	
	NSDictionary* info = self.extraInfo[indexPath];
	if (!info)
		return;

	EVEAccountStatus* accountStatus = info[@"EVEAccountStatus"];
	if (account.eveAPIKey.corporate) {
		
	}
	else {
		EVECharacterInfo* characterInfo = info[@"EVECharacterInfo"];
		if ([characterInfo isKindOfClass:[NSError class]]) {
			cell.characterNameLabel.text = [(NSError*) characterInfo localizedDescription];
		}
		else {
			EVESkillQueue* skillQueue = info[@"EVESkillQueue"];
			UIImage* image = info[@"image"];
			cell.characterNameLabel.text = characterInfo.characterName ?: apiKeyCharacterItem.characterName;
			cell.corporationLabel.text = characterInfo.corporation ?: @" ";
			cell.characterImageView.image = image;
			cell.spLabel.text = characterInfo ? [NCUnitFormatter localizedStringFromNumber:@(characterInfo.skillPoints) unit:NCUnitSP style:NCUnitFormatterStyleShort] : @" ";
			cell.wealthLabel.text = characterInfo ? [NCUnitFormatter localizedStringFromNumber:@(characterInfo.accountBalance) unit:NCUnitISK style:NCUnitFormatterStyleShort] : @" ";
			cell.skillLabel.text = skillQueue ? NSLocalizedString(@"No skills in training", nil) : @" ";
			cell.skillLabel.textColor = [UIColor lightTextColor];
			
			if (characterInfo.lastKnownLocation && characterInfo.shipTypeName) {
				NSMutableAttributedString* s = [NSMutableAttributedString new];
				[s appendAttributedString:[[NSAttributedString alloc] initWithString:characterInfo.shipTypeName attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}]];
				[s appendAttributedString:[[NSAttributedString alloc] initWithString:[@", " stringByAppendingString:characterInfo.lastKnownLocation] attributes:@{NSForegroundColorAttributeName:[UIColor lightTextColor]}]];
				cell.locationLabel.attributedText = s;
			}
			else if (characterInfo.lastKnownLocation) {
				cell.locationLabel.attributedText = [[NSAttributedString alloc] initWithString:characterInfo.lastKnownLocation attributes:@{NSForegroundColorAttributeName:[UIColor lightTextColor]}];
			}
			else if (characterInfo.shipName ) {
				cell.locationLabel.attributedText = [[NSAttributedString alloc] initWithString:characterInfo.shipTypeName attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
			}
			else {
				cell.locationLabel.text = @" ";
			}
			
			if (skillQueue) {
				NSArray* skills = [skillQueue.skillQueue filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"queuePosition == 0"]];
				
				if (skills.count > 0) {
					EVESkillQueueItem* firstSkill = skills[0];
					
					NCDBInvType* type = [NCDBInvType invTypesWithManagedObjectContext:NCDatabase.sharedDatabase.viewContext][firstSkill.typeID];
					NCSkill* skill = [[NCSkill alloc] initWithInvType:type skill:firstSkill inQueue:skillQueue];
					if (skill) {
						NSDate* endTime = skill.trainingEndDate;
						cell.skillLabel.textColor = [UIColor whiteColor];
						cell.skillLabel.attributedText = [NSAttributedString attributedStringWithSkillName:type.typeName level:firstSkill.level];
						cell.trainingTimeLabel.text = [NCTimeIntervalFormatter localizedStringFromTimeInterval:[endTime timeIntervalSinceNow] style:NCTimeIntervalFormatterStyleMinuts];
						cell.trainingProgressView.progress = skill.trainingProgress;
					}
					else {
						cell.skillLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Unknown typeID %d", nil), firstSkill.typeID];
					}
				}
			}
		}
	}
	
	
	NSDate* paidUntil = [accountStatus.eveapi localTimeWithServerTime:accountStatus.paidUntil];
	if (paidUntil) {
		NSTimeInterval t = [paidUntil timeIntervalSinceNow];
		if (t > 0)
			cell.subscriptionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ (%@)", nil), [self.dateFormatter stringFromDate:paidUntil], [NCTimeIntervalFormatter localizedStringFromTimeInterval:t style:NCTimeIntervalFormatterStyleDays]];
		else
			cell.subscriptionLabel.text = NSLocalizedString(@"expired", nil);
	}
	else
		cell.subscriptionLabel.text = @" ";
}

@end
