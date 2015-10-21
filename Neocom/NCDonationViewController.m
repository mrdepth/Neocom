//
//  NCDonationViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 06.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDonationViewController.h"
#import "ASInAppPurchase.h"
#import "NCDonationCell.h"
#import "UIColor+Neocom.h"

@interface NCDonationViewController ()<SKPaymentTransactionObserver>
@property (nonatomic, assign, getter = isAnAppActive) BOOL inAppActive;
@end

@implementation NCDonationViewController

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
	self.refreshControl = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onUpgrade:(id)sender {
	SKPaymentQueue *paymentQueue = [SKPaymentQueue defaultQueue];
	if (paymentQueue.transactions.count > 0)
		return;
	
	[paymentQueue addTransactionObserver:self];
	SKMutablePayment *payment = [[SKMutablePayment alloc] init];
	payment.productIdentifier = NCInAppFullProductID;
	payment.quantity = 1;
	[paymentQueue addPayment:payment];
	self.inAppActive = YES;
}

- (IBAction)onDonate:(id)sender {
	UIAlertController* controller = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	
	void (^donate)(NSString*) = ^(NSString* productID) {
		SKPaymentQueue *paymentQueue = [SKPaymentQueue defaultQueue];
		if (paymentQueue.transactions.count == 0) {
			[paymentQueue addTransactionObserver:self];
			SKMutablePayment *payment = [[SKMutablePayment alloc] init];
			payment.productIdentifier = productID;
			payment.quantity = 1;
			[paymentQueue addPayment:payment];
			self.inAppActive = YES;
		}
	};
	
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Donate $1", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		donate(NCInAppDonate1ProductID);
	}]];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Donate $5", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		donate(NCInAppDonate5ProductID);
	}]];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Donate $10", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		donate(NCInAppDonate10ProductID);
	}]];

	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
	}]];
	
	[self presentViewController:controller animated:YES completion:nil];
}

- (IBAction)onRestore:(id)sender {
	SKPaymentQueue *paymentQueue = [SKPaymentQueue defaultQueue];
	if (paymentQueue.transactions.count > 0)
		return;
	
	[paymentQueue addTransactionObserver:self];
	[paymentQueue restoreCompletedTransactions];
	
	self.inAppActive = YES;

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}


#pragma mark SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
	for (SKPaymentTransaction *transaction in transactions)
	{
		switch (transaction.transactionState)
		{
			case SKPaymentTransactionStatePurchased:
			case SKPaymentTransactionStateRestored: {
				[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
				self.inAppActive = NO;
				[self.tableView reloadData];
				break;
			}
			case SKPaymentTransactionStateFailed: {
				[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
				self.inAppActive = NO;
				[self.tableView reloadData];
				break;
			}
			default:
				break;
		}
	}
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
	UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
														message:NSLocalizedString(@"Sorry, but we haven't found your purchases.", nil)
													   delegate:nil
											  cancelButtonTitle:NSLocalizedString(@"Close", nil)
											  otherButtonTitles:nil];
	[alertView show];
	self.inAppActive = NO;
	[self.tableView reloadData];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
	if (queue.transactions.count == 0) {
		UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
															message:NSLocalizedString(@"Sorry, but we haven't found your purchases.", nil)
														   delegate:nil
												  cancelButtonTitle:NSLocalizedString(@"Close", nil)
												  otherButtonTitles:nil];
		[alertView show];
	}
	self.inAppActive = NO;
	[self.tableView reloadData];
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (NSString *)tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([ASInAppPurchase inAppPurchaseWithProductID:NCInAppFullProductID].purchased)
		return @"DonateCell";
	else
		return @"UpgradeCell";
}

- (void)tableView:(UITableView *)tableView configureCell:(UITableViewCell *)tableViewCell forRowAtIndexPath:(NSIndexPath *)indexPath {
	NCDonationCell* cell = (NCDonationCell*) tableViewCell;
	if (self.inAppActive) {
		cell.userInteractionEnabled = NO;
		[cell.activityIndicatorView startAnimating];
	}
	else {
		cell.userInteractionEnabled = YES;
		[cell.activityIndicatorView stopAnimating];
	}
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Private

- (void) setInAppActive:(BOOL)inAppActive {
	_inAppActive = inAppActive;
	NCDonationCell* cell = (NCDonationCell*) [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	if (inAppActive) {
		cell.userInteractionEnabled = NO;
		[cell.activityIndicatorView startAnimating];
	}
	else {
		cell.userInteractionEnabled = YES;
		[cell.activityIndicatorView stopAnimating];
	}
}

@end
