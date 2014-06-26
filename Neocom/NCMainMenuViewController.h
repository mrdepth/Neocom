//
//  NCMainMenuViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 09.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

typedef NS_OPTIONS(NSInteger, NCMarketPricesMonitor) {
	NCMarketPricesMonitorNone = 0,
	NCMarketPricesMonitorExchangeRate = 0x1 << 0,
	NCMarketPricesMonitorPlex = 0x1 << 1,
	NCMarketPricesMonitorMinerals = 0x1 << 2,
	NCMarketPricesMonitorAll = NCMarketPricesMonitorExchangeRate | NCMarketPricesMonitorPlex | NCMarketPricesMonitorMinerals
};


@interface NCMainMenuViewController : NCTableViewController
@property (weak, nonatomic) IBOutlet UILabel *serverStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *serverTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *marqueeLabel;

- (IBAction)onFacebook:(id)sender;
@end
