//
//  EVEAssetListItem+AssetsViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 2/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EVEOnlineAPI.h"
#import "EVEDBInvType.h"

@interface EVEAssetListItem (AssetsViewController)
@property (nonatomic, strong) EVEDBInvType* type;
@property (nonatomic, strong) EVELocationsItem* location;
@property (nonatomic, strong) NSString* characterName;
@property (nonatomic, copy) NSString* name;
@end
