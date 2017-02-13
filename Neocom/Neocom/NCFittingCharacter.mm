//
//  NCFittingCharacter.m
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingCharacter.h"
#import "NCFittingProtected.h"

@implementation NCFittingSkills {
	std::shared_ptr<dgmpp::Character> _character;
	__weak NCFittingEngine* _engine;
}

- (nonnull instancetype) initWithCharacter:(std::shared_ptr<dgmpp::Character> const&) character engine:(nonnull NCFittingEngine*) engine {
	if (self = [super init]) {
		_character = character;
		_engine = engine;
	}
	return self;
}

- (nullable NCFittingSkill*) objectAtIndexedSubscript:(NSInteger) typeID {
	NCVerifyFittingContext(_engine);
	auto skill = _character->getSkill(static_cast<dgmpp::TypeID>(typeID));
	return skill ? (NCFittingSkill*) [NCFittingItem item:skill withEngine:_engine] : nil;
}

- (NSArray<NCFittingSkill*>*) all {
	NCVerifyFittingContext(_engine);
	NSMutableArray* skills = [NSMutableArray new];
	for (const auto& skill: _character->getSkills()) {
		[skills addObject:[NCFittingItem item:skill.second withEngine:_engine]];
	}
	return skills;
}

- (NSUInteger) count {
	return _character->getSkills().size();
}

@end

@implementation NCFittingImplants {
	std::shared_ptr<dgmpp::Character> _character;
	__weak NCFittingEngine* _engine;
}

- (nonnull instancetype) initWithCharacter:(std::shared_ptr<dgmpp::Character> const&) character engine:(nonnull NCFittingEngine*) engine {
	if (self = [super init]) {
		_character = character;
		_engine = engine;
	}
	return self;
}

- (nullable NCFittingImplant*) objectAtIndexedSubscript:(NSInteger) slot {
	NCVerifyFittingContext(_engine);
	auto implant = _character->getImplant(static_cast<int>(slot));
	return implant ? (NCFittingImplant*) [NCFittingItem item:implant withEngine:_engine] : nil;
}

- (NSArray<NCFittingSkill*>*) all {
	NCVerifyFittingContext(_engine);
	NSMutableArray* implants = [NSMutableArray new];
	for (const auto& implant: _character->getImplants()) {
		[implants addObject:[NCFittingItem item:implant withEngine:_engine]];
	}
	return implants;
}

- (NSUInteger) count {
	return _character->getImplants().size();
}

@end

@implementation NCFittingBoosters {
	std::shared_ptr<dgmpp::Character> _character;
	__weak NCFittingEngine* _engine;
}

- (nonnull instancetype) initWithCharacter:(std::shared_ptr<dgmpp::Character> const&) character engine:(nonnull NCFittingEngine*) engine {
	if (self = [super init]) {
		_character = character;
		_engine = engine;
	}
	return self;
}

- (nullable NCFittingBooster*) objectAtIndexedSubscript:(NSInteger) slot {
	NCVerifyFittingContext(_engine);
	auto booster = _character->getBooster(static_cast<int>(slot));
	return booster ? (NCFittingBooster*) [NCFittingItem item:booster withEngine:_engine] : nil;
}

- (NSArray<NCFittingSkill*>*) all {
	NCVerifyFittingContext(_engine);
	NSMutableArray* boosters = [NSMutableArray new];
	for (const auto& booster: _character->getBoosters()) {
		[boosters addObject:[NCFittingItem item:booster withEngine:_engine]];
	}
	return boosters;
}

- (NSUInteger) count {
	return _character->getBoosters().size();
}


@end

@implementation NCFittingCharacter {
	NCFittingSkills* _skills;
	NCFittingImplants* _implants;
	NCFittingBoosters* _boosters;
}

- (nullable NCFittingImplant*) addImplantWithTypeID:(NSInteger) typeID {
	NCVerifyFittingContext(self.engine);
	return [self addImplantWithTypeID:typeID forced:NO];
}

- (nullable NCFittingImplant*) addImplantWithTypeID:(NSInteger) typeID forced:(BOOL) forced {
	NCVerifyFittingContext(self.engine);
	auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
	auto implant = character->addImplant(static_cast<dgmpp::TypeID>(typeID), forced);
	[self.engine didUpdate];
	return implant ? (NCFittingImplant*) [NCFittingItem item:implant withEngine:self.engine] : nil;
}

- (void) removeImplant:(nonnull NCFittingImplant*) implant {
	NCVerifyFittingContext(self.engine);
	auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
	auto i = std::dynamic_pointer_cast<dgmpp::Implant>(implant.item);
	character->removeImplant(i);
	[self.engine didUpdate];
}

- (nullable NCFittingBooster*) addBoosterWithTypeID:(NSInteger) typeID {
	NCVerifyFittingContext(self.engine);
	return [self addBoosterWithTypeID:typeID forced:NO];
}

- (nullable NCFittingBooster*) addBoosterWithTypeID:(NSInteger) typeID forced:(BOOL) forced {
	NCVerifyFittingContext(self.engine);
	auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
	auto booster = character->addBooster(static_cast<dgmpp::TypeID>(typeID), forced);
	[self.engine didUpdate];
	return booster ? (NCFittingBooster*) [NCFittingItem item:booster withEngine:self.engine] : nil;
}

- (void) removeBooster:(nonnull NCFittingBooster*) booster {
	NCVerifyFittingContext(self.engine);
	auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
	auto b = std::dynamic_pointer_cast<dgmpp::Booster>(booster.item);
	character->removeBooster(b);
	[self.engine didUpdate];
}

- (nullable NCFittingShip*) ship {
	NCVerifyFittingContext(self.engine);
	auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
	return character->getShip() ? (NCFittingShip*) [NCFittingItem item:character->getShip() withEngine:self.engine] : nil;
}

- (void) setShip:(NCFittingShip *)ship {
	NCVerifyFittingContext(self.engine);
	auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
	ship.item = character->setShip(static_cast<dgmpp::TypeID>(ship.typeID));
	[self.engine didUpdate];
}

- (nonnull NCFittingSkills*) skills {
	NCVerifyFittingContext(self.engine);
	if (!_skills) {
		auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
		_skills = [[NCFittingSkills alloc] initWithCharacter: character engine:self.engine];
	}
	return _skills;
}

- (nonnull NCFittingImplants*) implants {
	NCVerifyFittingContext(self.engine);
	if (!_implants) {
		auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
		_implants = [[NCFittingImplants alloc] initWithCharacter: character engine:self.engine];
	}
	return _implants;
}

- (nonnull NCFittingBoosters*) boosters {
	NCVerifyFittingContext(self.engine);
	if (!_boosters) {
		auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
		_boosters = [[NCFittingBoosters alloc] initWithCharacter: character engine:self.engine];
	}
	return _boosters;
}

- (double) droneControlDistance {
	NCVerifyFittingContext(self.engine);
	auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
	return character->getDroneControlDistance();
}

- (nonnull NSString*) characterName {
	NCVerifyFittingContext(self.engine);
	auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
	return [NSString stringWithCString:character->getCharacterName() ?: "" encoding:NSUTF8StringEncoding];
}

- (void) setCharacterName:(NSString *)characterName {
	NCVerifyFittingContext(self.engine);
	auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
	character->setCharacterName(characterName.UTF8String);
}

@end
