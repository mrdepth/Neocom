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

- (nonnull instancetype) initWithContentType:(NSInteger) typeID quantity: (NSInteger) quantity engine:(NCFittingEngine*) engine {
	if (self = [self init]) {
		
		_commodity = std::make_shared<dgmpp::Commodity>(engine.engine, static_cast<dgmpp::TypeID>(typeID), quantity);
		_engine = engine;
	}
	return self;
}


- (NSInteger) typeID {
	return static_cast<NSInteger>(static_cast<NSInteger>(_commodity->getTypeID()));
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
