//
//  NCFittingDamagePatternEditorViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 04.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingDamagePatternEditorViewController.h"
#import "NCDamagePattern.h"
#import "NCStorage.h"
#import "UIColor+Neocom.h"

@interface NCFittingDamagePatternEditorViewController ()

@end

@implementation NCFittingDamagePatternEditorViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	if (!self.tableView.backgroundView) {
		UIView* view = [[UIView alloc] initWithFrame:CGRectZero];
		view.backgroundColor = [UIColor clearColor];
		self.tableView.backgroundView = view;
	}
	
	self.tableView.backgroundColor = [UIColor appearanceTableViewBackgroundColor];
	self.tableView.separatorColor = [UIColor appearanceTableViewSeparatorColor];
	
	self.title = self.damagePattern.name;

	self.emTextField.progress = self.damagePattern.em;
	self.thermalTextField.progress = self.damagePattern.thermal;
	self.kineticTextField.progress = self.damagePattern.kinetic;
	self.explosiveTextField.progress = self.damagePattern.explosive;
	self.emTextField.text = [NSString stringWithFormat:@"%d", (int) (self.damagePattern.em * 100)];
	self.thermalTextField.text = [NSString stringWithFormat:@"%d", (int) (self.damagePattern.thermal * 100)];
	self.kineticTextField.text = [NSString stringWithFormat:@"%d", (int) (self.damagePattern.kinetic * 100)];
	self.explosiveTextField.text = [NSString stringWithFormat:@"%d", (int) (self.damagePattern.explosive * 100)];
	
	self.totalLabel.progress = self.damagePattern.em + self.damagePattern.thermal + self.damagePattern.kinetic + self.damagePattern.explosive;
	self.totalLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Total: %d%%", nil), (int32_t)(self.totalLabel.progress * 100)];
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	self.damagePattern.em = self.emTextField.progress;
	self.damagePattern.thermal = self.thermalTextField.progress;
	self.damagePattern.kinetic = self.kineticTextField.progress;
	self.damagePattern.explosive = self.explosiveTextField.progress;
	//[[NCStorage sharedStorage] saveContext];
}

- (void) viewDidAppear:(BOOL)animated {
	[self.emTextField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onAction:(id)sender {
	UIAlertController* controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Rename", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
	__block UITextField* renameTextField;
	[controller addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
		textField.text = self.damagePattern.name;
		textField.clearButtonMode = UITextFieldViewModeAlways;
		renameTextField = textField;
	}];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Rename", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		if (renameTextField.text.length > 0) {
			self.damagePattern.name = renameTextField.text;
			self.title = self.damagePattern.name;
		}
	}]];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
	}]];
	
	[self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	cell.backgroundColor = [UIColor appearanceTableViewCellBackgroundColor];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == self.emTextField)
		[self.thermalTextField becomeFirstResponder];
	else if (textField == self.thermalTextField)
		[self.kineticTextField becomeFirstResponder];
	else if (textField == self.kineticTextField)
		[self.explosiveTextField becomeFirstResponder];
	return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	textField.text = [textField.text stringByReplacingCharactersInRange:range withString:string];
	
	float em = [self.emTextField.text floatValue] / 100.0;
	float thermal = [self.thermalTextField.text floatValue] / 100.0;
	float kinetic = [self.kineticTextField.text floatValue] / 100.0;
	float explosive = [self.explosiveTextField.text floatValue] / 100.0;
	float total = em + thermal + kinetic + explosive;
	self.totalLabel.progress = total;
	self.totalLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Total: %d%%", nil), (int32_t)(total * 100)];
	self.emTextField.progress = em;
	self.thermalTextField.progress = thermal;
	self.kineticTextField.progress = kinetic;
	self.explosiveTextField.progress = explosive;

	
	return NO;
}

@end
