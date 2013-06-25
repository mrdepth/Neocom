//
//  ExpandedTableView.m
//  EVEUniverse
//
//  Created by Mr. Depth on 2/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ExpandedTableView.h"

@interface ExpandedTableView()

- (void) didTapSection:(UITapGestureRecognizer*) recognizer;

@end

@implementation ExpandedTableView

- (void) awakeFromNib {
	self.delegate = self;
	self.dataSource = self;
}

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame]) {
		self.delegate = self;
		self.dataSource = self;
	}
    return self;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
	return [ExpandedTableView instancesRespondToSelector:aSelector] || [expandedTableViewdDelegate respondsToSelector:aSelector] || [expandedTableViewdDataSource respondsToSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    SEL aSelector = [invocation selector];
	
    if ([expandedTableViewdDelegate respondsToSelector:aSelector])
        [invocation invokeWithTarget:expandedTableViewdDelegate];
    else if ([expandedTableViewdDataSource respondsToSelector:aSelector])
        [invocation invokeWithTarget:expandedTableViewdDataSource];
    else
        [self doesNotRecognizeSelector:aSelector];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if ([expandedTableViewdDelegate tableView:self isExpandedSection:section])
		return [expandedTableViewdDataSource tableView:tableView numberOfRowsInSection:section];
	else
		return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView* header = nil;
	if ([expandedTableViewdDelegate respondsToSelector:@selector(tableView:viewForHeaderInSection:)])
		header = [expandedTableViewdDelegate tableView:tableView viewForHeaderInSection:section];
	if (!header) {
		header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 22)] autorelease];
		
		header.opaque = NO;
		header.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9];
		
		UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.frame.size.width - 40, 22)] autorelease];
		label.opaque = NO;
		label.backgroundColor = [UIColor clearColor];
		if ([expandedTableViewdDataSource respondsToSelector:@selector(tableView:titleForHeaderInSection:)])
			label.text = [expandedTableViewdDataSource tableView:tableView titleForHeaderInSection:section];
		label.textColor = [UIColor whiteColor];
		label.font = [label.font fontWithSize:12];
		label.shadowColor = [UIColor blackColor];
		label.shadowOffset = CGSizeMake(1, 1);
		label.lineBreakMode = UILineBreakModeMiddleTruncation;
		[header addSubview:label];
	}
	BOOL expanded = [expandedTableViewdDelegate tableView:self isExpandedSection:section];
	UIImage* image = [UIImage imageNamed:expanded ? @"Icons/icon105_04.png" : @"Icons/icon105_05.png"];
	UIImageView* imageView = [[[UIImageView alloc] initWithImage:image] autorelease];
	imageView.frame = CGRectMake(tableView.frame.size.width - 22, header.frame.size.height / 2 - 11, 22, 22);
	imageView.tag = -1;
	[header addSubview:imageView];
	header.tag = section;
	[header addGestureRecognizer:[[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapSection:)] autorelease]];
	return header;
}

#pragma mark - Private

- (void) didTapSection:(UITapGestureRecognizer*) recognizer {
	NSInteger section = recognizer.view.tag;
	BOOL expanded = ![expandedTableViewdDelegate tableView:self isExpandedSection:section];
	
	UIImage* image = [UIImage imageNamed:expanded ? @"Icons/icon105_04.png" : @"Icons/icon105_05.png"];
	[(UIImageView*) [recognizer.view viewWithTag:-1] setImage:image];
	
	if (expanded) {
		[expandedTableViewdDelegate tableView:self didExpandSection:section];
	}
	else {
		[expandedTableViewdDelegate tableView:self didCollapseSection:section];
	}
	[self reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationNone];
}
@end