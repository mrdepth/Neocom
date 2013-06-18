//
//  DronesAmountViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DronesAmountViewController.h"

@interface DronesAmountViewController() {
	id _strongSelf;
}
@property (nonatomic, strong) UIPopoverController *popoverController;

- (void) remove;
- (void) animationDidStop:(NSString*) animationID finished:(NSNumber*) finished context:(void*) context;

@end


@implementation DronesAmountViewController
@synthesize popoverController;


// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	[self.pickerView selectRow:self.amount - 1 inComponent:0 animated:NO];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		self.contentSizeForViewInPopover = self.view.frame.size;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.pickerView = nil;
	self.backgroundView = nil;
	self.contentView = nil;
}

- (void) presentAnimated:(BOOL) animated {
	UIWindow *window = [[UIApplication sharedApplication] keyWindow];
	[window addSubview:self.view];
	self.view.frame = CGRectMake(0, window.frame.size.height - self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
	_strongSelf = self;
	if (animated) {
		self.backgroundView.alpha = 0;
		self.contentView.frame = CGRectMake(self.contentView.frame.origin.x, self.view.frame.size.height, self.contentView.frame.size.width, self.contentView.frame.size.height);
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.3];
		self.backgroundView.alpha = 1;
		self.contentView.frame = CGRectMake(self.contentView.frame.origin.x, self.view.frame.size.height - self.contentView.frame.size.height, self.contentView.frame.size.width, self.contentView.frame.size.height);
		[UIView commitAnimations];
	}
}

- (void)presentPopoverFromRect:(CGRect)rect inView:(UIView *)aView permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated {
	if (!popoverController) {
		popoverController = [[UIPopoverController alloc] initWithContentViewController:self];
		popoverController.delegate = self;
	}
	[popoverController presentPopoverFromRect:rect inView:aView permittedArrowDirections:arrowDirections animated:animated];
}

- (void) dismissAnimated:(BOOL) animated {
	if (animated) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.3];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
		self.backgroundView.alpha = 0;
		self.contentView.frame = CGRectMake(self.contentView.frame.origin.x, self.view.frame.size.height, self.contentView.frame.size.width, self.contentView.frame.size.height);
		[UIView commitAnimations];
	}
	else
		[self remove];
}

- (IBAction) onCancel:(id) sender {
	[self.delegate dronesAmountViewControllerDidCancel:self];
	[self dismissAnimated:YES];
}

- (IBAction) onDone:(id) sender {
	[self.delegate dronesAmountViewController:self didSelectAmount:[self.pickerView selectedRowInComponent:0] + 1];
	[self dismissAnimated:YES];
}


#pragma mark UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)aPickerView {
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)aPickerView numberOfRowsInComponent:(NSInteger)component {
	return self.maxAmount < self.amount ? self.amount : self.maxAmount;
}

- (NSString *)pickerView:(UIPickerView *)aPickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	return [NSString stringWithFormat:@"%d", row + 1];
}

- (UIView *)pickerView:(UIPickerView *)aPickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
	UILabel *label = (UILabel*) view;
	if (!label) {
		CGRect rect = CGRectMake(0, 0, 0, 0);
		rect.size = [aPickerView rowSizeForComponent:component];
		label = [[UILabel alloc] initWithFrame:rect];
		label.backgroundColor = [UIColor clearColor];
		label.font = [UIFont fontWithName:@"Helvetica-Bold" size:20];
		label.textAlignment = UITextAlignmentCenter;
	}
	label.text = [self pickerView:aPickerView titleForRow:row forComponent:component];
	return label;
}

#pragma mark UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)aPopoverController {
	self.popoverController = nil;
	[self.delegate dronesAmountViewController:self didSelectAmount:[self.pickerView selectedRowInComponent:0] + 1];
}

#pragma mark - Private

- (void) remove {
	[self.view removeFromSuperview];
	_strongSelf = nil;
}

- (void) animationDidStop:(NSString*) animationID finished:(NSNumber*) finished context:(void*) contex {
	[self remove];
}

@end