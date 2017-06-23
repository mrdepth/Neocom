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
	std::weak_ptr<dgmpp::Item> _item;
	__weak NCFittingEngine* _engine;
}

- (nonnull instancetype) initWithItem:(std::shared_ptr<dgmpp::Item> const&) item engine:(nonnull NCFittingEngine*) engine {
	if (self = [super init]) {
		_item = item;
		_engine = engine;
	}
	return self;
}

- (std::shared_ptr<dgmpp::Item>) item {
	return _item.lock();
}

- (nullable NCFittingAttribute*) objectAtIndexedSubscript:(NSInteger) attributeID {
	NCVerifyFittingContext(_engine);
	std::shared_ptr<dgmpp::Item> item = self.item;
	if (item) {
		auto attribute = item->getAttribute(static_cast<dgmpp::TypeID>(attributeID));
		return attribute ? [[NCFittingAttribute alloc] initWithAttribute:attribute engine:_engine] : nil;
	}
	else {
		return nil;
	}
}

@end

@implementation NCFittingItem {
	NCFittingAttributes* _attributes;
	std::weak_ptr<dgmpp::Item> _item;
}

- (nonnull instancetype) initWithItem:(std::shared_ptr<dgmpp::Item> const&) item engine:(nonnull NCFittingEngine*) engine {
	if (self = [self init]) {
		_item = item;
		_engine = engine;
	}
	return self;
}

- (std::shared_ptr<dgmpp::Item>) item {
	return _item.lock();
}

- (void) setItem:(std::shared_ptr<dgmpp::Item>)item {
	_item = item;
}

+ (nullable instancetype) item:(std::shared_ptr<dgmpp::Item> const&) item withEngine:(nonnull NCFittingEngine*) engine {
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
	else if (std::dynamic_pointer_cast<dgmpp::Area>(item) != nullptr)
		return [[NCFittingArea alloc] initWithItem:item engine:engine];
	else
		return [[NCFittingItem alloc] initWithItem:item engine:engine];
		
}

- (nonnull instancetype) init {
	if (self = [super init]) {
	}
	return self;
}

- (NSInteger) typeID {
	std::shared_ptr<dgmpp::Item> item = self.item;
	return item ? item->getTypeID() : 0;
}

- (nonnull NSString*) typeName {
	std::shared_ptr<dgmpp::Item> item = self.item;
	return item ? [NSString stringWithCString:item->getTypeName() ?: "" encoding:NSUTF8StringEncoding] : @"";
}

- (nonnull NSString*) groupName {
	std::shared_ptr<dgmpp::Item> item = self.item;
	return item ? [NSString stringWithCString:item->getGroupName() ?: "" encoding:NSUTF8StringEncoding] : @"";
}

- (NSInteger) groupID {
	std::shared_ptr<dgmpp::Item> item = self.item;
	return item ? item->getGroupID() : 0;
}

- (NSInteger) categoryID {
	std::shared_ptr<dgmpp::Item> item = self.item;
	return item ? item->getCategoryID() : 0;
}

- (nullable NCFittingItem*) owner {
	std::shared_ptr<dgmpp::Item> item = self.item;
	return item ? (item->getOwner() ? [NCFittingItem item:item->getOwner() withEngine:_engine] : nil) : nil;
}

- (nonnull NCFittingAttributes*) attributes {
	NCVerifyFittingContext(self.engine);
	if (!_attributes) {
		std::shared_ptr<dgmpp::Item> item = self.item;
		if (item) {
			_attributes = [[NCFittingAttributes alloc] initWithItem: item engine:_engine];
		}
	}
	return _attributes;
}

- (BOOL) isEqual:(id)object {
	return self.hash == [object hash];
}

- (NSUInteger) hash {
	std::shared_ptr<dgmpp::Item> item = self.item;
	return (intptr_t) item.get();
}

- (id)copyWithZone:(nullable NSZone *)zone {
	std::shared_ptr<dgmpp::Item> item = self.item;
	return item ? [[NCFittingItem allocWithZone:zone] initWithItem:item engine:_engine] : nil;
}

@end
