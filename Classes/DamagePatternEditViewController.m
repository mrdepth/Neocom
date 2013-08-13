//
//  DamagePatternEditViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DamagePatternEditViewController.h"
#import "DamagePattern.h"
#import "appearance.h"

@interface DamagePatternEditViewController()
- (void) update;
@end

@implementation DamagePatternEditViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onSave:)];
	self.title = self.damagePattern.patternName;
	self.titleTextField.text = self.damagePattern.patternName;
	
	self.emTextField.progress = self.damagePattern.emAmount;
	self.thermalTextField.progress = self.damagePattern.thermalAmount;
	self.kineticTextField.progress = self.damagePattern.kineticAmount;
	self.explosiveTextField.progress = self.damagePattern.explosiveAmount;
	self.emTextField.text = [NSString stringWithFormat:@"%d", (int) (self.damagePattern.emAmount * 100)];
	self.thermalTextField.text = [NSString stringWithFormat:@"%d", (int) (self.damagePattern.thermalAmount * 100)];
	self.kineticTextField.text = [NSString stringWithFormat:@"%d", (int) (self.damagePattern.kineticAmount * 100)];
	self.explosiveTextField.text = [NSString stringWithFormat:@"%d", (int) (self.damagePattern.explosiveAmount * 100)];
	
	self.totalDamageLabel.progress = self.damagePattern.emAmount + self.damagePattern.thermalAmount + self.damagePattern.kineticAmount + self.damagePattern.explosiveAmount;
	self.totalDamageLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Total: %d%%", nil), (int)(self.totalDamageLabel.progress * 100)];

	
    // Do any additional setup after loading the view from its nib.
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.titleTextField becomeFirstResponder];
}

- (IBAction)onSave:(id)sender {
	self.damagePattern.patternName = self.titleTextField.text;
	self.damagePattern.emAmount = self.emTextField.progress;
	self.damagePattern.thermalAmount = self.thermalTextField.progress;
	self.damagePattern.kineticAmount = self.kineticTextField.progress;
	self.damagePattern.explosiveAmount = self.explosiveTextField.progress;
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    // Return the number of sections.
	return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	return 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	self.damageAmountsCellView.groupStyle = GroupedCellGroupStyleSingle;
	return self.damageAmountsCellView;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView*) tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == self.titleTextField)
		[self.emTextField becomeFirstResponder];
	else if (textField == self.emTextField)
		[self.thermalTextField becomeFirstResponder];
	else if (textField == self.thermalTextField)
		[self.kineticTextField becomeFirstResponder];
	else if (textField == self.kineticTextField)
		[self.explosiveTextField becomeFirstResponder];
	return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	[self performSelector:@selector(update) withObject:nil afterDelay:0];
	return YES;
}

#pragma mark - Private

- (void) update {
	self.title = self.titleTextField.text;
	float em = [self.emTextField.text floatValue] / 100.0;
	float thermal = [self.thermalTextField.text floatValue] / 100.0;
	float kinetic = [self.kineticTextField.text floatValue] / 100.0;
	float explosive = [self.explosiveTextField.text floatValue] / 100.0;
	float total = em + thermal + kinetic + explosive;
	self.totalDamageLabel.progress = total;
	self.totalDamageLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Total: %d%%", nil), (int)(total * 100)];
	self.emTextField.progress = em;
	self.thermalTextField.progress = thermal;
	self.kineticTextField.progress = kinetic;
	self.explosiveTextField.progress = explosive;
	
	self.navigationItem.rightBarButtonItem.enabled = fabs(1.0 - total) < 0.001;
}

@end
