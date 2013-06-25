//
//  AddEVEAccountViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AddEVEAccountViewController.h"
#import "Globals.h"
#import "EVEOnlineAPI.h"
#import "TutorialViewController.h"
#import "PCViewController.h"
#import "APIKeysViewController.h"
#import "UIAlertView+Error.h"

@interface AddEVEAccountViewController()

- (void) loadAccountFromPasteboard;
- (void) saveAccount;
- (void) testForSave;
- (void) applicationDidBecomeActive:(NSNotification*) notification;

@end

@implementation AddEVEAccountViewController


/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	[self.navigationItem setRightBarButtonItem:self.saveButton];
	self.title = NSLocalizedString(@"Add API Key", nil);
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	if (![userDefaults boolForKey:SettingsTipsAddAccount]) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Tip", nil) message:NSLocalizedString(@"To gain access to corporate information, you should add Corp API Key.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
		[alertView show];
		[userDefaults setBool:YES forKey:SettingsTipsAddAccount];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void) viewDidAppear:(BOOL)animated {
	[self loadAccountFromPasteboard];
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    // Release any retained subviews of the main view.
	self.keyIDTextField = nil;
	self.vCodeTextField = nil;
	self.saveButton = nil;
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction) onBrowser: (id) sender {
	BrowserViewController *controller = [[BrowserViewController alloc] initWithNibName:@"BrowserViewController" bundle:nil];
	//controller.delegate = self;
	controller.startPageURL = [NSURL URLWithString:@"https://support.eveonline.com/api/Key/ActivateInstallLinks"];
	[self presentModalViewController:controller animated:YES];
}

- (IBAction) onSafari: (id) sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://support.eveonline.com/api/Key/ActivateInstallLinks"]];
}

- (IBAction) onPC: (id) sender {
	PCViewController *controller = [[PCViewController alloc] initWithNibName:@"PCViewController" bundle:nil];
	[self.navigationController pushViewController:controller animated:YES];
}

- (IBAction) onSave:(id) sender {
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"AddEVEAccountViewController+Save" name:NSLocalizedString(@"Checking API Key", nil)];
	__block NSError *error = nil;
	NSInteger keyID = [self.keyIDTextField.text integerValue];
	NSString* vCode = self.vCodeTextField.text;
	
	[operation addExecutionBlock:^(void) {
		[[EVEAccountStorage sharedAccountStorage] addAPIKeyWithKeyID:keyID vCode:vCode error:&error];
	}];
	
	__weak EUOperation* weakOperation = operation;
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![weakOperation isCancelled]) {
			if (error) {
				[[UIAlertView alertViewWithError:error] show];
			}
			else
				[self.navigationController popViewControllerAnimated:YES];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (IBAction) onToutorial: (id) sender {
	TutorialViewController *controller = [[TutorialViewController alloc] initWithNibName:@"TutorialViewController" bundle:nil];
	[self.navigationController pushViewController:controller animated:YES];
}

#pragma mark BrowserViewControllerDelegate

- (void) browserViewControllerDidFinish:(BrowserViewController*) controller {
	//[controller dismissModalViewControllerAnimated:YES];
	//[self loadAccountFromPasteboard];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == self.keyIDTextField)
		[self.vCodeTextField becomeFirstResponder];
	else if (textField == self.vCodeTextField)
		[textField resignFirstResponder];
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
//	saveButton.enabled = NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	[self testForSave];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	[self performSelector:@selector(testForSave) withObject:nil afterDelay:0];
	return YES;
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0)
		[self saveAccount];
}

#pragma mark APIKeysViewControllerDelegate

