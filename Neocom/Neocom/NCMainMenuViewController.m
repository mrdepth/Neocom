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
#import "unitily.h"
@import EVEAPI;

@interface NCMainMenuViewController ()<UITableViewDataSource, UITableViewDelegate, UIViewControllerTransitioningDelegate>
@property (nonatomic, weak) NCMainMenuHeaderViewController* headerViewController;
@property (nonatomic, assign) CGFloat headerMinHeight;
@property (nonatomic, assign) CGFloat headerMaxHeight;
@property (nonatomic, strong) NSArray<NSArray<NSDictionary<NSString*, id>*>*>* mainMenu;
@end

@implementation NCMainMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.tableView.estimatedRowHeight = self.tableView.rowHeight;
	self.tableView.rowHeight = UITableViewAutomaticDimension;

	self.mainMenu = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"mainMenu" ofType:@"plist"]];

	[self updateHeader];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentAccountChanged:) name:NCCurrentAccountChangedNotification object:nil];
}

- (void) viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	//[self.tableView layoutIfNeeded];
	//NSLog(@"viewWillLayoutSubviews");
	CGRect rect = CGRectMake(0, [self.topLayoutGuide length], self.view.bounds.size.width, MAX(self.headerMaxHeight - self.tableView.contentOffset.y, self.headerMinHeight));
	self.headerViewController.view.frame = [self.view convertRect:rect toView:self.tableView];
	self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(rect.size.height, 0, 0, 0);

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
	cell.subtitleLabel.text = row[@"detailsKeyPath"];
	cell.iconView.image = [UIImage imageNamed:row[@"image"]];
	return cell;
}

- (UIStatusBarStyle) preferredStatusBarStyle {
	return UIStatusBarStyleDefault;
}

#pragma mark - UIScrollViewDelegate

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
	CGRect rect = CGRectMake(0, [self.topLayoutGuide length], self.tableView.bounds.size.width, MAX(self.headerMaxHeight - scrollView.contentOffset.y, self.headerMinHeight));
	self.headerViewController.view.frame = [self.view convertRect:rect toView:self.tableView];
	self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(rect.size.height, 0, 0, 0);
	if (scrollView.contentOffset.y < -50 && !self.transitionCoordinator && scrollView.tracking) {
		UIViewController* controller = [self.storyboard instantiateViewControllerWithIdentifier:@"NCAccountsViewController"];
		controller.transitioningDelegate = self;
		[self presentViewController:controller animated:YES completion:nil];
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
	return self.tableView.tracking ? [[NCSlideDownInteractiveTransition alloc] initWithScrollView:self.tableView] : nil;
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
	[self updateHeader];
}

- (void) updateHeader {
	NCAccount* account = NCAccount.currentAccount;
	NSString* identifier;
	if (account)
		identifier = account.eveAPIKey.corporate ? @"NCMainMenuCorporationHeaderViewController" : @"NCMainMenuCharacterHeaderViewController";
	else
		identifier = [[NCStorage.sharedStorage.viewContext executeFetchRequest:[NCAccount fetchRequest] error:nil] count] > 0 ? @"NCMainMenuLoginHeaderViewController" : @"NCMainMenuHeaderViewController";
	
	if (self.headerViewController) {
		[self.headerViewController.view removeFromSuperview];
		[self.headerViewController removeFromParentViewController];
	}
	
	self.headerViewController = [self.storyboard instantiateViewControllerWithIdentifier:identifier];
	[self.tableView addSubview:self.headerViewController.view];
	[self addChildViewController:self.headerViewController];
	
	self.headerMinHeight = [self.headerViewController.view systemLayoutSizeFittingSize:CGSizeMake(self.view.bounds.size.width, 0) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityDefaultHigh].height;
	self.headerMaxHeight = [self.headerViewController.view systemLayoutSizeFittingSize:CGSizeMake(self.view.bounds.size.width, 0) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;
	
	CGRect rect = CGRectMake(0, 0, self.view.bounds.size.width, self.headerMaxHeight);
	self.tableView.tableHeaderView.frame = rect;
	self.headerViewController.view.frame = rect;
	self.tableView.tableHeaderView = self.tableView.tableHeaderView;
	self.headerViewController.view.translatesAutoresizingMaskIntoConstraints = YES;
	[self.tableView setNeedsLayout];
	[self.tableView layoutIfNeeded];
}

@end
