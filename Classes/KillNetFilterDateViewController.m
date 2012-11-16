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
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(onDone:)] autorelease];
	self.tableView.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background1.png"]] autorelease];
	self.titleLabel.text = self.title;

	self.datePicker.minimumDate = self.minimumDate;
	self.datePicker.maximumDate = self.maximumDate;
	
	if (!self.date)
		self.date = [NSDate date];
	self.datePicker.date = self.date;
	[self update];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)dealloc {
	[_titleLabel release];
	[_valueLabel release];
	[_cell release];
	[_datePicker release];
	[_minimumDate release];
	[_maximumDate release];
	[_date release];
	[_tableView release];
	[super dealloc];
}

- (void)viewDidUnload {
	[self setTitleLabel:nil];
	[self setValueLabel:nil];
	[self setCell:nil];
	[self setDatePicker:nil];
	[self setTableView:nil];
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
