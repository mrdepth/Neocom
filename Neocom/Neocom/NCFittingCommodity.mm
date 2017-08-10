//
//  NCFittingCommodity.m
//  Neocom
//
//  Created by Artem Shimanski on 22.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingCommodity.h"
#import "NCFittingProtected.h"

@implementation NCFittingCommodity

- (nonnull instancetype) initWithCommodity:(dgmpp::Commodity)commodity engine:(NCFittingEngine *)engine {
	if (self = [self init]) {
		_commodity = std::make_shared<dgmpp::Commodity>(commodity);
		_engine = engine;
	}
	return self;
}

- (nonnull instancetype) init {
	if (self = [super init]) {
	}
	return self;
}

- (NSInteger) typeID {
	return _commodity->getTypeID();
}

- (NSString*) typeName {
	return [NSString stringWithCString:_commodity->getTypeName().c_str() ?: "" encoding:NSUTF8StringEncoding];
}

- (NSInteger) quantity {
	NCVerifyFittingContext(self.engine);
	return _commodity->getQuantity();
}

- (double) itemVolume {
	NCVerifyFittingContext(self.engine);
	return _commodity->getItemVolume();
}

- (double) volume {
	NCVerifyFittingContext(self.engine);
	return _commodity->getVolume();
}

- (NCFittingCommodityTier) tier {
	NCVerifyFittingContext(self.engine);
	return static_cast<NCFittingCommodityTier>(_commodity->getTier());
}


@end
