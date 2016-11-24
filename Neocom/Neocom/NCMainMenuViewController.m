//
//  NCMainMenuViewController.m
//  Neocom
//
//  Created by Artem Shimanski on 13.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCMainMenuViewController.h"
#import "NCMainMenuHeaderViewController.h"
#import "NCTableViewDefaultCell.h"
#import "NCSlideDownInteractiveTransition.h"
#import "NCSlideDownAnimationController.h"
#import "NCStorage.h"
#import "NCDataManager.h"
#import "NCUnitFormatter.h"
#import "unitily.h"
#import "NCTimeIntervalFormatter.h"
#import "NCAccountsViewController.h"
#import "EVECharacterSheet+NC.h"
#import "ASValueTransformer.h"
@import EVEAPI;

@interface NCMainMenuDetails : NSObject
@property (nonatomic, strong) NCAccount* account;
@property (nonatomic, strong) ASBinder* binder;
@property (nonatomic, strong) NSString* skillPoints;
@property (nonatomic, strong) NSString* skillQueueInfo;
@property (nonatomic, strong) NSString* unreadMails;
@property (nonatomic, strong) NSString* balance;
@property (nonatomic, strong) NSString* jumpClones;

@property (nonatomic, strong) NCCacheRecord<EVECharacterSheet*>* characterSheet;
@property (nonatomic, strong) NCCacheRecord<EVECharacterInfo*>* characterInfo;
@property (nonatomic, strong) NCCacheRecord<EVESkillQueue*>* skillQueue;
@property (nonatomic, strong) NCCacheRecord<EVEAccountBalance*>* accountBalance;

@end

@implementation NCMainMenuDetails

- (id) init {
	if (self = [super init]) {
		self.binder = [[ASBinder alloc] initWithTarget:self];
	}
	return self;
}

- (void) setCharacterSheet:(NCCacheRecord<EVECharacterSheet *> *)characterSheet {
	_characterSheet = characterSheet;
	
	[self.binder bind:@"jumpClones" toObject:characterSheet.data withKeyPath:@"data" transformer:[ASValueTransformer valueTransformerWithHandler:^id(EVECharacterSheet* value) {
		if (value) {
			NSDate* date = [[value.eveapi localTimeWithServerTime:value.cloneJumpDate] dateByAddingTimeInterval:3600 * 24];
			NSTimeInterval t = [date timeIntervalSinceNow];
			return [NSString stringWithFormat:NSLocalizedString(@"Clone jump availability: %@", nil), t > 0 ? [NCTimeIntervalFormatter localizedStringFromTimeInterval:t precision:NCTimeIntervalFormatterPrecisionMinuts] : NSLocalizedString(@"Now", nil)];
		}
		else
			return [characterSheet.error localizedDescription];
	}]];

}

- (void) setCharacterInfo:(NCCacheRecord<EVECharacterInfo *> *)characterInfo {
	_characterInfo = characterInfo;
	[self.binder bind:@"skillPoints" toObject:characterInfo.data withKeyPath:@"data.skillPoints" transformer:[ASValueTransformer valueTransformerWithHandler:^id(id value) {
		return value ? [NCUnitFormatter localizedStringFromNumber:value unit:NCUnitSP style:NCUnitFormatterStyleFull] : [characterInfo.error localizedDescription];
	}]];

	[self.binder bind:@"balance" toObject:characterInfo.data withKeyPath:@"data.accountBalance" transformer:[ASValueTransformer valueTransformerWithHandler:^id(id value) {
		return value ? [NCUnitFormatter localizedStringFromNumber:value unit:NCUnitISK style:NCUnitFormatterStyleFull] : [characterInfo.error localizedDescription];
	}]];
}

