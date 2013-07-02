//
//  VariationsViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 11.02.13.
//
//

#import <UIKit/UIKit.h>

@class EVEDBInvType;
@interface VariationsViewController : UITableViewController
@property (nonatomic, strong) EVEDBInvType* type;

- (void) didSelectType:(EVEDBInvType*) type;

@end
