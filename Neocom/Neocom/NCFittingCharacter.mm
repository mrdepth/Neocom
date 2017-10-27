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
	std::weak_ptr<dgmpp::Character> _character;
	__weak NCFittingEngine* _engine;
}

- (nonnull instancetype) initWithCharacter:(std::shared_ptr<dgmpp::Character> const&) character engine:(nonnull NCFittingEngine*) engine {
	if (self = [super init]) {
		_character = character;
		_engine = engine;
	}
	return self;
}

- (std::shared_ptr<dgmpp::Character>) character {
	return _character.lock();
}


- (nullable NCFittingSkill*) objectAtIndexedSubscript:(NSInteger) typeID {
	NCVerifyFittingContext(_engine);
	std::shared_ptr<dgmpp::Character> character = self.character;
	if (character) {
		auto skill = character->getSkill(static_cast<dgmpp::TypeID>(typeID));
		return skill ? (NCFittingSkill*) [NCFittingItem item:skill withEngine:_engine] : nil;
	}
	else {
		return nil;
	}
}

- (NSArray<NCFittingSkill*>*) all {
	NCVerifyFittingContext(_engine);
	NSMutableArray* skills = [NSMutableArray new];
	std::shared_ptr<dgmpp::Character> character = self.character;
	if (character) {
		for (const auto& skill: character->getSkills()) {
			[skills addObject:[NCFittingItem item:skill.second withEngine:_engine]];
		}
	}
	return skills;
}

- (NSUInteger) count {
	std::shared_ptr<dgmpp::Character> character = self.character;
	return character ? character->getSkills().size() : 0;
}

- (void) setAllSkillsLevel: (NSInteger) level {
	NCVerifyFittingContext(_engine);
	std::shared_ptr<dgmpp::Character> character = self.character;
	if (character) {
		character->setAllSkillsLevel(static_cast<int>(level));
		[_engine updateWithItem: [NCFittingItem item:character withEngine:_engine]];
	}
}

- (void) setLevels: (nonnull NSDictionary<NSNumber*, NSNumber*>*) skillLevels {
	NCVerifyFittingContext(_engine);

	std::shared_ptr<dgmpp::Character> character = self.character;
	if (character) {
		__block std::map<dgmpp::TypeID, int> levels;
		[skillLevels enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
			levels[static_cast<dgmpp::TypeID>(key.intValue)] = obj.intValue;
		}];
		character->setSkillLevels(levels);
		[_engine updateWithItem: [NCFittingItem item:character withEngine:_engine]];
	}
}

@end

@implementation NCFittingImplants {
	std::weak_ptr<dgmpp::Character> _character;
	__weak NCFittingEngine* _engine;
}

- (nonnull instancetype) initWithCharacter:(std::shared_ptr<dgmpp::Character> const&) character engine:(nonnull NCFittingEngine*) engine {
	if (self = [super init]) {
		_character = character;
		_engine = engine;
	}
	return self;
}

- (std::shared_ptr<dgmpp::Character>) character {
	return _character.lock();
}

- (nullable NCFittingImplant*) objectAtIndexedSubscript:(NSInteger) slot {
	NCVerifyFittingContext(_engine);
	
	std::shared_ptr<dgmpp::Character> character = self.character;
	if (character) {
		auto implant = character->getImplant(static_cast<int>(slot));
		return implant ? (NCFittingImplant*) [NCFittingItem item:implant withEngine:_engine] : nil;
	}
	else {
		return nil;
	}
}

- (nonnull NSArray<NCFittingSkill*>*) all {
	NCVerifyFittingContext(_engine);
	
	std::shared_ptr<dgmpp::Character> character = self.character;
	if (character) {
		NSMutableArray* implants = [NSMutableArray new];
		for (const auto& implant: character->getImplants()) {
			[implants addObject:[NCFittingItem item:implant withEngine:_engine]];
		}
		return implants;
	}
	else {
		return @[];
	}
}

- (NSUInteger) count {
	std::shared_ptr<dgmpp::Character> character = self.character;
	return character ? character->getImplants().size() : 0;
}

@end

@implementation NCFittingBoosters {
	std::weak_ptr<dgmpp::Character> _character;
	__weak NCFittingEngine* _engine;
}

- (nonnull instancetype) initWithCharacter:(std::shared_ptr<dgmpp::Character> const&) character engine:(nonnull NCFittingEngine*) engine {
	if (self = [super init]) {
		_character = character;
		_engine = engine;
	}
	return self;
}

- (std::shared_ptr<dgmpp::Character>) character {
	return _character.lock();
}

- (nullable NCFittingBooster*) objectAtIndexedSubscript:(NSInteger) slot {
	NCVerifyFittingContext(_engine);
	
	std::shared_ptr<dgmpp::Character> character = self.character;
	if (character) {
		auto booster = character->getBooster(static_cast<int>(slot));
		return booster ? (NCFittingBooster*) [NCFittingItem item:booster withEngine:_engine] : nil;
	}
	else {
		return nil;
	}
}