- (void) setSkillQueue:(NCCacheRecord<EVESkillQueue *> *)skillQueue {
	_skillQueue = skillQueue;

	[self.binder bind:@"skillQueueInfo" toObject:skillQueue.data withKeyPath:@"data" transformer:[ASValueTransformer valueTransformerWithHandler:^id(EVESkillQueue* value) {
		if (value) {
			if (value.skillQueue.count == 0)
				return NSLocalizedString(@"No skills in training", nil);
			else {
				EVESkillQueueItem* lastSkill = [value.skillQueue lastObject];
				NSDate* endTime = [value.eveapi localTimeWithServerTime:lastSkill.endTime];
				return [NSString stringWithFormat:NSLocalizedString(@"%d skills in queue (%@)" , nil), (int) value.skillQueue.count, [NCTimeIntervalFormatter localizedStringFromTimeInterval:[endTime timeIntervalSinceNow] precision:NCTimeIntervalFormatterPrecisionMinuts]];
				;
			}
		}
		else
			return [skillQueue.error localizedDescription];
	}]];
}

- (void) setAccountBalance:(NCCacheRecord<EVEAccountBalance *> *)accountBalance {
	_accountBalance = accountBalance;
	
	[self.binder bind:@"balance" toObject:accountBalance.data withKeyPath:@"data" transformer:[ASValueTransformer valueTransformerWithHandler:^id(EVEAccountBalance* value) {
		double isk = 0;
		for (EVEAccountBalanceItem* account in value.accounts)
			isk += account.balance;
		return [NCUnitFormatter localizedStringFromNumber:@(isk) unit:NCUnitNone style:NCUnitFormatterStyleShort];
	}]];
}

@end

@interface NCMainMenuViewController ()<UITableViewDataSource, UITableViewDelegate, UIViewControllerTransitioningDelegate>
@property (nonatomic, weak) NCMainMenuHeaderViewController* headerViewController;
@property (nonatomic, assign) CGFloat headerMinHeight;
@property (nonatomic, assign) CGFloat headerMaxHeight;
@property (nonatomic, strong) NSArray<NSArray<NSDictionary<NSString*, id>*>*>* mainMenu;
@property (nonatomic, assign, getter=isInteractive) BOOL interactive;

@property (nonatomic, strong) NCMainMenuDetails* mainMenuDetails;
@end

@implementation NCMainMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.tableView.estimatedRowHeight = self.tableView.rowHeight;
	self.tableView.rowHeight = UITableViewAutomaticDimension;

	[self updateHeader];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentAccountChanged:) name:NCCurrentAccountChangedNotification object:nil];
	[self loadMenu];
}

