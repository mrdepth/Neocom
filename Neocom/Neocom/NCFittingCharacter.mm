//
//  NCFittingCharacter.m
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingCharacter.h"
#import "NCFittingProtected.h"

struct {
	
} state;

@implementation NCFittingSkills {
	std::shared_ptr<dgmpp::Character> _character;
}

- (nonnull instancetype) initWithCharacter:(std::shared_ptr<dgmpp::Character> const&) character {
	if (self = [super init]) {
		_character = character;
	}
	return self;
}

- (nullable NCFittingSkill*) objectAtIndexedSubscript:(NSInteger) typeID {
	auto skill = _character->getSkill(static_cast<dgmpp::TypeID>(typeID));
	return skill ? [[NCFittingSkill alloc] initWithItem:skill] : nil;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained _Nullable [_Nonnull])buffer count:(NSUInteger)len {
	auto skills = _character->getSkills();
	auto i = new typeof(skills.begin());
	*i = skills.begin();
	*(reinterpret_cast<typeof(i)*> (state->extra)) = i;
	
	return 0;
}

@end

@implementation NCFittingImplants {
	std::shared_ptr<dgmpp::Character> _character;
}

- (nonnull instancetype) initWithCharacter:(std::shared_ptr<dgmpp::Character> const&) character {
	if (self = [super init]) {
		_character = character;
	}
	return self;
}

- (nullable NCFittingImplant*) objectAtIndexedSubscript:(NSInteger) slot {
	auto implant = _character->getImplant(static_cast<int>(slot));
	return implant ? [[NCFittingImplant alloc] initWithItem:implant] : nil;
}

@end

@implementation NCFittingBoosters {
	std::shared_ptr<dgmpp::Character> _character;
}

- (nonnull instancetype) initWithCharacter:(std::shared_ptr<dgmpp::Character> const&) character {
	if (self = [super init]) {
		_character = character;
	}
	return self;
}

- (nullable NCFittingBooster*) objectAtIndexedSubscript:(NSInteger) slot {
	auto booster = _character->getBooster(static_cast<int>(slot));
	return booster ? [[NCFittingBooster alloc] initWithItem:booster] : nil;
}

@end

@implementation NCFittingCharacter {
	NCFittingSkills* _skills;
	NCFittingImplants* _implants;
	NCFittingBoosters* _boosters;
}

- (nullable NCFittingImplant*) addImplant:(NSInteger) typeID {
	return [self addImplant:typeID forced:NO];
}

- (nullable NCFittingImplant*) addImplant:(NSInteger) typeID forced:(BOOL) forced {
	auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
	auto implant = character->addImplant(static_cast<dgmpp::TypeID>(typeID), forced);
	return implant ? [[NCFittingImplant alloc] initWithItem:implant] : nil;
}

- (void) removeImplant:(nonnull NCFittingImplant*) implant {
	auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
	auto i = std::dynamic_pointer_cast<dgmpp::Implant>(implant.item);
	character->removeImplant(i);
}

- (nullable NCFittingBooster*) addBooster:(NSInteger) typeID {
	return [self addBooster:typeID forced:NO];
}

- (nullable NCFittingBooster*) addBooster:(NSInteger) typeID forced:(BOOL) forced {
	auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
	auto booster = character->addBooster(static_cast<dgmpp::TypeID>(typeID), forced);
	return booster ? [[NCFittingBooster alloc] initWithItem:booster] : nil;
}

- (void) removeBooster:(nonnull NCFittingBooster*) booster {
	auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
	auto b = std::dynamic_pointer_cast<dgmpp::Booster>(booster.item);
	character->removeBooster(b);
}

- (nullable NCFittingShip*) ship {
	auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
	return character->getShip() ? [[NCFittingShip alloc] initWithItem:character->getShip()] : nil;
}

- (void) setShip:(NCFittingShip *)ship {
	auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
	ship.item = character->setShip(static_cast<dgmpp::TypeID>(ship.typeID));
}

- (nonnull NCFittingSkills*) skills {
	if (!_skills) {
		auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
		_skills = [[NCFittingSkills alloc] initWithCharacter: character];
	}
	return _skills;
}

- (nonnull NCFittingImplants*) implants {
	if (!_implants) {
		auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
		_implants = [[NCFittingImplants alloc] initWithCharacter: character];
	}
	return _implants;
}

- (nonnull NCFittingBoosters*) boosters {
	if (!_boosters) {
		auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
		_boosters = [[NCFittingBoosters alloc] initWithCharacter: character];
	}
	return _boosters;
}


@end
