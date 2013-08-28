//
//  DonationViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 2/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GroupedCell.h"

@interface DonationViewController : UITableViewController<UIActionSheetDelegate, SKPaymentTransactionObserver>
@property (strong, nonatomic) IBOutlet GroupedCell *upgradeCellView;
@property (strong, nonatomic) IBOutlet GroupedCell *donateCellView;
@property (strong, nonatomic) IBOutlet GroupedCell *upgradeDoneCellView;

- (IBAction) onUpgrade:(id) sender;
- (IBAction) onDonate:(id) sender;
- (IBAction) onRestore:(id)sender;

@end