- (void) viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	//[self.tableView layoutIfNeeded];
	//NSLog(@"viewWillLayoutSubviews");
	CGRect rect = CGRectMake(0, [self.topLayoutGuide length], self.view.bounds.size.width, MAX(self.headerMaxHeight - self.tableView.contentOffset.y, self.headerMinHeight));
	self.headerViewController.view.frame = [self.view convertRect:rect toView:self.tableView];
	self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(rect.size.height, 0, 0, 0);

}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillAppear:animated];
	UIViewController* toVC = [self.transitionCoordinator viewControllerForKey:UITransitionContextToViewControllerKey];
	if (!toVC || toVC == self)
		return;
	if ([toVC isKindOfClass:[UINavigationController class]]) {
		UIViewController* topVC = [(UINavigationController*) toVC topViewController];
		if ([topVC isKindOfClass:[NCAccountsViewController class]])
			return;
	}
	[self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
	[super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
	dispatch_async(dispatch_get_main_queue(), ^{
		self.headerMinHeight = [self.headerViewController.view systemLayoutSizeFittingSize:CGSizeMake(self.view.bounds.size.width, 0) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityDefaultHigh].height;
		self.headerMaxHeight = [self.headerViewController.view systemLayoutSizeFittingSize:CGSizeMake(self.view.bounds.size.width, 0) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;
		CGRect rect = CGRectMake(0, 0, self.view.bounds.size.width, self.headerMaxHeight);
		self.tableView.tableHeaderView.frame = rect;
		
		rect = CGRectMake(0, [self.topLayoutGuide length], self.view.bounds.size.width, MAX(self.headerMaxHeight - self.tableView.contentOffset.y, self.headerMinHeight));
		self.headerViewController.view.frame = [self.view convertRect:rect toView:self.tableView];
		self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(rect.size.height, 0, 0, 0);

	});
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCAccountsViewController"]) {
		segue.destinationViewController.transitioningDelegate = self;
	}
	[super prepareForSegue:segue sender:sender];
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
	return [self.mainMenu count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.mainMenu[section].count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCTableViewDefaultCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	NSDictionary* row = self.mainMenu[indexPath.section][indexPath.row];
	cell.titleLabel.text = row[@"title"];
	NSString* detailsKeyPath = row[@"detailsKeyPath"];
	if (detailsKeyPath)
		[cell.binder bind:@"subtitleLabel.text" toObject:self.mainMenuDetails withKeyPath:detailsKeyPath transformer:nil];
	else
		cell.subtitleLabel.text = nil;
	cell.iconView.image = [UIImage imageNamed:row[@"image"]];
	return cell;
}

- (UIStatusBarStyle) preferredStatusBarStyle {
	return UIStatusBarStyleDefault;
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary* row = self.mainMenu[indexPath.section][indexPath.row];
	NSString* segueIdentifier = row[@"segueIdentifier"];
	if (segueIdentifier) {
		[self performSegueWithIdentifier:segueIdentifier sender:[tableView cellForRowAtIndexPath:indexPath]];
	}
}

#pragma mark - UIScrollViewDelegate

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
	CGRect rect = CGRectMake(0, [self.topLayoutGuide length], self.tableView.bounds.size.width, MAX(self.headerMaxHeight - scrollView.contentOffset.y, self.headerMinHeight));
	self.headerViewController.view.frame = [self.view convertRect:rect toView:self.tableView];
	self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(rect.size.height, 0, 0, 0);
	if (scrollView.contentOffset.y < -50 && !self.transitionCoordinator && scrollView.tracking) {
//		UIViewController* controller = [self.storyboard instantiateViewControllerWithIdentifier:@"NCAccountsViewController"];
//		controller.transitioningDelegate = self;
//		[self presentViewController:controller animated:YES completion:nil];
		self.interactive = YES;
		[self performSegueWithIdentifier:@"NCAccountsViewController" sender:self];
		self.interactive = NO;
	}
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
	
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
	return NO;
}

#pragma mark - UIViewControllerTransitioningDelegate

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
	return [NCSlideDownAnimationController new];
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
	return nil;
}

- (nullable id <UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id <UIViewControllerAnimatedTransitioning>)animator {
	return self.interactive ? [[NCSlideDownInteractiveTransition alloc] initWithScrollView:self.tableView] : nil;
}

