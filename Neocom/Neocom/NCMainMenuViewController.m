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

@interface NCMainMenuViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, weak) NCMainMenuHeaderViewController* headerViewController;
@property (nonatomic, assign) CGFloat headerMinHeight;
@property (nonatomic, assign) CGFloat headerMaxHeight;
@property (nonatomic, strong) NSArray<NSArray<NSDictionary<NSString*, id>*>*>* mainMenu;
@end

@implementation NCMainMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.mainMenu = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"mainMenu" ofType:@"plist"]];
	
	self.headerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NCMainMenuCharacterHeaderViewController"];
	[self.tableView addSubview:self.headerViewController.view];
	[self addChildViewController:self.headerViewController];
	
//	for (UIViewController* controller in self.childViewControllers) {
//		if ([controller isKindOfClass:[NCMainMenuHeaderViewController class]])
//			self.headerViewController = (NCMainMenuHeaderViewController*) controller;
//	}
	//self.tableView.tableHeaderView.frame = CGRectZero;
	//self.tableView.contentInset = UIEdgeInsetsMake(190, 0, 0, 0);
	self.tableView.estimatedRowHeight = 43;
    // Do any additional setup after loading the view.
	self.headerMinHeight = [self.headerViewController.view systemLayoutSizeFittingSize:CGSizeMake(self.view.bounds.size.width, 0) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityDefaultHigh].height;
	self.headerMaxHeight = [self.headerViewController.view systemLayoutSizeFittingSize:CGSizeMake(self.view.bounds.size.width, 0) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;
	
	CGRect rect = CGRectMake(0, 0, self.view.bounds.size.width, self.headerMaxHeight);
	//self.tableView.contentInset = UIEdgeInsetsMake(self.headerMaxHeight, 0, 0, 0);
	self.tableView.tableHeaderView.frame = rect;
	self.headerViewController.view.frame = rect;
	self.headerViewController.view.translatesAutoresizingMaskIntoConstraints = YES;
//	self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(self.headerViewController.view.frame.size.height, 0, 0, 0);
	
	self.edgesForExtendedLayout = UIRectEdgeNone;
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
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
