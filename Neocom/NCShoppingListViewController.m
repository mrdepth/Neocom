//
//  NCShoppingListViewController.m
//  Neocom
//
//  Created by Artem Shimanski on 31.03.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCShoppingListViewController.h"
#import "NCShoppingItem+Neocom.h"
#import "NCShoppingList.h"
#import "EVEAssetListItem+Neocom.h"
#import "NCStorage.h"

@interface NCShoppingListViewControllerSection : NSObject
@property (nonatomic, strong) NSMutableArray* rows;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, assign) double price;
@end

@interface NCShoppingListViewControllerRow : NSObject
@property (nonatomic, strong) NCShoppingItem* shoppingItem;
@property (nonatomic, strong) NSArray* assets;
@property (nonatomic, assign) CGFloat progress;
@end

@interface NCShoppingListViewControllerAsset : NSObject
@property (nonatomic, strong) EVEAssetListItem* asset;
@property (nonatomic, strong) EVEAssetListItem* parentAsset;
@end

@implementation NCShoppingListViewControllerSection;
@end

@implementation NCShoppingListViewControllerRow;
@end

@implementation NCShoppingListViewControllerAsset;
@end

@interface NCShoppingListViewController()
- (void) reload;
- (void) reloadAssets;
@end

@implementation NCShoppingListViewController

- (void) viewDidLoad {
	[super viewDidLoad];
}

@end
