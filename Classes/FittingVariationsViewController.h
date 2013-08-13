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

@interface FittingVariationsViewController : VariationsViewController
@property (nonatomic, strong) ItemInfo* modifiedItem;
@property (nonatomic, copy) void (^completionHandler)(EVEDBInvType* type);
@end
