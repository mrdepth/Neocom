//
//  DronesAmountViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DronesAmountViewController.h"

@interface DronesAmountViewController(Private)

- (void) remove;
- (void) animationDidStop:(NSString*) animationID finished:(NSNumber*) finished context:(void*) context;

@end


@implementation DronesAmountViewController
@synthesize pickerView;
@synthesize backgroundView;
@synthesize contentView;
@synthesize maxAmount;
@synthesize amount;
@synthesize delegate;


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
	[pickerView selectRow:amount - 1 inComponent:0 animated:NO];
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


- (void)dealloc {
	[pickerView release];
	[backgroundView release];
	[contentView release];
    [super dealloc];
}

- (void) presentAnimated:(BOOL) animated {
	[self retain];
	UIWindow *window = [[UIApplication sharedApplication] keyWindow];
	[window addSubview:self.view];
	self.view.frame = CGRectMake(0, window.frame.size.height - self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
	if (animated) {
		backgroundView.alpha = 0;
		contentView.frame = CGRectMake(contentView.frame.origin.x, self.view.frame.size.height, contentView.frame.size.width, contentView.frame.size.height);
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.3];
		backgroundView.alpha = 1;
		contentView.frame = CGRectMake(contentView.frame.origin.x, self.view.frame.size.height - contentView.frame.size.height, contentView.frame.size.width, contentView.frame.size.height);
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
		backgroundView.alpha = 0;
		contentView.frame = CGRectMake(contentView.frame.origin.x, self.view.frame.size.height, contentView.frame.size.width, contentView.frame.size.height);
		[UIView commitAnimations];
	}
	else
		[self remove];
}

- (IBAction) onCancel:(id) sender {
	[delegate dronesAmountViewControllerDidCancel:self];
	[self dismissAnimated:YES];
}

- (IBAction) onDone:(id) sender {
	[delegate dronesAmountViewController:self didSelectAmount:[pickerView selectedRowInComponent:0] + 1];
	[self dismissAnimated:YES];
}


#pragma mark UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)aPickerView {
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)aPickerView numberOfRowsInComponent:(NSInteger)component {
	return maxAmount < amount ? amount : maxAmount;
}

- (NSString *)pickerView:(UIPickerView *)aPickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	return [NSString stringWithFormat:@"%d", row + 1];
}

- (UIView *)pickerView:(UIPickerView *)aPickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
	UILabel *label = (UILabel*) view;
	if (!label) {
		CGRect rect = CGRectMake(0, 0, 0, 0);
		rect.size = [aPickerView rowSizeForComponent:component];
		label = [[[UILabel alloc] initWithFrame:rect] autorelease];
		label.backgroundColor = [UIColor clearColor];
		label.font = [UIFont fontWithName:@"Helvetica-Bold" size:20];
		label.textAlignment = UITextAlignmentCenter;
	}
	label.text = [self pickerView:aPickerView titleForRow:row forComponent:component];
	return label;
}

#pragma mark UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)aPopoverController {
	[popoverController release];
	popoverController = nil;
	[delegate dronesAmountViewController:self didSelectAmount:[pickerView selectedRowInComponent:0] + 1];
}

@end

@implementation DronesAmountViewController(Private)

- (void) remove {
	[self.view removeFromSuperview];
	[self release];
}

- (void) animationDidStop:(NSString*) animationID finished:(NSNumber*) finished context:(void*) contex {
	[self remove];
}

@end