- (void) apiKeysViewController:(APIKeysViewController*) controller didSelectAPIKeys:(NSArray*) apiKeys {
	if (apiKeys.count == 0)
		return;
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"AddEVEAccountViewController+MultipleSave" name:NSLocalizedString(@"Checking API Keys", nil)];
	__weak EUOperation* weakOperation = operation;
	
	NSMutableArray *errors = [NSMutableArray array];
	[operation addExecutionBlock:^(void) {
		float n = apiKeys.count;
		float i = 0;
		for (NSDictionary *apiKey in apiKeys) {
			weakOperation.progress = i++ / n;
			NSError *error = nil;
			[[EVEAccountStorage sharedAccountStorage] addAPIKeyWithKeyID:[[apiKey valueForKey:@"keyID"] integerValue] vCode:[apiKey valueForKey:@"vCode"] error:&error];
			if (error)
				[errors addObject:[apiKey valueForKey:@"keyID"]];
		}
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![weakOperation isCancelled]) {
			if (errors.count > 0) {
				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
																	message:[NSString stringWithFormat:NSLocalizedString(@"Unable to import keys: %@.", nil), [errors componentsJoinedByString:@","]]
																   delegate:nil
														  cancelButtonTitle:NSLocalizedString(@"Ok", nil)
														  otherButtonTitles:nil];
				[alertView show];
			}
			else {
				if ([self.navigationController visibleViewController] == self)
					[self.navigationController popViewControllerAnimated:YES];
			}
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

#pragma mark - Private

- (void) loadAccountFromPasteboard {
	UIPasteboard *pb = [UIPasteboard generalPasteboard];
	NSArray *types = [pb pasteboardTypes];
	if (types.count > 0) {
		NSCharacterSet *keyIDCharactersSet = [NSCharacterSet decimalDigitCharacterSet];
		NSCharacterSet *vCodeCharactersSet = [NSCharacterSet alphanumericCharacterSet];
		for (NSString *type in types) {
			NSString *text = [pb valueForPasteboardType:type];
			if ([text isKindOfClass:[NSString class]]) {
				NSMutableArray *apiKeys = [NSMutableArray array];
				NSArray *lines = [text componentsSeparatedByString:@"\n"];
				for (NSString *line in lines) {
					NSArray *columns = [line componentsSeparatedByString:@"\t"];
					if (columns.count >= 3) {
						NSCharacterSet *characterSet1 = [NSCharacterSet characterSetWithCharactersInString:[columns objectAtIndex:0]];
						NSCharacterSet *characterSet2 = [NSCharacterSet characterSetWithCharactersInString:[columns objectAtIndex:2]];
						if ([keyIDCharactersSet isSupersetOfSet:characterSet1] && [vCodeCharactersSet isSupersetOfSet:characterSet2]) {
							[apiKeys addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[columns objectAtIndex:0], @"keyID",
												[columns objectAtIndex:1], @"name",
												[columns objectAtIndex:2], @"vCode",
												[NSNumber numberWithBool:NO], @"selected",
												nil]];
						}
					}
				}
				if (apiKeys.count == 1) {
					[pb setValue:@"" forPasteboardType:type];
					NSDictionary *apiKey = [apiKeys objectAtIndex:0];
					self.keyIDTextField.text = [apiKey valueForKey:@"keyID"];
					self.vCodeTextField.text = [apiKey valueForKey:@"vCode"];
					break;
				}
				else if (apiKeys.count > 1 && [self.navigationController visibleViewController] == self) {
					[pb setValue:@"" forPasteboardType:type];
					APIKeysViewController *controller = [[APIKeysViewController alloc] initWithNibName:@"APIKeysViewController" bundle:nil];
					controller.apiKeys = apiKeys;
					controller.delegate = self;
					[self.navigationController pushViewController:controller animated:YES];
					break;
				}
			}
		}
	}
	[self testForSave];
}

- (void) saveAccount {
	NSString *path = [Globals accountsFilePath];
	NSURL *url = [NSURL fileURLWithPath:path];
	NSMutableDictionary *accounts = [NSMutableDictionary dictionaryWithContentsOfURL:url];
	if (!accounts)
		accounts = [NSMutableDictionary dictionary];
	NSMutableDictionary *account = [NSMutableDictionary dictionary];
	[account setValue:self.vCodeTextField.text forKey:@"apiKey"];
	[account setValue:self.keyIDTextField.text forKey:@"userID"];
	[accounts setValue:account forKey:self.keyIDTextField.text];
	[accounts writeToURL:url atomically:YES];
	[self.navigationController popViewControllerAnimated:YES];
}

- (void) testForSave {
	if (self.keyIDTextField.text.length == 0 || self.vCodeTextField.text.length == 0)
		self.saveButton.enabled = NO;
	else
		self.saveButton.enabled = YES;
}

- (void) applicationDidBecomeActive:(NSNotification*) notification {
	[self loadAccountFromPasteboard];
}

@end
