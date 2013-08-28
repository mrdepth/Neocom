//
//  ItemViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
	ItemViewControllerActivePageNone = 0,
	ItemViewControllerActivePageInfo,
	ItemViewControllerActivePageMarket
} ItemViewControllerActivePage;

@class ItemInfoViewController;
@class MarketInfoViewController;
@class EVEDBInvType;
@interface ItemViewController : UIViewController
@property (nonatomic, strong) IBOutlet ItemInfoViewController *itemInfoViewController;
@property (nonatomic, strong) IBOutlet MarketInfoViewController *marketInfoViewController;
@property (nonatomic, strong) EVEDBInvType *type;
@property (nonatomic, assign) ItemViewControllerActivePage activePage;
@property (nonatomic, strong) IBOutlet UISegmentedControl *pageSegmentControl;

- (IBAction) onChangePage:(id) sender;

@end
