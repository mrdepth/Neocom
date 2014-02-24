//
//  EVEDBInvType+Neocom.h
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "EVEDBAPI.h"
#import "eufe.h"

typedef NS_ENUM(NSInteger, NCTypeCategory) {
	NCTypeCategoryUnknown,
	NCTypeCategoryModule,
	NCTypeCategoryCharge,
	NCTypeCategoryDrone
};

@interface EVEDBInvType (Neocom)
- (eufe::Module::Slot) slot;
- (NCTypeCategory) category;
@end
