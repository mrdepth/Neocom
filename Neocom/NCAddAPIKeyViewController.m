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
#import "UIAlertController+Neocom.h"
#import "UIColor+Neocom.h"

@interface NCAddAPIKeyViewController ()<ASHTTPServerDelegate>
@property (nonatomic, strong) ASHTTPServer* server;
@property (nonatomic, strong) NCTaskManager* taskManager;
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
	if (!self.tableView.backgroundView) {
		UIView* view = [[UIView alloc] initWithFrame:CGRectZero];
		view.backgroundColor = [UIColor clearColor];
		self.tableView.backgroundView = view;
	}
	
	self.tableView.backgroundColor = [UIColor appearanceTableViewBackgroundColor];
	self.tableView.separatorColor = [UIColor appearanceTableViewSeparatorColor];
	
	self.taskManager = [[NCTaskManager alloc] initWithViewController:self];
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
	
	NCAccountsManager* accountsManager = [NCAccountsManager sharedManager];
	if (accountsManager)
		[accountsManager addAPIKeyWithKeyID:keyID vCode:vCode completionBlock:^(NSArray *accounts, NSError *error) {
			if (error) {
				[self presentViewController:[UIAlertController alertWithError:error] animated:YES completion:nil];
			}
			else {
				[self presentViewController:[UIAlertController alertWithTitle:nil message:NSLocalizedString(@"API Key added", nil)] animated:YES completion:nil];
				self.keyIDTextField.text = nil;
				self.vCodeTextField.text = nil;
				self.navigationItem.rightBarButtonItem.enabled = NO;
			}
		}];
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.row == 3)
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://support.eveonline.com/api/Key/ActivateInstallLinks"]];
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	cell.backgroundColor = [UIColor appearanceTableViewCellBackgroundColor];
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
	int32_t keyID = [arguments[@"keyID"] intValue];
	NSString* vCode = arguments[@"vCode"];
	
	NSMutableString *page = [NSMutableString stringWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"]] encoding:NSUTF8StringEncoding error:nil];

	NCAccountsManager* manager = [NCAccountsManager sharedManager];
	if (keyID > 0 && vCode.length > 0 && manager) {
		[manager addAPIKeyWithKeyID:keyID vCode:vCode completionBlock:^(NSArray *accounts, NSError *error) {
			[page replaceOccurrencesOfString:@"{error}" withString:NSLocalizedString(@"Key added", nil) options:0 range:NSMakeRange(0, page.length)];
			[page replaceOccurrencesOfString:@"{keyID}" withString:@"" options:0 range:NSMakeRange(0, page.length)];
			[page replaceOccurrencesOfString:@"{vCode}" withString:@"" options:0 range:NSMakeRange(0, page.length)];
			NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:request.URL
																	  statusCode:200
																		bodyData:[page dataUsingEncoding:NSUTF8StringEncoding]
																	headerFields:nil];
			[server finishRequest:request withResponse:response];
		}];
	}
	else {
		if (arguments.count > 0) {
			NSString* errorDescription = nil;
			if (keyID == 0)
				errorDescription = @"Error: Enter <b>KeyID</b>";
			else if (!vCode || vCode.length == 0)
				errorDescription = @"Error: Enter <b>Verification Code</b>";
			
			[page replaceOccurrencesOfString:@"{error}" withString:errorDescription options:0 range:NSMakeRange(0, page.length)];
			[page replaceOccurrencesOfString:@"{keyID}" withString:arguments[@"keyID"] ? arguments[@"keyID"] : @"" options:0 range:NSMakeRange(0, page.length)];
			[page replaceOccurrencesOfString:@"{vCode}" withString:arguments[@"vCode"] ? arguments[@"vCode"] : @"" options:0 range:NSMakeRange(0, page.length)];
		}
		else {
			[page replaceOccurrencesOfString:@"{error}" withString:@"" options:0 range:NSMakeRange(0, page.length)];
			[page replaceOccurrencesOfString:@"{keyID}" withString:@"" options:0 range:NSMakeRange(0, page.length)];
			[page replaceOccurrencesOfString:@"{vCode}" withString:@"" options:0 range:NSMakeRange(0, page.length)];
		}
		NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:request.URL
																  statusCode:200
																	bodyData:[page dataUsingEncoding:NSUTF8StringEncoding]
																headerFields:nil];
		[server finishRequest:request withResponse:response];
	}
}


@end
