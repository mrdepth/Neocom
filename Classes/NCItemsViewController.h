//
//  NCItemsViewController.h
//  EVEUniverse
//
//  Created by mr_depth on 03.08.13.
//
//

#import <UIKit/UIKit.h>

@class EVEDBInvType;
@interface NCItemsViewController : UINavigationController
@property (nonatomic, strong) NSArray* conditions;
@property (nonatomic, copy) void (^completionHandler)(EVEDBInvType* type);
@end
