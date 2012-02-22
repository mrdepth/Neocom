//
//  EUSearchDisplayController.m
//  EVEUniverse
//
//  Created by Shimanski on 8/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EUSearchDisplayController.h"

@interface EUSearchDisplayController(Private)
- (void) updateNoResultsLabel;
@end

@implementation EUSearchDisplayController

- (void) awakeFromNib {
	[super awakeFromNib];
	[self.searchBar addObserver:self forKeyPath:@"selectedScopeButtonIndex" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	NSUInteger oldValue = [[change valueForKey:NSKeyValueChangeOldKey] unsignedIntegerValue];
	NSUInteger newValue = [[change valueForKey:NSKeyValueChangeNewKey] unsignedIntegerValue];
	if (oldValue == newValue)
		return;
	if (scopeSegmentControler.selectedSegmentIndex != newValue)
		scopeSegmentControler.selectedSegmentIndex = newValue;
}

- (void) dealloc {
	[self.searchBar removeObserver:self forKeyPath:@"selectedScopeButtonIndex"];
	[popoverController release];
	[tableViewController release];
	[noResultsLabel release];
	[sections release];
	[scopeSegmentControler release];
	[super dealloc];
}

- (UIPopoverController*) popoverController {
	if (!popoverController) {
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.tableViewController];
		popoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
		popoverController.delegate = self;
		popoverController.passthroughViews = [NSArray arrayWithObject:self.searchBar];
		popoverController.popoverContentSize = CGSizeMake(320, 1100);
		[navigationController release];
	}
	return popoverController;
}

- (UITableViewController*) tableViewController {
	if (!tableViewController) {
		tableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
		tableViewController.tableView.dataSource = self;
		tableViewController.tableView.delegate = self;
		tableViewController.contentSizeForViewInPopover = CGSizeMake(320, 1100);
		NSArray *titles = self.searchBar.scopeButtonTitles;
		if (titles.count > 0) {
			if (scopeSegmentControler)
				[scopeSegmentControler release];
			scopeSegmentControler = [[UISegmentedControl alloc] initWithItems:titles];
			scopeSegmentControler.segmentedControlStyle = UISegmentedControlStyleBar;
			scopeSegmentControler.selectedSegmentIndex = self.searchBar.selectedScopeButtonIndex;
			[scopeSegmentControler addTarget:self action:@selector(onChangePublishedFilterSegment:) forControlEvents:UIControlEventValueChanged];
			[tableViewController.navigationItem setTitleView:scopeSegmentControler];
		}
		else
			tableViewController.title = @"Results";
		
		self.noResultsLabel.frame = tableViewController.tableView.bounds;
		[tableViewController.tableView addSubview:self.noResultsLabel];
		[self.delegate searchDisplayController:self didLoadSearchResultsTableView:tableViewController.tableView];
	}
	return tableViewController;
}

- (UITableView*) searchResultsTableView {
	return self.tableViewController.tableView;
}

- (void)setActive:(BOOL)visible animated:(BOOL)animated {
	if (visible) {
		if (![self.popoverController isPopoverVisible])
			[popoverController presentPopoverFromRect:self.searchBar.frame inView:self.searchBar.superview permittedArrowDirections:UIPopoverArrowDirectionUp animated:animated];
	}
	else {
		if ([self.popoverController isPopoverVisible]) {
			[self.searchBar resignFirstResponder];
			[popoverController dismissPopoverAnimated:animated];
		}
	}
}

- (UILabel*) noResultsLabel {
	if (!noResultsLabel) {
		noResultsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		noResultsLabel.autoresizingMask =  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		noResultsLabel.text = @"No Results";
		noResultsLabel.textColor = [UIColor colorWithWhite:0.48 alpha:1];
		noResultsLabel.backgroundColor = [UIColor clearColor];
		noResultsLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:20];
		noResultsLabel.textAlignment = UITextAlignmentCenter;
	}
	return noResultsLabel;
}

- (IBAction) onChangePublishedFilterSegment: (id) sender {
	self.searchBar.selectedScopeButtonIndex = scopeSegmentControler.selectedSegmentIndex;
	if ([self.searchBar.delegate respondsToSelector:@selector(searchBar:selectedScopeButtonIndexDidChange:)])
		[self.searchBar.delegate searchBar:self.searchBar selectedScopeButtonIndexDidChange:scopeSegmentControler.selectedSegmentIndex];

	if ([self.delegate respondsToSelector:@selector(searchDisplayController:shouldReloadTableForSearchScope:)]) {
		if ([self.delegate searchDisplayController:self shouldReloadTableForSearchScope:scopeSegmentControler.selectedSegmentIndex])
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
	[self setActive:YES animated:YES];
	if ([self.delegate respondsToSelector:@selector(searchDisplayController:shouldReloadTableForSearchString:)]) {
		if ([self.delegate searchDisplayController:self shouldReloadTableForSearchString:searchText])
			[self.searchResultsTableView reloadData];
	}
	else
		[self.searchResultsTableView reloadData];
}

- (void)searchBarResultsListButtonClicked:(UISearchBar *)searchBar {
	[self setActive:YES animated:YES];
	[searchBar resignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
//	searchBar.showsSearchResultsButton = NO;
	if (searchBar.text.length > 0)
		[self setActive:YES animated:YES];
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
	if (!sections) {
		sections = [[NSMutableArray alloc] init];
	}
	else
		[sections removeAllObjects];
	for (int i = 0; i < n; i++)
		[sections addObject:[NSNull null]];
	return n;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger n = [self.searchResultsDataSource tableView:tableView numberOfRowsInSection:section];
	[sections replaceObjectAtIndex:section withObject:[NSNumber numberWithInteger:n]];
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

@end

@implementation EUSearchDisplayController(Private)

- (void) updateNoResultsLabel {
	int n = 0;
	for (NSNumber *number in sections) {
		if ([number isKindOfClass:[NSNumber class]])
			n += [number integerValue];
	}
	noResultsLabel.hidden = n > 0;
}

@end