- (nullable id <UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id <UIViewControllerAnimatedTransitioning>)animator {
	return nil;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Private

- (void) currentAccountChanged:(NSNotification*) notification {
	[self loadMenu];
	[self.tableView reloadData];
	[self.tableView layoutIfNeeded];
	[self updateHeader];
}

- (void) updateHeader {
	NCAccount* account = NCAccount.currentAccount;
	NSString* identifier;
	if (account)
		identifier = account.eveAPIKey.corporate ? @"NCMainMenuCorporationHeaderViewController" : @"NCMainMenuCharacterHeaderViewController";
	else
		identifier = [[NCStorage.sharedStorage.viewContext executeFetchRequest:[NCAccount fetchRequest] error:nil] count] > 0 ? @"NCMainMenuLoginHeaderViewController" : @"NCMainMenuHeaderViewController";
	
	
	NCMainMenuHeaderViewController* from = self.headerViewController;
	NCMainMenuHeaderViewController* to = [self.storyboard instantiateViewControllerWithIdentifier:identifier];
	
	self.headerMinHeight = [to.view systemLayoutSizeFittingSize:CGSizeMake(self.view.bounds.size.width, 0) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityDefaultHigh].height;
	self.headerMaxHeight = [to.view systemLayoutSizeFittingSize:CGSizeMake(self.view.bounds.size.width, 0) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;

	CGRect rect = CGRectMake(0, 0, self.view.bounds.size.width, self.headerMaxHeight);
	to.view.frame = rect;
	to.view.translatesAutoresizingMaskIntoConstraints = YES;
	[to.view layoutIfNeeded];

	
	if (from) {
		[from willMoveToParentViewController:nil];
		[self addChildViewController:to];
		to.view.alpha = 0.0;
		[self transitionFromViewController:from toViewController:to duration:0.25 options:0 animations:^{
			from.view.alpha = 0.0;
			to.view.alpha = 1.0;
			self.tableView.tableHeaderView.frame = rect;
			self.tableView.tableHeaderView = self.tableView.tableHeaderView;
		} completion:^(BOOL finished) {
			[from removeFromParentViewController];
			[to didMoveToParentViewController:self];
		}];
	}
	else {
		self.tableView.tableHeaderView.frame = rect;
		self.tableView.tableHeaderView = self.tableView.tableHeaderView;
		[self addChildViewController:to];
		[self.tableView addSubview:to.view];
		[self didMoveToParentViewController:self];
	}
	
	self.headerViewController = to;
}

- (void) loadMenu {
	NCAccount* account = NCAccount.currentAccount;
	BOOL corporate = account.eveAPIKey.corporate;
	NSInteger apiKeyAccessMask = account.apiKey.apiKeyInfo.key.accessMask;
	NSString* accessMaskKey = corporate ? @"corpAccessMask" : @"charAccessMask" ;
	
	NSArray* mainMenu = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"mainMenu" ofType:@"plist"]];
	
	NSMutableArray* sections = [NSMutableArray new];
	for (NSArray* rows in mainMenu) {
		NSMutableArray* section = [NSMutableArray new];
		for (NSDictionary* row in rows) {
			NSInteger accessMask = [row[accessMaskKey] integerValue];
			if ((accessMask & apiKeyAccessMask) == accessMask) {
				[section addObject:row];
			}
		}
		if (section.count > 0)
			[sections addObject:section];
	}
	self.mainMenu = sections;
	[self updateAccountInfo];
}

- (void) updateAccountInfo {
	NCAccount* account = NCAccount.currentAccount;
	if (!account)
		return;
	
	NCMainMenuDetails* mainMenuDetails = [NCMainMenuDetails new];
	mainMenuDetails.account = account;
	self.mainMenuDetails = mainMenuDetails;
	
	NCDataManager* dataManager = [NCDataManager defaultManager];
	
	if (account.eveAPIKey.corporate) {
	}
	else {
		[dataManager characterInfoForAccount:account cachePolicy:NSURLRequestUseProtocolCachePolicy completionHandler:^(EVECharacterInfo *result, NSError *error, NSManagedObjectID *cacheRecordID) {
			mainMenuDetails.characterInfo = [NCCache.sharedCache.viewContext objectWithID:cacheRecordID];
		}];
		
		[dataManager characterSheetForAccount:account cachePolicy:NSURLRequestUseProtocolCachePolicy completionHandler:^(EVECharacterSheet *result, NSError *error, NSManagedObjectID *cacheRecordID) {
			mainMenuDetails.characterSheet = [NCCache.sharedCache.viewContext objectWithID:cacheRecordID];
		}];
		
		[dataManager skillQueueForAccount:account cachePolicy:NSURLRequestUseProtocolCachePolicy completionHandler:^(EVESkillQueue *result, NSError *error, NSManagedObjectID *cacheRecordID) {
			mainMenuDetails.skillQueue = [NCCache.sharedCache.viewContext objectWithID:cacheRecordID];
		}];
	}
}

@end
