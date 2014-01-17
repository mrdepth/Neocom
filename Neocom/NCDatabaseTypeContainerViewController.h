//
//  NCDatabaseTypeContainerViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 15.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, NCDatabaseTypeContainerViewControllerMode) {
	NCDatabaseTypeContainerViewControllerModeTypeInfo,
	NCDatabaseTypeContainerViewControllerModeTypeMarketInfo
};

@class EVEDBInvType;
@interface NCDatabaseTypeContainerViewController : UIViewController
@property (nonatomic, strong) EVEDBInvType* type;
@property (nonatomic, assign) NCDatabaseTypeContainerViewControllerMode mode;

- (IBAction)onChangeMode:(id)sender;
- (void) setMode:(NCDatabaseTypeContainerViewControllerMode)mode animated:(BOOL) animated;

@end
