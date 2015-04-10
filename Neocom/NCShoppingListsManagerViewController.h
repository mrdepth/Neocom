//
//  NCShoppingListsManagerViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 30.03.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@class NCShoppingListsManagerViewController;
@class NCShoppingList;
@protocol NCShoppingListsManagerViewControllerDelegate<NSObject>
- (void) shoppingListsManagerViewController:(NCShoppingListsManagerViewController*) controller didSelectShoppingList:(NCShoppingList*) shoppingList;
@end

@interface NCShoppingListsManagerViewController : NCTableViewController
@property (nonatomic, weak) id<NCShoppingListsManagerViewControllerDelegate> delegate;

@end
