//
//  FittingVariationsViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 11.02.13.
//
//

#import "VariationsViewController.h"

@class FittingVariationsViewController;
@class ItemInfo;
@protocol FittingVariationsViewControllerDelegate <NSObject>
- (void) fittingVariationsViewController:(FittingVariationsViewController*) controller didSelectType:(EVEDBInvType*) type;
@end

@interface FittingVariationsViewController : VariationsViewController
@property (nonatomic, assign) id<FittingVariationsViewControllerDelegate> delegate;
@property (nonatomic, retain) ItemInfo* modifiedItem;
@end
