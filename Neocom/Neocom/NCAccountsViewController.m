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
@import EVEAPI;

@interface NCAccountsViewController ()<UIViewControllerTransitioningDelegate>
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
	[self.results performFetch:nil];
	self.extraInfo = [NSMutableDictionary new];
	[self.refreshControl beginRefreshing];
	[self reloadWithCachePolicy:NSURLRequestUseProtocolCachePolicy];
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	self.navigationController.transitioningDelegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
	[self configureCell:cell atIndexPath:indexPath];
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

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
	[self reloadWithCachePolicy:NSURLRequestReloadIgnoringCacheData];
}

- (void) reloadWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	NCDataManager* dataManager = [NCDataManager new];
	
	dispatch_group_t dispatchGroup = dispatch_group_create();
	NCProgressHandler* progressHandler;
	progressHandler = [NCProgressHandler progressHandlerForViewController:self withTotalUnitCount:self.results.fetchedObjects.count];
	
	for (NCAccount* account in self.results.fetchedObjects) {
		NSMutableDictionary* info = self.extraInfo[[self.results indexPathForObject:account]];
		NSIndexPath* indexPath = [self.results indexPathForObject:account];
		if (!info)
			self.extraInfo[indexPath] = info = [NSMutableDictionary new];
		
		[progressHandler.progress becomeCurrentWithPendingUnitCount:1];
		NSProgress* progress = [NSProgress progressWithTotalUnitCount:5];
		[progressHandler.progress resignCurrent];

		
		dispatch_group_enter(dispatchGroup);
		[dataManager characterInfoForAccount:account cachePolicy:cachePolicy completionHandler:^(EVECharacterInfo *result, NSError *error, NSManagedObjectID *cacheRecordID) {
			progress.completedUnitCount++;
			if (result)
				info[@"EVECharacterInfo"] = result;
			[self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
			dispatch_group_leave(dispatchGroup);
		}];
		
		dispatch_group_enter(dispatchGroup);
		[dataManager accountStatusForAccount:account cachePolicy:cachePolicy completionHandler:^(EVEAccountStatus *result, NSError *error, NSManagedObjectID *cacheRecordID) {
			progress.completedUnitCount++;
			if (result)
				info[@"EVEAccountStatus"] = result;
			[self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
			dispatch_group_leave(dispatchGroup);
		}];
		
		dispatch_group_enter(dispatchGroup);
		[dataManager skillQueueForAccount:account cachePolicy:cachePolicy completionHandler:^(EVESkillQueue *result, NSError *error, NSManagedObjectID *cacheRecordID) {
			progress.completedUnitCount++;
			if (result)
				info[@"EVESkillQueue"] = result;
			[self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
			dispatch_group_leave(dispatchGroup);
		}];
		
		dispatch_group_enter(dispatchGroup);
		[dataManager imageWithCharacterID:account.characterID preferredSize:CGSizeMake(80, 80) scale:UIScreen.mainScreen.scale cachePolicy:cachePolicy completionBlock:^(UIImage *image, NSError *error) {
			progress.completedUnitCount++;
			if (image)
				info[@"image"] = image;
			[self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
			dispatch_group_leave(dispatchGroup);
		}];
	}
	
	dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
		[self.refreshControl endRefreshing];
		[progressHandler finish];
	});
}

- (void) configureCell:(NCAccountsCell*) cell atIndexPath:(NSIndexPath*) indexPath {
	if (!cell)
		return;
	
	NCAccount* account = [self.results objectAtIndexPath:indexPath];
	EVEAPIKeyInfoCharactersItem* apiKeyCharacterItem = [[account.apiKey.apiKeyInfo.key.characters filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"characterID == %ld", (long) account.characterID]] lastObject];
	
	NSDictionary* info = self.extraInfo[indexPath];
	EVEAccountStatus* accountStatus = info[@"EVEAccountStatus"];
	if (account.eveAPIKey.corporate) {
		
	}
	else {
		EVECharacterInfo* characterInfo = info[@"EVECharacterInfo"];
		EVESkillQueue* skillQueue = info[@"EVESkillQueue"];
		UIImage* image = info[@"image"];
		cell.characterNameLabel.text = characterInfo.characterName ?: apiKeyCharacterItem.characterName;
		cell.corporationLabel.text = characterInfo.corporation ?: @" ";
		cell.characterImageView.image = image;
		cell.spLabel.text = characterInfo ? [NCUnitFormatter localizedStringFromNumber:@(characterInfo.skillPoints) unit:NCUnitSP style:NCUnitFormatterStyleShort] : @" ";
		cell.wealthLabel.text = characterInfo ? [NCUnitFormatter localizedStringFromNumber:@(characterInfo.accountBalance) unit:NCUnitISK style:NCUnitFormatterStyleShort] : @" ";
		cell.skillLabel.text = NSLocalizedString(@"No skills in training", nil);
		cell.skillLabel.textColor = [UIColor lightTextColor];
		cell.trainingTimeLabel.text = @" ";
		cell.trainingProgressView.progress = 0;
		
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
					cell.skillLabel.text = [NSString stringWithFormat:@"%@ %d", type.typeName, firstSkill.level];
					cell.skillLabel.textColor = [UIColor whiteColor];
					cell.trainingTimeLabel.text = [NCTimeIntervalFormatter localizedStringFromTimeInterval:[endTime timeIntervalSinceNow] style:NCTimeIntervalFormatterStyleMinuts];
					cell.trainingProgressView.progress = skill.trainingProgress;
				}
				else {
					cell.skillLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Unknown typeID %d", nil), firstSkill.typeID];
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
