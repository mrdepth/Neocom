//
//  NCStoryboardPopoverSegue.m
//  Neocom
//
//  Created by Артем Шиманский on 03.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCStoryboardPopoverSegue.h"

@implementation NCStoryboardPopoverSegue

- (UIView*) anchorView {
	if (!_anchorView && [self.sourceViewController respondsToSelector:@selector(tableView)]) {
		NSIndexPath* indexPath = [[self.sourceViewController tableView] indexPathForSelectedRow];
		if (indexPath)
			_anchorView = [[self.sourceViewController tableView] cellForRowAtIndexPath:indexPath];
	}
	return _anchorView;
}

- (UIView*) _anchorView {
	return self.anchorView;
}

- (CGRect) _anchorRect {
	return self.anchorView.bounds;
}

- (UIPopoverArrowDirection) _permittedArrowDirections {
	return UIPopoverArrowDirectionAny;
}

@end
