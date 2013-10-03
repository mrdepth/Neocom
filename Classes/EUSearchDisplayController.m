//
//  EUSearchDisplayController.m
//  EVEUniverse
//
//  Created by Shimanski on 8/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EUSearchDisplayController.h"
#import "EUPopoverBackgroundView.h"

@interface UISearchDisplayController() <UISearchBarDelegate>

@end

@interface EUSearchDisplayController()
@property (nonatomic, readwrite, strong) UIPopoverController *popoverController;
@property (nonatomic, readwrite, strong) UITableViewController *tableViewController;
@property (nonatomic, readwrite, strong) UILabel *noResultsLabel;
@property(nonatomic, strong) NSMutableArray *sections;
@property(nonatomic, strong) UISegmentedControl *scopeSegmentControler;

- (void) updateNoResultsLabel;

@end

@implementation EUSearchDisplayController
@synthesize popoverController;
@synthesize noResultsLabel;

- (void) awakeFromNib {
	[super awakeFromNib];
	[self.searchBar addObserver:self forKeyPath:@"selectedScopeButtonIndex" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	NSUInteger oldValue = [[change valueForKey:NSKeyValueChangeOldKey] unsignedIntegerValue];
	NSUInteger newValue = [[change valueForKey:NSKeyValueChangeNewKey] unsignedIntegerValue];
	if (oldValue == newValue)
		return;
	if (self.scopeSegmentControler.selectedSegmentIndex != newValue)
		self.scopeSegmentControler.selectedSegmentIndex = newValue;
}

- (void) dealloc {
	[self.searchBar removeObserver:self forKeyPath:@"selectedScopeButtonIndex" context:nil];
}

- (UIPopoverController*) popoverController {
	if (!popoverController) {
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.tableViewController];
		popoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
		popoverController.delegate = self;
		popoverController.passthroughViews = [NSArray arrayWithObject:self.searchBar];
		popoverController.popoverContentSize = CGSizeMake(320, 1100);
		popoverController.popoverBackgroundViewClass = [EUPopoverBackgroundView class];
	}
	return popoverController;
}

- (UITableViewController*) tableViewController {
	if (!_tableViewController) {
		_tableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
		_tableViewController.tableView.dataSource = self;
		_tableViewController.tableView.delegate = self;
		_tableViewController.contentSizeForViewInPopover = CGSizeMake(320, 1100);
		_tableViewController.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
		NSArray *titles = self.searchBar.scopeButtonTitles;
		if (titles.count > 0) {
			_scopeSegmentControler = [[UISegmentedControl alloc] initWithItems:titles];
			_scopeSegmentControler.segmentedControlStyle = UISegmentedControlStyleBar;
			_scopeSegmentControler.selectedSegmentIndex = self.searchBar.selectedScopeButtonIndex;
			[_scopeSegmentControler addTarget:self action:@selector(onChangePublishedFilterSegment:) forControlEvents:UIControlEventValueChanged];
			[_tableViewController.navigationItem setTitleView:_scopeSegmentControler];
		}
		else
			_tableViewController.title = NSLocalizedString(@"Results", nil);
		
		self.noResultsLabel.frame = _tableViewController.tableView.bounds;
		[_tableViewController.tableView addSubview:self.noResultsLabel];
		[self.delegate searchDisplayController:self didLoadSearchResultsTableView:_tableViewController.tableView];
	}
	return _tableViewController;
}

- (UITableView*) searchResultsTableView {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return self.tableViewController.tableView;
	else
		return [super searchResultsTableView];
}

- (void)setActive:(BOOL)visible animated:(BOOL)animated {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if (visible) {
			if (![self.popoverController isPopoverVisible])
				[self.popoverController presentPopoverFromRect:self.searchBar.frame inView:self.searchBar.superview permittedArrowDirections:UIPopoverArrowDirectionUp animated:animated];
		}
		else {
			if ([self.popoverController isPopoverVisible]) {
				[self.searchBar resignFirstResponder];
				[self.popoverController dismissPopoverAnimated:animated];
			}
		}
	}
	else {
		//[self.searchContentsController.navigationController setNavigationBarHidden:visible animated:YES];
		[super setActive:visible animated:animated];
	}
}

