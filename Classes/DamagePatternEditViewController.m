//
//  DamagePatternEditViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DamagePatternEditViewController.h"
#import "DamagePattern.h"

@interface DamagePatternEditViewController(Private)
- (void) update;
@end

@implementation DamagePatternEditViewController
@synthesize tableView;
@synthesize damageAmountsCellView;
@synthesize titleCellView;
@synthesize titleTextField;
@synthesize emTextField;
@synthesize thermalTextField;
@synthesize kineticTextField;
@synthesize explosiveTextField;
@synthesize totalDamageLabel;
@synthesize damagePattern;

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
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onSave:)] autorelease];
	self.title = damagePattern.patternName;
	titleTextField.text = damagePattern.patternName;
	
	emTextField.progress = damagePattern.emAmount;
	thermalTextField.progress = damagePattern.thermalAmount;
	kineticTextField.progress = damagePattern.kineticAmount;
	explosiveTextField.progress = damagePattern.explosiveAmount;
	emTextField.text = [NSString stringWithFormat:@"%d", (int) (damagePattern.emAmount * 100)];
	thermalTextField.text = [NSString stringWithFormat:@"%d", (int) (damagePattern.thermalAmount * 100)];
	kineticTextField.text = [NSString stringWithFormat:@"%d", (int) (damagePattern.kineticAmount * 100)];
	explosiveTextField.text = [NSString stringWithFormat:@"%d", (int) (damagePattern.explosiveAmount * 100)];
	
	totalDamageLabel.progress = damagePattern.emAmount + damagePattern.thermalAmount + damagePattern.kineticAmount + damagePattern.explosiveAmount;
	totalDamageLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Total: %d%%", nil), (int)(totalDamageLabel.progress * 100)];

	
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
	[titleTextField becomeFirstResponder];
}

- (void)viewDidUnload
{
	[self setTableView:nil];
	[self setDamageAmountsCellView:nil];
	[self setTitleCellView:nil];
	[self setTitleTextField:nil];
	[self setEmTextField:nil];
	[self setThermalTextField:nil];
	[self setKineticTextField:nil];
	[self setExplosiveTextField:nil];
	[self setTotalDamageLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc {
	[tableView release];
	[damageAmountsCellView release];
	[titleCellView release];
	[titleTextField release];
	[emTextField release];
	[thermalTextField release];
	[kineticTextField release];
	[explosiveTextField release];
	[totalDamageLabel release];
	[damagePattern release];
	[super dealloc];
}

- (IBAction)onSave:(id)sender {
	damagePattern.patternName = titleTextField.text;
	damagePattern.emAmount = emTextField.progress;
	damagePattern.thermalAmount = thermalTextField.progress;
	damagePattern.kineticAmount = kineticTextField.progress;
	damagePattern.explosiveAmount = explosiveTextField.progress;
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    // Return the number of sections.
	return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	return 2;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.row == 0 ? titleCellView : damageAmountsCellView;
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 32;
}

- (void)tableView:(UITableView*) aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == titleTextField)
		[emTextField becomeFirstResponder];
	else if (textField == emTextField)
		[thermalTextField becomeFirstResponder];
	else if (textField == thermalTextField)
		[kineticTextField becomeFirstResponder];
	else if (textField == kineticTextField)
		[explosiveTextField becomeFirstResponder];
	return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	[self performSelector:@selector(update) withObject:nil afterDelay:0];
	return YES;
}

@end

@implementation DamagePatternEditViewController(Private)

- (void) update {
	self.title = titleTextField.text;
	float em = [emTextField.text floatValue] / 100.0;
	float thermal = [thermalTextField.text floatValue] / 100.0;
	float kinetic = [kineticTextField.text floatValue] / 100.0;
	float explosive = [explosiveTextField.text floatValue] / 100.0;
	float total = em + thermal + kinetic + explosive;
	totalDamageLabel.progress = total;
	totalDamageLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Total: %d%%", nil), (int)(total * 100)];
	emTextField.progress = em;
	thermalTextField.progress = thermal;
	kineticTextField.progress = kinetic;
	explosiveTextField.progress = explosive;
	
	self.navigationItem.rightBarButtonItem.enabled = fabs(1.0 - total) < 0.001;
}

@end
