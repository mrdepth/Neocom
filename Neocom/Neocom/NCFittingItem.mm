//
//  NCFittingItem.m
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingItem.h"
#import "NCFittingProtected.h"

@interface NCFittingAttributes()
@property (weak, nonatomic) NCFittingItem* item;
@end

@implementation NCFittingAttributes

- (nonnull instancetype) initWithItem:(nonnull NCFittingItem*) item {
	if (self = [super init]) {
		self.item = item;
	}
	return self;
}

- (nullable NCFittingAttribute*) objectAtIndexedSubscript:(NSInteger) attributeID {
	auto attribute = self.item->_item->getAttribute(static_cast<dgmpp::TypeID>(attributeID));
	return attribute ? [[NCFittingAttribute alloc] initWithAttribute:attribute] : nil;
}

@end

@implementation NCFittingItem

- (nonnull instancetype) initWithItem:(std::shared_ptr<dgmpp::Item> const&) item {
	if (self = [super init]) {
		_item = item;
	}
	return self;
}

- (NSInteger) typeID {
	return _item->getTypeID();
}

- (nonnull NSString*) typeName {
	return [NSString stringWithCString:_item->getTypeName() ?: "" encoding:NSUTF8StringEncoding];
}

- (nonnull NSString*) groupName {
	return [NSString stringWithCString:_item->getGroupName() ?: "" encoding:NSUTF8StringEncoding];
}

- (NSInteger) groupID {
	return _item->getGroupID();
}

- (NSInteger) categoryID {
	return _item->getCategoryID();
}

- (nullable NCFittingItem*) owner {
	return _item->getOwner() ? [[NCFittingItem alloc] initWithItem:_item->getOwner()] : nil;
}

- (nonnull NCFittingAttributes*) attributes {
	if (!_attributes) {
		_attributes = [[NCFittingAttributes alloc] initWithItem: self];
	}
	return _attributes;
}

- (BOOL) isEqual:(id)object {
	return self.hash == [object hash];
}

- (NSUInteger) hash {
	return (intptr_t) _item.get();
}


@end
