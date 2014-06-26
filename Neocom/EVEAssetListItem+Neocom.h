//
//  EVEAssetListItem+Neocom.h
//  Neocom
//
//  Created by Shimanski Artem on 13.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "EVEAssetList.h"
#import "EVEOnlineAPI.h"

@class NCDBInvType;
@interface EVEAssetListItem (Neocom)

@property (nonatomic, strong) NCDBInvType* type;
@property (nonatomic, strong) EVELocationsItem* location;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSString* owner;


@end
