//
//  NCTableViewCollapsedHeaderView.m
//  Neocom
//
//  Created by Артем Шиманский on 26.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCollapsedHeaderView.h"
#import "NCDatabase.h"

@implementation NCTableViewCollapsedHeaderView

- (void) setCollapsed:(BOOL)value {
	_collapsed = value;
	self.imageView.image = [UIImage imageNamed:value ? @"collapsed" : @"expanded"];
}


@end
