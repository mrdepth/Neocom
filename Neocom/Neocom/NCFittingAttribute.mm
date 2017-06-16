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
	std::weak_ptr<dgmpp::Attribute> _attribute;
	__weak NCFittingEngine* _engine;
}

- (nonnull instancetype) initWithAttribute:(std::shared_ptr<dgmpp::Attribute> const&) attribute engine:(nonnull NCFittingEngine*) engine {
	if (self = [super init]) {
		_attribute = attribute;
		_engine = engine;
	}
	return self;
}

- (std::shared_ptr<dgmpp::Attribute>) attribute {
	return _attribute.lock();
}


- (nullable NCFittingItem*) owner {
	std::shared_ptr<dgmpp::Attribute> attribute = self.attribute;
	return attribute ? [NCFittingItem item:attribute->getOwner() withEngine:_engine] : nil;
}

- (NSInteger) attributeID {
	std::shared_ptr<dgmpp::Attribute> attribute = self.attribute;
	return attribute ? attribute->getAttributeID() : 0;
}

- (nonnull NSString*) attributeName {
	std::shared_ptr<dgmpp::Attribute> attribute = self.attribute;
	return attribute ? [NSString stringWithCString:attribute->getAttributeName() ?: "" encoding:NSUTF8StringEncoding] : @"";
}

- (double) value {
	NCVerifyFittingContext(_engine);
	std::shared_ptr<dgmpp::Attribute> attribute = self.attribute;
	return attribute ? attribute->getValue() : 0;
}

- (double) initialValue {
	NCVerifyFittingContext(_engine);
	std::shared_ptr<dgmpp::Attribute> attribute = self.attribute;
	return attribute ? attribute->getInitialValue() : 0;
}

- (BOOL) isStackable {
	std::shared_ptr<dgmpp::Attribute> attribute = self.attribute;
	return attribute ? attribute->isStackable() : NO;
}

- (BOOL) highIsGood {
	std::shared_ptr<dgmpp::Attribute> attribute = self.attribute;
	return attribute ? attribute->highIsGood() : NO;
}


@end
