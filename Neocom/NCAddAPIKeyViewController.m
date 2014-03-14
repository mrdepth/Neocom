//
//  NCAddAPIKeyViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 18.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCAddAPIKeyViewController.h"
#import "ASHTTPServer.h"
#import "UIDevice+IP.h"
#import "NCAccountsManager.h"
#import "UIAlertView+Error.h"
#import "UIAlertView+Block.h"

@interface NCAddAPIKeyViewController ()<ASHTTPServerDelegate>
@property (nonatomic, strong) ASHTTPServer* server;
@end

@implementation NCAddAPIKeyViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.refreshControl = nil;
	// Do any additional setup after loading the view.
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	self.server = [[ASHTTPServer alloc] initWithName:NSLocalizedString(@"Neocom", nil) port:8080];
	self.server.delegate = self;
	NSError* error = nil;
	if ([self.server startWithError:&error]) {
		NSString* address = [UIDevice localIPAddress];
		if (address) {
			self.urlLabel.text = [NSString stringWithFormat:@"http://%@:8080", address];
			return;
		}
	}
	self.urlLabel.text = NSLocalizedString(@"Check your Wi-Fi settings", nil);
	self.server = nil;
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	self.server = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onSave:(id)sender {
	int32_t keyID = [self.keyIDTextField.text intValue];
	NSString* vCode = self.vCodeTextField.text;
	
	__block NSError* error = nil;
	__block BOOL success = NO;
	[[self taskManager] addTaskWithIndentifier:nil
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NCAccountsManager* accountsManager = [NCAccountsManager defaultManager];
											 success = [accountsManager addAPIKeyWithKeyID:keyID vCode:vCode error:&error];
											 
										 }
							 completionHandler:^(NCTask *task) {
								 if (!success) {
									 [[UIAlertView alertViewWithError:error] show];
								 }
								 else {
									 [[UIAlertView alertViewWithTitle:nil
															  message:NSLocalizedString(@"API Key added", nil)
													cancelButtonTitle:NSLocalizedString(@"Ok", nil)
													otherButtonTitles:nil
													  completionBlock:nil
														  cancelBlock:nil] show];
									 self.keyIDTextField.text = nil;
									 self.vCodeTextField.text = nil;
									 self.navigationItem.rightBarButtonItem.enabled = NO;
								 }
							 }];
}

#pragma mark - Table view data source

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.row == 3)
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://support.eveonline.com/api/Key/ActivateInstallLinks"]];
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == self.keyIDTextField)
		[self.vCodeTextField becomeFirstResponder];
	else if (textField == self.vCodeTextField)
		[self.vCodeTextField resignFirstResponder];
		
	return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	NSString* keyID;
	NSString* vCode;
	if (textField == self.keyIDTextField) {
		keyID = [textField.text stringByReplacingCharactersInRange:range withString:string];
		vCode = self.vCodeTextField.text;
	}
	else {
		keyID = self.keyIDTextField.text;
		vCode = [textField.text stringByReplacingCharactersInRange:range withString:string];
	}
	self.navigationItem.rightBarButtonItem.enabled = keyID.length > 0 && vCode.length > 0;
	return YES;
}

#pragma mark - ASHTTPServerDelegate

- (void) server:(ASHTTPServer*) server didReceiveRequest:(NSURLRequest*) request {
	NSDictionary* arguments = request.arguments;
	
	__block NSData* bodyData = nil;
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NSMutableString *page = [NSMutableString stringWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"]] encoding:NSUTF8StringEncoding error:nil];
											 if (arguments.count > 0) {
												 NSString* errorDescription = nil;
												 if ([arguments[@"keyID"] length] == 0)
													 errorDescription = @"Error: Enter <b>KeyID</b>";
												 else if ([arguments[@"vCode"] length] == 0)
													 errorDescription = @"Error: Enter <b>Verification Code</b>";
												 
												 if (!errorDescription) {
													 int32_t keyID = [arguments[@"keyID"] intValue];
													 NSString* vCode = arguments[@"vCode"];
													 NSError* error = nil;
													 if (![[NCAccountsManager defaultManager] addAPIKeyWithKeyID:keyID vCode:vCode error:&error])
														 errorDescription = [error localizedDescription];
												 }
												 
												 if (errorDescription) {
													 [page replaceOccurrencesOfString:@"{error}" withString:errorDescription options:0 range:NSMakeRange(0, page.length)];
													 [page replaceOccurrencesOfString:@"{keyID}" withString:arguments[@"keyID"] options:0 range:NSMakeRange(0, page.length)];
													 [page replaceOccurrencesOfString:@"{vCode}" withString:arguments[@"vCode"] options:0 range:NSMakeRange(0, page.length)];
												 }
												 else {
													 [page replaceOccurrencesOfString:@"{error}" withString:NSLocalizedString(@"Key added", nil) options:0 range:NSMakeRange(0, page.length)];
													 [page replaceOccurrencesOfString:@"{keyID}" withString:@"" options:0 range:NSMakeRange(0, page.length)];
													 [page replaceOccurrencesOfString:@"{vCode}" withString:@"" options:0 range:NSMakeRange(0, page.length)];
												 }
											 }
											 else {
												 [page replaceOccurrencesOfString:@"{error}" withString:@"" options:0 range:NSMakeRange(0, page.length)];
												 [page replaceOccurrencesOfString:@"{keyID}" withString:@"" options:0 range:NSMakeRange(0, page.length)];
												 [page replaceOccurrencesOfString:@"{vCode}" withString:@"" options:0 range:NSMakeRange(0, page.length)];
											 }
											 bodyData = [page dataUsingEncoding:NSUTF8StringEncoding];
										 }
							 completionHandler:^(NCTask *task) {
								 NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:request.URL
																						   statusCode:200
																							 bodyData:bodyData
																						 headerFields:nil];
								 [server finishRequest:request withResponse:response];
							 }];
}


@end
