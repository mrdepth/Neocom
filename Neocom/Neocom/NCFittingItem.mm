//
//  NCFittingItem.m
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingItem.h"
#import "NCFittingProtected.h"
#import "NCFittingGang.h"
#import "NCFittingCharacter.h"
#import "NCFittingSkill.h"
#import "NCFittingImplant.h"
#import "NCFittingBooster.h"
#import "NCFittingShip.h"
#import "NCFittingModule.h"
#import "NCFittingDrone.h"
#import "NCFittingCharge.h"

@implementation NCFittingAttributes {
	std::shared_ptr<dgmpp::Item> _item;
	__weak NCFittingEngine* _engine;
}

- (nonnull instancetype) initWithItem:(std::shared_ptr<dgmpp::Item> const&) item engine:(nonnull NCFittingEngine*) engine {
	if (self = [super init]) {
		_item = item;
		_engine = engine;
	}
	return self;
}

- (nullable NCFittingAttribute*) objectAtIndexedSubscript:(NSInteger) attributeID {
	NCVerifyFittingContext(_engine);
	auto attribute = _item->getAttribute(static_cast<dgmpp::TypeID>(attributeID));
	return attribute ? [[NCFittingAttribute alloc] initWithAttribute:attribute engine:_engine] : nil;
}

@end

@implementation NCFittingItem {
	NCFittingAttributes* _attributes;
}

- (nonnull instancetype) initWithItem:(std::shared_ptr<dgmpp::Item> const&) item engine:(nonnull NCFittingEngine*) engine {
	if (self = [self init]) {
		_item = item;
		_engine = engine;
	}
	return self;
}

+ (nonnull instancetype) item:(std::shared_ptr<dgmpp::Item> const&) item withEngine:(nonnull NCFittingEngine*) engine {
	if (!item)
		return nil;
	
	if (std::dynamic_pointer_cast<dgmpp::Gang>(item) != nullptr)
		return [[NCFittingGang alloc] initWithItem:item engine:engine];
	else if (std::dynamic_pointer_cast<dgmpp::Character>(item) != nullptr)
		return [[NCFittingCharacter alloc] initWithItem:item engine:engine];
	else if (std::dynamic_pointer_cast<dgmpp::Ship>(item) != nullptr)
		return [[NCFittingShip alloc] initWithItem:item engine:engine];
	else if (std::dynamic_pointer_cast<dgmpp::Skill>(item) != nullptr)
		return [[NCFittingSkill alloc] initWithItem:item engine:engine];
	else if (std::dynamic_pointer_cast<dgmpp::Implant>(item) != nullptr)
		return [[NCFittingImplant alloc] initWithItem:item engine:engine];
	else if (std::dynamic_pointer_cast<dgmpp::Booster>(item) != nullptr)
		return [[NCFittingBooster alloc] initWithItem:item engine:engine];
	else if (std::dynamic_pointer_cast<dgmpp::Module>(item) != nullptr)
		return [[NCFittingModule alloc] initWithItem:item engine:engine];
	else if (std::dynamic_pointer_cast<dgmpp::Drone>(item) != nullptr)
		return [[NCFittingDrone alloc] initWithItem:item engine:engine];
	else if (std::dynamic_pointer_cast<dgmpp::Charge>(item) != nullptr)
		return [[NCFittingCharge alloc] initWithItem:item engine:engine];
	else
		return [[NCFittingItem alloc] initWithItem:item engine:engine];
		
}

- (nonnull instancetype) init {
	if (self = [super init]) {
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
	return _item->getOwner() ? [[NCFittingItem alloc] initWithItem:_item->getOwner() engine:_engine] : nil;
}

- (nonnull NCFittingAttributes*) attributes {
	NCVerifyFittingContext(self.engine);
	if (!_attributes) {
		_attributes = [[NCFittingAttributes alloc] initWithItem: _item engine:_engine];
	}
	return _attributes;
}

- (BOOL) isEqual:(id)object {
	return self.hash == [object hash];
}

- (NSUInteger) hash {
	return (intptr_t) _item.get();
}

- (id)copyWithZone:(nullable NSZone *)zone {
	return [[NCFittingItem allocWithZone:zone] initWithItem:_item engine:_engine];
}

@end
