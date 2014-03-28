//
//  NCNavigationController.m
//  Neocom
//
//  Created by Артем Шиманский on 28.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCNavigationController.h"

@interface NCNavigationController ()
@property (nonatomic, strong) UITapGestureRecognizer* tapOutsideGestureRecognizer;
- (void) onTap:(UITapGestureRecognizer *)recognizer;
@end

@implementation NCNavigationController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	self.tapOutsideGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
	self.tapOutsideGestureRecognizer.cancelsTouchesInView = NO;
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	self.tapOutsideGestureRecognizer = nil;
}

- (void) dealloc {
	self.tapOutsideGestureRecognizer = nil;
}

#pragma mark - Private

- (void) setTapOutsideGestureRecognizer:(UITapGestureRecognizer *)tapOutsideGestureRecognizer {
	if (_tapOutsideGestureRecognizer)
		[self.view.window removeGestureRecognizer:_tapOutsideGestureRecognizer];
	_tapOutsideGestureRecognizer = tapOutsideGestureRecognizer;
	if (tapOutsideGestureRecognizer)
		[self.view.window addGestureRecognizer:tapOutsideGestureRecognizer];
	
}

- (void) onTap:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
		CGPoint location = [recognizer locationInView:nil];
        if (![self.view pointInside:[self.view convertPoint:location fromView:self.view.window] withEvent:nil]) {
			[self dismissViewControllerAnimated:YES completion:nil];
			self.tapOutsideGestureRecognizer = nil;
        }
	}
}

@end
