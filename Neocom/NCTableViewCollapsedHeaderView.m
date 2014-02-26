//
//  NCTableViewCollapsedHeaderView.m
//  Neocom
//
//  Created by Артем Шиманский on 26.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCollapsedHeaderView.h"

@implementation NCTableViewCollapsedHeaderView

- (void) setCollapsed:(BOOL)value {
	_collapsed = value;
	self.imageView.image = [UIImage imageNamed:value ? @"Icons/icon105_04.png" : @"Icons/icon105_05.png"];
}


@end
