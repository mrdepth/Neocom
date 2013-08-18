//
//  KillNetFilterDateViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 14.11.12.
//
//

#import "KillNetFilterDateViewController.h"
#import "appearance.h"

@interface KillNetFilterDateViewController ()
- (IBAction)onDone:(id)sender;
- (void) update;
@end

@implementation KillNetFilterDateViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	self.contentSizeForViewInPopover = self.view.frame.size;
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStyleDone target:self action:@selector(onDone:)];
	self.cell.groupStyle = GroupedCellGroupStyleSingle;
	self.cell.textLabel.text = self.title;

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
	self.cell.detailTextLabel.text = [formatter stringFromDate:self.date];
	[self.cell setNeedsLayout];
}

@end
