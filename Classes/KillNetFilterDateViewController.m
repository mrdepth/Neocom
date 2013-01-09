//
//  KillNetFilterDateViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 14.11.12.
//
//

#import "KillNetFilterDateViewController.h"

@interface KillNetFilterDateViewController ()
- (IBAction)onDone:(id)sender;
- (void) update;
@end

@implementation KillNetFilterDateViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.contentSizeForViewInPopover = self.view.frame.size;
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStyleDone target:self action:@selector(onDone:)] autorelease];
	self.titleLabel.text = self.title;

	self.datePicker.minimumDate = self.minimumDate;
	self.datePicker.maximumDate = self.maximumDate;
	
	if (!self.date)
		self.date = [NSDate date];
	self.datePicker.date = self.date;
	[self update];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
	[_titleLabel release];
	[_valueLabel release];
	[_datePicker release];
	[_minimumDate release];
	[_maximumDate release];
	[_date release];
	[super dealloc];
}

- (void)viewDidUnload {
	[self setTitleLabel:nil];
	[self setValueLabel:nil];
	[self setDatePicker:nil];
	[super viewDidUnload];
}

- (IBAction)onChangeDate:(id)sender {
	self.date = self.datePicker.date;
	[self update];
}

#pragma mark - Private

- (IBAction)onDone:(id)sender {
	[self.delegate killNetFilterDateViewController:self didSelectDate:self.date];
}

- (void) update {
	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy.MM.dd"];
	self.valueLabel.text = [formatter stringFromDate:self.date];
	[formatter release];
}

@end