- (NSArray<NCFittingSkill*>*) all {
	NCVerifyFittingContext(_engine);
	
	std::shared_ptr<dgmpp::Character> character = self.character;
	if (character) {
		NSMutableArray* boosters = [NSMutableArray new];
		for (const auto& booster: character->getBoosters()) {
			[boosters addObject:[NCFittingItem item:booster withEngine:_engine]];
		}
		return boosters;
	}
	else {
		return @[];
	}
}

- (NSUInteger) count {
	std::shared_ptr<dgmpp::Character> character = self.character;
	return character ? character->getBoosters().size() : 0;
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
	if (character) {
		auto implant = character->addImplant(static_cast<dgmpp::TypeID>(typeID), forced);
		[self.engine updateWithItem: self];
		return implant ? (NCFittingImplant*) [NCFittingItem item:implant withEngine:self.engine] : nil;
	}
	else {
		return nil;
	}
}

- (void) removeImplant:(nonnull NCFittingImplant*) implant {
	NCVerifyFittingContext(self.engine);
	auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
	if (character) {
		auto i = std::dynamic_pointer_cast<dgmpp::Implant>(implant.item);
		character->removeImplant(i);
		[self.engine updateWithItem: self];
	}
}

- (nullable NCFittingBooster*) addBoosterWithTypeID:(NSInteger) typeID {
	NCVerifyFittingContext(self.engine);
	return [self addBoosterWithTypeID:typeID forced:NO];
}

- (nullable NCFittingBooster*) addBoosterWithTypeID:(NSInteger) typeID forced:(BOOL) forced {
	NCVerifyFittingContext(self.engine);
	auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
	if (character) {
		auto booster = character->addBooster(static_cast<dgmpp::TypeID>(typeID), forced);
		[self.engine updateWithItem: self];
		return booster ? (NCFittingBooster*) [NCFittingItem item:booster withEngine:self.engine] : nil;
	}
	else {
		return nil;
	}
}

- (void) removeBooster:(nonnull NCFittingBooster*) booster {
	NCVerifyFittingContext(self.engine);
	auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
	if (character) {
		auto b = std::dynamic_pointer_cast<dgmpp::Booster>(booster.item);
		character->removeBooster(b);
		[self.engine updateWithItem: self];
	}
}

- (nullable NCFittingShip*) ship {
	NCVerifyFittingContext(self.engine);
	auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
	return character ? (character->getShip() ? (NCFittingShip*) [NCFittingItem item:character->getShip() withEngine:self.engine] : nil) : nil;
}

- (void) setShip:(NCFittingShip *)ship {
	NCVerifyFittingContext(self.engine);
	auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
	if (character) {
		auto oldShip = character->getShip();
		if (oldShip)
			[self.engine assignIdentifier:nil forItem:[NCFittingItem item: oldShip withEngine:self.engine]];
		ship.item = character->setShip(static_cast<dgmpp::TypeID>(ship.typeID));
		ship.engine = self.engine;
		[self.engine updateWithItem: self];
	}
}

- (nullable NCFittingStructure*) structure {
	NCVerifyFittingContext(self.engine);
	auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
	return character ? (character->getStructure() ? (NCFittingStructure*) [NCFittingItem item:character->getStructure() withEngine:self.engine] : nil) : nil;
}

- (void) setStructure:(NCFittingStructure *)structure {
	NCVerifyFittingContext(self.engine);
	auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
	if (character) {
		auto oldStructure = character->getStructure();
		if (oldStructure)
			[self.engine assignIdentifier:nil forItem:[NCFittingItem item: oldStructure withEngine:self.engine]];
		structure.item = character->setStructure(static_cast<dgmpp::TypeID>(structure.typeID));
		structure.engine = self.engine;
		[self.engine updateWithItem: self];
	}
}


- (nonnull NCFittingSkills*) skills {
	NCVerifyFittingContext(self.engine);
	if (!_skills) {
		auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
		if (character) {
			_skills = [[NCFittingSkills alloc] initWithCharacter: character engine:self.engine];
		}
	}
	return _skills;
}

- (nonnull NCFittingImplants*) implants {
	NCVerifyFittingContext(self.engine);
	if (!_implants) {
		auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
		if (character) {
			_implants = [[NCFittingImplants alloc] initWithCharacter: character engine:self.engine];
		}
	}
	return _implants;
}

- (nonnull NCFittingBoosters*) boosters {
	NCVerifyFittingContext(self.engine);
	if (!_boosters) {
		auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
		if (character) {
			_boosters = [[NCFittingBoosters alloc] initWithCharacter: character engine:self.engine];
		}
	}
	return _boosters;
}

- (double) droneControlDistance {
	NCVerifyFittingContext(self.engine);
	auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
	return character ? character->getDroneControlDistance() : 0;
}

- (nonnull NSString*) characterName {
	NCVerifyFittingContext(self.engine);
	auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
	return character ? [NSString stringWithCString:character->getCharacterName() ?: "" encoding:NSUTF8StringEncoding] : @"";
}

- (void) setCharacterName:(NSString *)characterName {
	NCVerifyFittingContext(self.engine);
	auto character = std::dynamic_pointer_cast<dgmpp::Character>(self.item);
	if (character) {
		character->setCharacterName(characterName.UTF8String);
		[self.engine updateWithItem: self];
	}
}

@end
