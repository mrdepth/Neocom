//
//  NCFittingSchematic.m
//  Neocom
//
//  Created by Artem Shimanski on 22.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingSchematic.h"
#import "NCFittingProtected.h"

@implementation NCFittingSchematic {
	std::weak_ptr<dgmpp::Schematic> _schematic;
	NSInteger _schematicID;
}

- (nonnull instancetype) initWithSchematic:(const std::shared_ptr<dgmpp::Schematic> &)schematic engine:(NCFittingEngine *)engine {
	if (self = [self init]) {
		_schematic = schematic;
		_engine = engine;
	}
	return self;
}

- (nonnull instancetype) initWithSchematicID:(NSInteger)schematicID {
	if (self = [super init]) {
		_schematicID = schematicID;
	}
	return self;
}

- (nonnull instancetype) init {
	if (self = [super init]) {
	}
	return self;
}


- (std::shared_ptr<dgmpp::Schematic>) schematic {
	return _schematic.lock();
}

- (void) setSchematic:(std::shared_ptr<dgmpp::Schematic>)schematic {
	_schematic = schematic;
}

- (NSInteger) schematicID {
	auto schematic = self.schematic;
	return schematic ? schematic->getSchematicID() : _schematicID;

}

- (NSTimeInterval) cycleTime {
	NCVerifyFittingContext(self.engine);
	auto schematic = self.schematic;
	return schematic ? schematic->getCycleTime() : 0;
}

- (NCFittingCommodity*) output {
	NCVerifyFittingContext(self.engine);
	auto schematic = self.schematic;
	return schematic ? [[NCFittingCommodity alloc] initWithCommodity:schematic->getOutput() engine:self.engine] : 0;
}

- (NSArray<NCFittingCommodity*>*) inputs {
	NCVerifyFittingContext(self.engine);
	auto schematic = self.schematic;
	if (schematic) {
		NSMutableArray* array = [NSMutableArray new];
		NCFittingEngine* engine = self.engine;
		for (auto i: schematic->getInputs()) {
			[array addObject:[[NCFittingCommodity alloc] initWithCommodity:i engine:engine]];
		}
		return array;
	}
	else {
		return @[];
	}
}

@end
