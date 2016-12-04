//
//  NCProgressHandler.m
//  Neocom
//
//  Created by Artem Shimanski on 16.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCProgressHandler.h"
#import "UIColor+CS.h"

@interface NCProgressHandler()
@property (nonatomic, strong, readwrite) NSProgress* progress;
@property (nonatomic, strong) NSProgress* totalProgress;
@property (nonatomic, strong) NSProgress* fakeProgress;
@property (nonatomic, strong) id strongRefToSelf;
@property (nonatomic, strong) UIProgressView* progressView;
@property (nonatomic, strong) NSTimer* timer;
@property (nonatomic, weak) UIViewController* controller;

@end

@implementation NCProgressHandler

+ (NCProgressHandler*) progressHandlerForViewController:(UIViewController*) controller withTotalUnitCount:(int64_t)unitCount {
	return [[self alloc] initForViewController:controller withTotalUnitCount:unitCount];
}

- (id) initForViewController:(UIViewController*) controller withTotalUnitCount:(int64_t)unitCount {
	if (self = [super init]) {
		if (!controller)
			return nil;
		self.controller = controller;
		
		self.totalProgress = [NSProgress progressWithTotalUnitCount:3];
		[self.totalProgress becomeCurrentWithPendingUnitCount:1];
		self.fakeProgress = [NSProgress progressWithTotalUnitCount:100];
		[self.totalProgress resignCurrent];
		[self.totalProgress becomeCurrentWithPendingUnitCount:2];
		self.progress = [NSProgress progressWithTotalUnitCount:unitCount];
		[self.totalProgress resignCurrent];
		
		self.timer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(timerTick:) userInfo:nil repeats:YES];
		[[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
	}
	return self;
}

- (void) dealloc {
	self.timer = nil;
	self.totalProgress = nil;
	if (_progressView) {
		if ([NSThread isMainThread]) {
			[_progressView removeFromSuperview];
		}
		else {
			UIProgressView* progressView = _progressView;
			dispatch_async(dispatch_get_main_queue(), ^{
				[progressView removeFromSuperview];
			});
		}
	}
}

- (void) finish {
	self.timer = nil;
	self.totalProgress = nil;
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
	if ([keyPath isEqualToString:@"fractionCompleted"]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (self.progress.fractionCompleted >= 1.0)
				[self finish];
			else
				[self.progressView setProgress:self.totalProgress.fractionCompleted animated:YES];
		});
	}
}

#pragma mark - Private;

- (void) setTotalProgress:(NSProgress *)totalProgress {
	[_totalProgress removeObserver:self forKeyPath:@"fractionCompleted"];
	_totalProgress = totalProgress;
	[_totalProgress addObserver:self forKeyPath:@"fractionCompleted" options:0 context:nil];
}

- (void) setTimer:(NSTimer *)timer {
	[_timer invalidate];
	_timer = timer;
}

- (void) timerTick:(NSTimer*) timer {
	_fakeProgress.completedUnitCount += 5;
	if (_fakeProgress.fractionCompleted >= 1)
		self.timer = nil;
}

- (UIProgressView*) progressView {
	if (_progressView && !_progressView.window) {
		[_progressView removeFromSuperview];
		_progressView = nil;
	}
	
	if (!_progressView) {
		if (self.controller.view.window) {
			UINavigationBar* bar = self.controller.navigationController.navigationBar;
			if (bar) {
				_progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
				_progressView.layer.zPosition = 1000;
				_progressView.translatesAutoresizingMaskIntoConstraints = NO;
				_progressView.progressTintColor = [UIColor progressTintColor];
				_progressView.trackTintColor = [UIColor clearColor];
				[self.controller.view addSubview:_progressView];
				
				NSMutableArray* constraints = [NSMutableArray new];
				[constraints addObject:[NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:bar attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
				[constraints addObject:[NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:bar attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
				[constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[bar]-0-[progress]" options:0 metrics:nil views:@{@"progress": self.progressView, @"bar":bar}]];
				[NSLayoutConstraint activateConstraints:constraints];
			}
			[self.controller.view layoutIfNeeded];
		}
	}
	return _progressView;
}

@end
