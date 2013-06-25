//
//  DonationViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 2/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DonationViewController.h"
#import "Globals.h"
#import "EVEUniverseAppDelegate.h"
#import "EVEAccount.h"

@interface DonationViewController()

- (void) reload;

@end


@implementation DonationViewController


// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
 if (self) {
 // Custom initialization.
 }
 return self;
 }
 */


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = NSLocalizedString(@"Remove Ads", nil);
	[self reload];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
	[self setUpgradeDoneView:nil];
    [super viewDidUnload];
	self.upgradeView = nil;
	self.donateView = nil;
}


- (void)dealloc {
	[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (IBAction) onUpgrade:(id) sender {
	SKPaymentQueue *paymentQueue = [SKPaymentQueue defaultQueue];
	if (paymentQueue.transactions.count > 0)
		return;
	
	[[Globals appDelegate] setInAppStatus:YES];
	[paymentQueue addTransactionObserver:self];
	SKMutablePayment *payment = [[SKMutablePayment alloc] init];
	payment.productIdentifier = @"com.shimanski.eveuniverse.full";
	payment.quantity = 1;
	[paymentQueue addPayment:payment];
}

- (IBAction) onDonate:(id) sender {
	UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Donate", nil)
															 delegate:self
													cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
											   destructiveButtonTitle:nil
													otherButtonTitles:NSLocalizedString(@"Donate $1", nil), NSLocalizedString(@"Donate $5", nil), NSLocalizedString(@"Donate $10", nil), nil];
	[actionSheet showFromRect:[sender frame] inView:[sender superview] animated:YES];
}

- (IBAction) onRestore:(id)sender {
	SKPaymentQueue *paymentQueue = [SKPaymentQueue defaultQueue];
	if (paymentQueue.transactions.count > 0)
		return;
	
	[[Globals appDelegate] setInAppStatus:YES];
	[paymentQueue addTransactionObserver:self];
	[paymentQueue restoreCompletedTransactions];
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex != actionSheet.cancelButtonIndex) {
		SKPaymentQueue *paymentQueue = [SKPaymentQueue defaultQueue];
		if (paymentQueue.transactions.count > 0)
			return;
		
		[[Globals appDelegate] setInAppStatus:YES];
		[paymentQueue addTransactionObserver:self];
		SKMutablePayment *payment = [[SKMutablePayment alloc] init];
		if (buttonIndex == 0)
			payment.productIdentifier = @"com.shimanski.eveuniverse.donation";
		else if (buttonIndex == 1)
			payment.productIdentifier = @"com.shimanski.eveuniverse.donation5";
		else if (buttonIndex == 2)
			payment.productIdentifier = @"com.shimanski.eveuniverse.donation10";
		payment.quantity = 1;
		[paymentQueue addPayment:payment];
	}
}

#pragma mark SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
	for (SKPaymentTransaction *transaction in transactions)
	{
		switch (transaction.transactionState)
		{
			case SKPaymentTransactionStatePurchased:
			case SKPaymentTransactionStateRestored:
				[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
				[[Globals appDelegate] setInAppStatus:NO];
				[self performSelector:@selector(reload) withObject:nil afterDelay:0];
				break;
			case SKPaymentTransactionStateFailed:
				[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
				[[Globals appDelegate] setInAppStatus:NO];
				break;
			default:
				break;
		}
	}
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
	[[Globals appDelegate] setInAppStatus:NO];
	UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
														 message:NSLocalizedString(@"Sorry, but we haven't found your purchases.", nil)
														delegate:nil
											   cancelButtonTitle:NSLocalizedString(@"Close", nil)
											   otherButtonTitles:nil];
	[alertView show];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
	if (queue.transactions.count == 0) {
		[[Globals appDelegate] setInAppStatus:NO];
		UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
															 message:NSLocalizedString(@"Sorry, but we haven't found your purchases.", nil)
															delegate:nil
												   cancelButtonTitle:NSLocalizedString(@"Close", nil)
												   otherButtonTitles:nil];
		[alertView show];
	}
}

#pragma mark - Private

- (void) reload {
	if (self.upgradeView.superview)
		[self.upgradeView removeFromSuperview];
	if (self.donateView.superview)
		[self.upgradeView removeFromSuperview];
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey:SettingsNoAds]) {
		[self.view addSubview:self.upgradeView];
		self.upgradeView.frame = CGRectMake(0, 0, self.upgradeView.frame.size.width, self.upgradeView.frame.size.height);
	}
	else {
		[self.view addSubview:self.donateView];
		self.donateView.frame = CGRectMake(0, 0, self.donateView.frame.size.width, self.donateView.frame.size.height);
	}
}

@end
