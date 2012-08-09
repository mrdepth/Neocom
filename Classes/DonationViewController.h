//
//  DonationViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 2/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DonationViewController : UIViewController<UIActionSheetDelegate, SKPaymentTransactionObserver> {
	UIView *upgradeView;
	UIView *donateView;
}
@property (nonatomic, retain) IBOutlet UIView *upgradeView;
@property (nonatomic, retain) IBOutlet UIView *donateView;

- (IBAction) onUpgrade:(id) sender;
- (IBAction) onDonate:(id) sender;
- (IBAction) onRestore:(id)sender;

@end

