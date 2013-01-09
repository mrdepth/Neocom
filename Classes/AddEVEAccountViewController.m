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

@interface AddEVEAccountViewController(Private)

- (void) loadAccountFromPasteboard;
- (void) saveAccount;
- (void) testForSave;
- (void) applicationDidBecomeActive:(NSNotification*) notification;

@end


@implementation AddEVEAccountViewController
@synthesize keyIDTextField;
@synthesize vCodeTextField;
@synthesize saveButton;

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
	[self.navigationItem setRightBarButtonItem:saveButton];
	self.title = NSLocalizedString(@"Add API Key", nil);
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	if (![userDefaults boolForKey:SettingsTipsAddAccount]) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Tip", nil) message:NSLocalizedString(@"To gain access to corporate information, you should add Corp API Key.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
		[alertView show];
		[alertView release];
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
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    // Release any retained subviews of the main view.
	self.keyIDTextField = nil;
	self.vCodeTextField = nil;
	self.saveButton = nil;
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
	[keyIDTextField release];
	[vCodeTextField release];
	[saveButton release];
    [super dealloc];
}

- (IBAction) onBrowser: (id) sender {
	BrowserViewController *controller = [[BrowserViewController alloc] initWithNibName:@"BrowserViewController" bundle:nil];
	//controller.delegate = self;
	controller.startPageURL = [NSURL URLWithString:@"https://support.eveonline.com/api/Key/ActivateInstallLinks"];
	[self presentModalViewController:controller animated:YES];
	[controller release];
}

- (IBAction) onSafari: (id) sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://support.eveonline.com/api/Key/ActivateInstallLinks"]];
}

- (IBAction) onPC: (id) sender {
	PCViewController *controller = [[PCViewController alloc] initWithNibName:@"PCViewController" bundle:nil];
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

- (IBAction) onSave:(id) sender {
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"AddEVEAccountViewController+Save" name:NSLocalizedString(@"Checking API Key", nil)];
	__block NSError *error = nil;
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[[EVEAccountStorage sharedAccountStorage] addAPIKeyWithKeyID:[keyIDTextField.text integerValue] vCode:vCodeTextField.text error:&error];
		[error retain];
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			if (error) {
				[[UIAlertView alertViewWithError:error] show];
			}
			else
				[self.navigationController popViewControllerAnimated:YES];
		}
		[error release];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (IBAction) onToutorial: (id) sender {
	TutorialViewController *controller = [[TutorialViewController alloc] initWithNibName:@"TutorialViewController" bundle:nil];
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

#pragma mark BrowserViewControllerDelegate

- (void) browserViewControllerDidFinish:(BrowserViewController*) controller {
	//[controller dismissModalViewControllerAnimated:YES];
	//[self loadAccountFromPasteboard];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == keyIDTextField)
		[vCodeTextField becomeFirstResponder];
	else if (textField == vCodeTextField)
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
	NSMutableArray *errors = [NSMutableArray array];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		float n = apiKeys.count;
		float i = 0;
		for (NSDictionary *apiKey in apiKeys) {
			operation.progress = i++ / n;
			NSError *error = nil;
			[[EVEAccountStorage sharedAccountStorage] addAPIKeyWithKeyID:[[apiKey valueForKey:@"keyID"] integerValue] vCode:[apiKey valueForKey:@"vCode"] error:&error];
			if (error)
				[errors addObject:[apiKey valueForKey:@"keyID"]];
		}
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			if (errors.count > 0) {
				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
																	message:[NSString stringWithFormat:NSLocalizedString(@"Unable to import keys: %@.", nil), [errors componentsJoinedByString:@","]]
																   delegate:nil
														  cancelButtonTitle:NSLocalizedString(@"Ok", nil)
														  otherButtonTitles:nil];
				[alertView show];
				[alertView release];
			}
			else {
				if ([self.navigationController visibleViewController] == self)
					[self.navigationController popViewControllerAnimated:YES];
			}
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end

@implementation AddEVEAccountViewController(Private)

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
					keyIDTextField.text = [apiKey valueForKey:@"keyID"];
					vCodeTextField.text = [apiKey valueForKey:@"vCode"];
					break;
				}
				else if (apiKeys.count > 1 && [self.navigationController visibleViewController] == self) {
					[pb setValue:@"" forPasteboardType:type];
					APIKeysViewController *controller = [[APIKeysViewController alloc] initWithNibName:@"APIKeysViewController" bundle:nil];
					controller.apiKeys = apiKeys;
					controller.delegate = self;
					[self.navigationController pushViewController:controller animated:YES];
					[controller release];
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
	[account setValue:vCodeTextField.text forKey:@"apiKey"];
	[account setValue:keyIDTextField.text forKey:@"userID"];
	[accounts setValue:account forKey:keyIDTextField.text];
	[accounts writeToURL:url atomically:YES];
	[self.navigationController popViewControllerAnimated:YES];
}

- (void) testForSave {
	if (keyIDTextField.text.length == 0 || vCodeTextField.text.length == 0)
		saveButton.enabled = NO;
	else
		saveButton.enabled = YES;
}

- (void) applicationDidBecomeActive:(NSNotification*) notification {
	[self loadAccountFromPasteboard];
}

@end
