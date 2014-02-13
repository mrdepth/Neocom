//
//  EVEAssetListItem+Neocom.h
//  Neocom
//
//  Created by Shimanski Artem on 13.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "EVEAssetList.h"
#import "EVEDBAPI.h"
#import "EVEOnlineAPI.h"

@interface EVEAssetListItem (Neocom)

@property (nonatomic, strong) EVEDBInvType* type;
@property (nonatomic, strong) EVELocationsItem* location;
@property (nonatomic, strong) NSString* title;


@end
