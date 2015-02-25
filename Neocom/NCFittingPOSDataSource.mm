//
//  NCFittingPOSDataSource.m
//  Neocom
//
//  Created by Shimanski Artem on 11.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingPOSDataSource.h"
#import "UIColor+Neocom.h"
#import "NCTableViewCell.h"
#import "NCFittingPOSViewController.h"

@implementation NCFittingPOSDataSource

- (void) reload {
	
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString* identifier = [self tableView:tableView cellIdentifierForRowAtIndexPath:indexPath];
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
	if (!cell && tableView != self.tableView)
		cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
	
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	return cell;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 0;
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	cell.backgroundColor = [UIColor appearanceTableViewCellBackgroundColor];
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) cell forRowAtIndexPath:(NSIndexPath*) indexPath {
	
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return nil;
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return self.tableView.rowHeight;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1)
		return UITableViewAutomaticDimension;
	
	NSString* identifier = [self tableView:tableView cellIdentifierForRowAtIndexPath:indexPath];
	NCTableViewCell* cell = [self.controller.workspaceViewController tableView:tableView offscreenCellWithIdentifier:identifier];
	if ([cell isKindOfClass:[NCTableViewCell class]]) {
		[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
		cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
		[cell layoutIfNeeded];
		return cell.layoutContentView.frame.size.height;
	}
	else
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
}

@end
