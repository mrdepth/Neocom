//
//  ItemInfo.h
//  EVEUniverse
//
//  Created by Mr. Depth on 12/15/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "EVEDBInvType.h"
#include "eufe.h"

@interface ItemInfo: EVEDBInvType {
	boost::weak_ptr<eufe::Item> item;
}
@property (nonatomic, readonly) boost::shared_ptr<eufe::Item> item;

+ (id) itemInfoWithItem:(boost::shared_ptr<eufe::Item>) aItem error:(NSError **)errorPtr;
- (id) initWithItem:(boost::shared_ptr<eufe::Item>) aItem error:(NSError **)errorPtr;

@end
