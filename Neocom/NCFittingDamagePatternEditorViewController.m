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
#import "UIActionSheet+Block.h"
#import "UIAlertView+Block.h"

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
	self.totalLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Total: %d%%", nil), (int)(self.totalLabel.progress * 100)];
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
	[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackTranslucent
								   title:nil
					   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
				  destructiveButtonTitle:nil
					   otherButtonTitles:@[NSLocalizedString(@"Rename", nil)]
						 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
							 if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
								 UIAlertView* alertView = [UIAlertView alertViewWithTitle:NSLocalizedString(@"Rename", nil)
																				  message:nil
																		cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
																		otherButtonTitles:@[NSLocalizedString(@"Rename", nil)]
																		  completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
																			  if (selectedButtonIndex != alertView.cancelButtonIndex) {
																				  UITextField* textField = [alertView textFieldAtIndex:0];
																				  self.damagePattern.name = textField.text;
																				  self.title = self.damagePattern.name;
																			  }
																		  } cancelBlock:nil];
								 alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
								 UITextField* textField = [alertView textFieldAtIndex:0];
								 textField.text = self.damagePattern.name;
								 [alertView show];
							 }
						 }
							 cancelBlock:nil] showFromBarButtonItem:sender animated:YES];
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
	self.totalLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Total: %d%%", nil), (int)(total * 100)];
	self.emTextField.progress = em;
	self.thermalTextField.progress = thermal;
	self.kineticTextField.progress = kinetic;
	self.explosiveTextField.progress = explosive;

	
	return NO;
}

@end
