//
//  NCTaskManager.m
//  Neocom
//
//  Created by Artem Shimanski on 12.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import "NCTaskManager.h"
#import <libkern/OSAtomic.h>

@interface NCTaskManager()<NCTaskDelegate> {
	int32_t _numberOfTasks;
}
@property (nonatomic, weak, readwrite) UIViewController* viewController;

@property (weak, nonatomic) NCTask* activeTask;
@property (nonatomic, strong) UIProgressView* progressView;

- (void) update;

@end

@implementation NCTaskManager

- (id) init {
	if (self = [super init]) {
		_numberOfTasks = 0;
	}
	return self;
}

- (id) initWithViewController:(UIViewController*) viewController {
	if (self = [self init]) {
		self.viewController = viewController;
		UINavigationBar* navigationBar = self.viewController.navigationController.navigationBar;
		if (navigationBar) {
			BOOL enabled = [UIView areAnimationsEnabled];
			[UIView setAnimationsEnabled:NO];
			self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
			self.progressView.frame = CGRectMake(0, navigationBar.frame.size.height - 2, navigationBar.frame.size.width, 2);
			self.progressView.hidden = YES;
			self.progressView.trackTintColor = [UIColor clearColor];
			[UIView setAnimationsEnabled:enabled];
		}
	}
	return self;
}

- (void) addTaskWithIndentifier:(NSString*) identifier
						  title:(NSString*) title
						  block:(void(^)(NCTask* task)) block
			  completionHandler:(void(^)(NCTask* task)) completionHandler {
	NCTask* task = [NCTask new];
	task.delegate = self;
	task.title = title;
	task.identifier = identifier;
	task.block = block;
	task.completionHandler = completionHandler;
	if (task.identifier) {
		for (NCTask* theTask in [self operations]) {
			if ([theTask.identifier isEqual:task.identifier]) {
				[task addDependency:theTask];
				[theTask cancel];
				break;
			}
		}
	}
	[self addOperation:task];
}

- (void) setActive:(BOOL)active {
	_active = active;
	if (self.progressView) {
		if (active) {
			if (!self.progressView.superview) {
				UINavigationBar* navigationBar = self.viewController.navigationController.navigationBar;
				[navigationBar addSubview:self.progressView];
			}
		}
		else {
			if (self.progressView.superview)
				[self.progressView removeFromSuperview];
		}
	}
}

#pragma mark - NCTaskDelegate

- (void) taskWillStart:(NCTask*) task {
	OSAtomicIncrement32Barrier(&_numberOfTasks);
	[self performSelectorOnMainThread:@selector(update) withObject:nil waitUntilDone:NO];
}

- (void) taskDidFinish:(NCTask*) task {
	OSAtomicDecrement32Barrier(&_numberOfTasks);
	[self performSelectorOnMainThread:@selector(update) withObject:nil waitUntilDone:NO];
}

- (void) task:(NCTask*) task didChangeProgress:(float) progress {
	[self performSelectorOnMainThread:@selector(update) withObject:nil waitUntilDone:NO];
}

#pragma mark - Private

- (void) update {
	if (_numberOfTasks > 0) {
		if (!_activeTask) {
			NSArray* operations = [self operations];
			if (operations.count > 0)
				_activeTask = operations[0];
		}
		if (self.progressView) {
			if (_activeTask) {
				self.progressView.hidden = NO;
				self.progressView.progress = _activeTask.progress;
			}
			else
				self.progressView.hidden = YES;
		}
	}
	else if (self.progressView) {
		self.progressView.hidden = YES;
	}
}

@end
