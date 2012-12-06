//
//  DonationViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 2/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DonationViewController.h"
#import "EVERequestsCache.h"
#import "Globals.h"
#import "EVEUniverseAppDelegate.h"
#import "EVEAccount.h"

@interface DonationViewController(Private)

- (void) reload;

@end


@implementation DonationViewController
@synthesize upgradeView;
@synthesize donateView;



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
	self.title = @"Donation";
	[self reload];
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.upgradeView = nil;
	self.donateView = nil;
}


- (void)dealloc {
	[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
	[upgradeView release];
	[donateView release];
	
    [super dealloc];
}

- (IBAction) onUpgrade:(id) sender {
	SKPaymentQueue *paymentQueue = [SKPaymentQueue defaultQueue];
	if (paymentQueue.transactions.count > 0)
		return;
	
	[[Globals appDelegate] setInAppStatus:YES];
	[paymentQueue addTransactionObserver:self];
	SKMutablePayment *payment = [[[SKMutablePayment alloc] init] autorelease];
	payment.productIdentifier = @"com.shimanski.eveuniverse.full";
	payment.quantity = 1;
	[paymentQueue addPayment:payment];
}

- (IBAction) onDonate:(id) sender {
	UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"Donate"
															 delegate:self
													cancelButtonTitle:@"Cancel"
											   destructiveButtonTitle:nil
													otherButtonTitles:@"Donate $1", @"Donate $5", @"Donate $10", nil];
	[actionSheet showFromRect:[sender frame] inView:[sender superview] animated:YES];
	[actionSheet release];
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
		SKMutablePayment *payment = [[[SKMutablePayment alloc] init] autorelease];
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
	UIAlertView* alertView = [[[UIAlertView alloc] initWithTitle:@"Error"
														 message:@"Sorry, but we haven't found your purchases."
														delegate:nil
											   cancelButtonTitle:@"Close"
											   otherButtonTitles:nil] autorelease];
	[alertView show];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
	if (queue.transactions.count == 0) {
		[[Globals appDelegate] setInAppStatus:NO];
		UIAlertView* alertView = [[[UIAlertView alloc] initWithTitle:@"Error"
															 message:@"Sorry, but we haven't found your purchases."
															delegate:nil
												   cancelButtonTitle:@"Close"
												   otherButtonTitles:nil] autorelease];
		[alertView show];
	}
}

@end

@implementation DonationViewController(Private)

- (void) reload {
	if (upgradeView.superview)
		[upgradeView removeFromSuperview];
	if (donateView.superview)
		[upgradeView removeFromSuperview];
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey:SettingsNoAds]) {
		[self.view addSubview:upgradeView];
		upgradeView.frame = CGRectMake(0, 0, upgradeView.frame.size.width, upgradeView.frame.size.height);
	}
	else {
		[self.view addSubview:donateView];
		donateView.frame = CGRectMake(0, 0, donateView.frame.size.width, donateView.frame.size.height);
	}
}

@end
