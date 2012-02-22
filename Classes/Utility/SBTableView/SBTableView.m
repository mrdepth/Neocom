//
//  SBTableView.m
//  AutoHidingBar
//
//  Created by Shimanski on 11/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SBTableView.h"

@interface SBTableView(Private)

- (void) scrollToNearest;

@end


@implementation SBTableView
@synthesize topView;
@synthesize visibleTopPartHeight;

- (void) awakeFromNib {
	self.delegate = self;
	topView.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y - topView.frame.size.height, topView.frame.size.width, topView.frame.size.height);
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
		self.delegate = self;
    }
    return self;
}

- (void)dealloc {
	[topView release];
    [super dealloc];
}

- (void) setDelegate:(id <UITableViewDelegate>) value {
	if (value == self)
		[super setDelegate:value];
	else {
		delegate = value;
	}
}

- (id <UITableViewDelegate>) delegate {
	return delegate;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
	return [SBTableView instancesRespondToSelector:aSelector] | [delegate respondsToSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    SEL aSelector = [invocation selector];
	
    if ([delegate respondsToSelector:aSelector])
        [invocation invokeWithTarget:delegate];
    else
        [self doesNotRecognizeSelector:aSelector];
}

- (void) setFrame:(CGRect)value {
	[super setFrame:value];
}

- (void) setVisibleTopPartHeight:(float)value {
	float dif = value - visibleTopPartHeight;
	visibleTopPartHeight = value;
	if (topView.frame.origin.y < visibleTopPartHeight - topView.frame.size.height) {
		topView.frame = CGRectMake(topView.frame.origin.x, visibleTopPartHeight - topView.frame.size.height, topView.frame.size.width, topView.frame.size.height);
		self.frame = CGRectMake(self.frame.origin.x, visibleTopPartHeight, self.frame.size.width, self.frame.size.height - dif);
	}
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if (topView) {
		CGPoint p = scrollView.contentOffset;
		p.y = - p.y;
		if (scrollView.frame.origin.y + p.y >= topView.frame.size.height) {
			scrollView.frame = CGRectMake(scrollView.frame.origin.x, topView.frame.size.height, scrollView.frame.size.width, scrollView.frame.size.height);
			topView.frame = CGRectMake(topView.frame.origin.x, 0, topView.frame.size.width, topView.frame.size.height);
		}
		else if (scrollView.frame.origin.y + p.y < visibleTopPartHeight) {
			scrollView.frame = CGRectMake(scrollView.frame.origin.x, visibleTopPartHeight, scrollView.frame.size.width, scrollView.frame.size.height);
			topView.frame = CGRectMake(topView.frame.origin.x, -topView.frame.size.height + visibleTopPartHeight, topView.frame.size.width, topView.frame.size.height);
		}
		else {
			scrollView.frame = CGRectMake(scrollView.frame.origin.x, scrollView.frame.origin.y + p.y, scrollView.frame.size.width, scrollView.frame.size.height);
			topView.frame = CGRectMake(topView.frame.origin.x, topView.frame.origin.y + p.y, topView.frame.size.width, topView.frame.size.height);
			scrollView.contentOffset = CGPointMake(0, 0);
		}
	}

    if ([delegate respondsToSelector:@selector(scrollViewDidScroll:)])
		[delegate scrollViewDidScroll:scrollView];

}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {	
	if (!decelerate) {
		[self scrollToNearest];
	}
    if ([delegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)])
		[delegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	[self scrollToNearest];
    if ([delegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)])
		[delegate scrollViewDidEndDecelerating:scrollView];
}

@end

@implementation SBTableView(Private)

- (void) scrollToNearest {
	if (!topView)
		return;
	if (self.frame.origin.y > (topView.frame.size.height + visibleTopPartHeight) / 2) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationDuration:0.3];
		self.frame = CGRectMake(self.frame.origin.x, topView.frame.size.height, self.frame.size.width, self.frame.size.height);
		topView.frame = CGRectMake(topView.frame.origin.x, 0, topView.frame.size.width, topView.frame.size.height);
		[UIView commitAnimations];
	}
	else {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationDuration:0.3];
		self.frame = CGRectMake(self.frame.origin.x, visibleTopPartHeight, self.frame.size.width, self.frame.size.height);
		topView.frame = CGRectMake(topView.frame.origin.x, -topView.frame.size.height + visibleTopPartHeight, topView.frame.size.width, topView.frame.size.height);
		[UIView commitAnimations];
	}
}

@end