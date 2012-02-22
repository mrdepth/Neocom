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
@interface ItemViewController : UIViewController {
	ItemInfoViewController *itemInfoViewController;
	MarketInfoViewController *marketInfoViewController;
	UIView *parentView;
	EVEDBInvType *type;
	ItemViewControllerActivePage activePage;
	
	UISegmentedControl *pageSegmentControl;
}
@property (nonatomic, retain) IBOutlet ItemInfoViewController *itemInfoViewController;
@property (nonatomic, retain) IBOutlet MarketInfoViewController *marketInfoViewController;
@property (nonatomic, retain) IBOutlet UIView *parentView;
@property (nonatomic, retain) EVEDBInvType *type;
@property (nonatomic, assign) ItemViewControllerActivePage activePage;
@property (nonatomic, retain) IBOutlet UISegmentedControl *pageSegmentControl;

- (void) setActivePage:(ItemViewControllerActivePage) value animated:(BOOL) animated;

- (IBAction) onChangePage:(id) sender;
- (IBAction) dismissModalViewController:(id) sender;

@end