- (UILabel*) noResultsLabel {
	if (!noResultsLabel) {
		noResultsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		noResultsLabel.autoresizingMask =  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		noResultsLabel.text = NSLocalizedString(@"No Results", nil);
		noResultsLabel.textColor = [UIColor colorWithWhite:0.48 alpha:1];
		noResultsLabel.backgroundColor = [UIColor clearColor];
		noResultsLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:20];
		noResultsLabel.textAlignment = NSTextAlignmentCenter;
	}
	return noResultsLabel;
}

- (IBAction) onChangePublishedFilterSegment: (id) sender {
	self.searchBar.selectedScopeButtonIndex = _scopeSegmentControler.selectedSegmentIndex;
	if ([self.searchBar.delegate respondsToSelector:@selector(searchBar:selectedScopeButtonIndexDidChange:)])
		[self.searchBar.delegate searchBar:self.searchBar selectedScopeButtonIndexDidChange:self.scopeSegmentControler.selectedSegmentIndex];

	if ([self.delegate respondsToSelector:@selector(searchDisplayController:shouldReloadTableForSearchScope:)]) {
		if ([self.delegate searchDisplayController:self shouldReloadTableForSearchScope:self.scopeSegmentControler.selectedSegmentIndex])
			[self.searchResultsTableView reloadData];
	}
	else
		[self.searchResultsTableView reloadData];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
	return [EUSearchDisplayController instancesRespondToSelector:aSelector] | [self.searchResultsDelegate respondsToSelector:aSelector] | [self.searchResultsDataSource respondsToSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    SEL aSelector = [invocation selector];
	
    if ([self.searchResultsDelegate respondsToSelector:aSelector])
        [invocation invokeWithTarget:self.searchResultsDelegate];
    else if ([self.searchResultsDataSource respondsToSelector:aSelector])
        [invocation invokeWithTarget:self.searchResultsDelegate];
    else
        [self doesNotRecognizeSelector:aSelector];
}

#pragma mark UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		
		[self setActive:YES animated:YES];
		if ([self.delegate respondsToSelector:@selector(searchDisplayController:shouldReloadTableForSearchString:)]) {
			if ([self.delegate searchDisplayController:self shouldReloadTableForSearchString:searchText])
				[self.searchResultsTableView reloadData];
		}
		else
			[self.searchResultsTableView reloadData];
	}
	else
		[super searchBar:searchBar textDidChange:searchText];
}

- (void)searchBarResultsListButtonClicked:(UISearchBar *)searchBar {
	[self setActive:YES animated:YES];
	[searchBar resignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if (searchBar.text.length > 0)
			[self setActive:YES animated:YES];
	}
	else
		[super searchBarTextDidBeginEditing:searchBar];
}

#pragma mark UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)aPopoverController {
	[self.searchBar resignFirstResponder];
	if (!self.searchBar.showsBookmarkButton)
		self.searchBar.showsSearchResultsButton = self.searchBar.text.length > 0;
	aPopoverController.popoverContentSize = CGSizeMake(320, 1100);
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[self.searchBar resignFirstResponder];
    if ([self.searchResultsDelegate respondsToSelector:@selector(scrollViewDidScroll:)])
        [self.searchResultsDelegate scrollViewDidScroll:scrollView];
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NSInteger n;
	if ([self.searchResultsDataSource respondsToSelector:@selector(numberOfSectionsInTableView:)])
		n = [self.searchResultsDataSource numberOfSectionsInTableView:tableView];
	else
		n = 1;
	if (!self.sections) {
		self.sections = [[NSMutableArray alloc] init];
	}
	else
		[self.sections removeAllObjects];
	for (int i = 0; i < n; i++)
		[self.sections addObject:[NSNull null]];
	return n;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger n = [self.searchResultsDataSource tableView:tableView numberOfRowsInSection:section];
	[self.sections replaceObjectAtIndex:section withObject:[NSNumber numberWithInteger:n]];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateNoResultsLabel) object:nil];
	[self performSelector:@selector(updateNoResultsLabel) withObject:nil afterDelay:0];
	return n;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	return [self.searchResultsDataSource tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.searchBar resignFirstResponder];
	[self.searchResultsDelegate tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark - Private

- (void) updateNoResultsLabel {
	int n = 0;
	for (NSNumber *number in self.sections) {
		if ([number isKindOfClass:[NSNumber class]])
			n += [number integerValue];
	}
	self.noResultsLabel.hidden = n > 0;
}

@end
