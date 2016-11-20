//
//  NCMainMenuViewController.m
//  Neocom
//
//  Created by Artem Shimanski on 13.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCMainMenuViewController.h"
#import "NCMainMenuHeaderViewController.h"
#import "NCImageSubtitleCell.h"
#import "NCSlideDownInteractiveTransition.h"
#import "NCSlideDownAnimationController.h"
#import "NCStorage.h"
#import "NCDataManager.h"
#import "NCUnitFormatter.h"
#import "unitily.h"
#import "NCTimeIntervalFormatter.h"
#import "NCAccountsViewController.h"
@import EVEAPI;

@interface NCMainMenuViewController ()<UITableViewDataSource, UITableViewDelegate, UIViewControllerTransitioningDelegate>
@property (nonatomic, weak) NCMainMenuHeaderViewController* headerViewController;
@property (nonatomic, assign) CGFloat headerMinHeight;
@property (nonatomic, assign) CGFloat headerMaxHeight;
@property (nonatomic, strong) NSArray<NSArray<NSDictionary<NSString*, id>*>*>* mainMenu;
@property (nonatomic, assign, getter=isInteractive) BOOL interactive;

@property (nonatomic, strong) NSString* skillPoints;
@property (nonatomic, strong) NSString* skillQueue;
@property (nonatomic, strong) NSString* unreadMails;
@property (nonatomic, strong) NSString* balance;
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
	NCImageSubtitleCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	NSDictionary* row = self.mainMenu[indexPath.section][indexPath.row];
	cell.titleLabel.text = row[@"title"];
	NSString* detailsKeyPath = row[@"detailsKeyPath"];
	if (detailsKeyPath)
		cell.subtitleLabel.text = [self valueForKey:detailsKeyPath];
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
	self.skillPoints = nil;
	self.skillQueue = nil;
	self.balance = nil;
	
	NCAccount* account = NCAccount.currentAccount;
	NCDataManager* dataManager = [NCDataManager defaultManager];
	
	if (account.eveAPIKey.corporate) {
	}
	else {
		[dataManager characterInfoForAccount:account cachePolicy:NSURLRequestUseProtocolCachePolicy completionHandler:^(EVECharacterInfo *result, NSError *error, NSManagedObjectID *cacheRecordID) {
			if (result) {
				self.skillPoints = [NCUnitFormatter localizedStringFromNumber:@(result.skillPoints) unit:NCUnitSP style:NCUnitFormatterStyleFull];
				self.balance = [NCUnitFormatter localizedStringFromNumber:@(result.accountBalance) unit:NCUnitISK style:NCUnitFormatterStyleFull];
			}
			else {
				self.skillPoints = [error localizedDescription];
				self.balance = [error localizedDescription];
			}
			[self reloadCellWithDetails:@"skillPoints"];
			[self reloadCellWithDetails:@"balance"];
		}];
		
		[dataManager skillQueueForAccount:account cachePolicy:NSURLRequestUseProtocolCachePolicy completionHandler:^(EVESkillQueue *result, NSError *error, NSManagedObjectID *cacheRecordID) {
			if (result) {
				if (result.skillQueue.count == 0)
					self.skillQueue = NSLocalizedString(@"No skills in training", nil);
				else {
					NSArray* skills = [result.skillQueue sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"queuePosition" ascending:YES]]];
					EVESkillQueueItem* lastSkill = [skills lastObject];
					NSDate* endTime = [result.eveapi localTimeWithServerTime:lastSkill.endTime];
					self.skillQueue = [NSString stringWithFormat:NSLocalizedString(@"%d skills in queue (%@)" , nil), (int) skills.count, [NCTimeIntervalFormatter localizedStringFromTimeInterval:[endTime timeIntervalSinceNow] style:NCTimeIntervalFormatterStyleMinuts]];
					;
				}
			}
			else
				self.skillQueue = [error localizedDescription];
			[self reloadCellWithDetails:@"skillQueue"];
		}];
	}
}

- (void) reloadCellWithDetails:(NSString*) details {
	NSInteger section = 0;
	for (NSArray* rows in self.mainMenu) {
		NSInteger row = 0;
		for (NSDictionary* dic in rows) {
			if ([dic[@"detailsKeyPath"] isEqualToString:details]) {
				[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:section]] withRowAnimation:UITableViewRowAnimationFade];
			}
			row++;
		}
		section++;
	}
}

@end
