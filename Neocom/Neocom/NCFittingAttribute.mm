//
//  NCFittingAttribute.m
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingAttribute.h"
#import "NCFittingProtected.h"

@implementation NCFittingAttribute {
	std::shared_ptr<dgmpp::Attribute> _attribute;
	__weak NCFittingEngine* _engine;
}

- (nonnull instancetype) initWithAttribute:(std::shared_ptr<dgmpp::Attribute> const&) attribute engine:(nonnull NCFittingEngine*) engine {
	if (self = [super init]) {
		_attribute = attribute;
		_engine = engine;
	}
	return self;
}

- (nonnull NCFittingItem*) owner {
	return [NCFittingItem item:_attribute->getOwner() withEngine:_engine];
}

- (NSInteger) attributeID {
	return _attribute->getAttributeID();
}

- (nonnull NSString*) attributeName {
	return [NSString stringWithCString:_attribute->getAttributeName() ?: "" encoding:NSUTF8StringEncoding];
}

- (double) value {
	NCVerifyFittingContext(_engine);
	return _attribute->getValue();
}

- (double) initialValue {
	NCVerifyFittingContext(_engine);
	return _attribute->getInitialValue();
}

- (BOOL) isStackable {
	return _attribute->isStackable();
}

- (BOOL) highIsGood {
	return _attribute->highIsGood();
}


@end
