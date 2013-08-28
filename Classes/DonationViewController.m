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
#import "appearance.h"

typedef enum {
	DonationViewControllerUpgrade,
	DonationViewControllerUpgradeDone,
	DonationViewControllerDonate
} DonationViewControllerMode;

@interface DonationViewController()
@property (nonatomic, assign) DonationViewControllerMode mode;

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
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
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

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    GroupedCell *cell = nil;
	if (self.mode == DonationViewControllerUpgrade)
		cell = self.upgradeCellView;
	else if (self.mode == DonationViewControllerUpgradeDone)
		cell = self.upgradeDoneCellView;
	else
		cell = self.donateCellView;
	cell.groupStyle = GroupedCellGroupStyleSingle;
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.mode == DonationViewControllerUpgrade)
		return 128;
	else if (self.mode == DonationViewControllerUpgradeDone)
		return 40;
	else
		return 91;
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
	if (![[NSUserDefaults standardUserDefaults] boolForKey:SettingsNoAds]) {
		self.mode = DonationViewControllerUpgrade;
	}
	else {
		self.mode = DonationViewControllerDonate;
	}
	[self.tableView reloadData];
}

@end
