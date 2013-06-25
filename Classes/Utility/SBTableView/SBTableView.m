//
//  SBTableView.m
//  AutoHidingBar
//
//  Created by Shimanski on 11/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SBTableView.h"

@interface SBTableView()

- (void) scrollToNearest;

@end


@implementation SBTableView
@synthesize delegate;

- (void) awakeFromNib {
	self.delegate = self;
	self.topView.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y - self.topView.frame.size.height, self.topView.frame.size.width, self.topView.frame.size.height);
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
		self.delegate = self;
    }
    return self;
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
	float dif = value - _visibleTopPartHeight;
	_visibleTopPartHeight = value;
	if (self.topView.frame.origin.y < _visibleTopPartHeight - self.topView.frame.size.height) {
		self.topView.frame = CGRectMake(self.topView.frame.origin.x, _visibleTopPartHeight - self.topView.frame.size.height, self.topView.frame.size.width, self.topView.frame.size.height);
		self.frame = CGRectMake(self.frame.origin.x, _visibleTopPartHeight, self.frame.size.width, self.frame.size.height - dif);
	}
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if (self.topView) {
		CGPoint p = scrollView.contentOffset;
		p.y = - p.y;
		if (scrollView.frame.origin.y + p.y >= self.topView.frame.size.height) {
			scrollView.frame = CGRectMake(scrollView.frame.origin.x, self.topView.frame.size.height, scrollView.frame.size.width, scrollView.frame.size.height);
			self.topView.frame = CGRectMake(self.topView.frame.origin.x, 0, self.topView.frame.size.width, self.topView.frame.size.height);
		}
		else if (scrollView.frame.origin.y + p.y < self.visibleTopPartHeight) {
			scrollView.frame = CGRectMake(scrollView.frame.origin.x, self.visibleTopPartHeight, scrollView.frame.size.width, scrollView.frame.size.height);
			self.topView.frame = CGRectMake(self.topView.frame.origin.x, -self.topView.frame.size.height + self.visibleTopPartHeight, self.topView.frame.size.width, self.topView.frame.size.height);
		}
		else {
			scrollView.frame = CGRectMake(scrollView.frame.origin.x, scrollView.frame.origin.y + p.y, scrollView.frame.size.width, scrollView.frame.size.height);
			self.topView.frame = CGRectMake(self.topView.frame.origin.x, self.topView.frame.origin.y + p.y, self.topView.frame.size.width, self.topView.frame.size.height);
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

#pragma mark -Private

- (void) scrollToNearest {
	if (!self.topView)
		return;
	if (self.frame.origin.y > (self.topView.frame.size.height + self.visibleTopPartHeight) / 2) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationDuration:0.3];
		self.frame = CGRectMake(self.frame.origin.x, self.topView.frame.size.height, self.frame.size.width, self.frame.size.height);
		self.topView.frame = CGRectMake(self.topView.frame.origin.x, 0, self.topView.frame.size.width, self.self.topView.frame.size.height);
		[UIView commitAnimations];
	}
	else {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationDuration:0.3];
		self.frame = CGRectMake(self.frame.origin.x, self.visibleTopPartHeight, self.frame.size.width, self.frame.size.height);
		self.topView.frame = CGRectMake(self.topView.frame.origin.x, -self.topView.frame.size.height + self.visibleTopPartHeight, self.topView.frame.size.width, self.topView.frame.size.height);
		[UIView commitAnimations];
	}
}

@end