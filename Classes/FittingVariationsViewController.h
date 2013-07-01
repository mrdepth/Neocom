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
@property (nonatomic, weak) id<FittingVariationsViewControllerDelegate> delegate;
@property (nonatomic, strong) ItemInfo* modifiedItem;
@end
