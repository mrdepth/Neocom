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
}

- (nonnull instancetype) initWithAttribute:(std::shared_ptr<dgmpp::Attribute> const&) attribute {
	if (self = [super init]) {
		_attribute = attribute;
	}
	return self;
}

- (nonnull NCFittingItem*) owner {
	return [[NCFittingItem alloc] initWithItem:_attribute->getOwner()];
}

- (NSInteger) attributeID {
	return _attribute->getAttributeID();
}

- (nonnull NSString*) attributeName {
	return [NSString stringWithCString:_attribute->getAttributeName() ?: "" encoding:NSUTF8StringEncoding];
}

- (double) value {
	return _attribute->getValue();
}

- (BOOL) isStackable {
	return _attribute->isStackable();
}

- (BOOL) highIsGood {
	return _attribute->highIsGood();
}


@end
