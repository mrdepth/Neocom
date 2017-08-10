//
//  UIView+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 25.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "UIView+Neocom.h"

@implementation UIView (Neocom)

- (UIView*) snapshot {
	return [self snapshotViewAfterScreenUpdates:YES];
}


@end
