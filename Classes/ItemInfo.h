//
//  ItemInfo.h
//  EVEUniverse
//
//  Created by Mr. Depth on 12/15/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "EVEDBAPI.h"
#include "eufe.h"

@interface ItemInfo: EVEDBInvType
@property (nonatomic, readonly, assign) eufe::Item* item;

+ (id) itemInfoWithItem:(eufe::Item*) aItem error:(NSError **)errorPtr;
- (id) initWithItem:(eufe::Item*) aItem error:(NSError **)errorPtr;
- (void) updateAttributes;

@end
