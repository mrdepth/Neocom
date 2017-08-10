//
//  NCFittingProductionState.m
//  Neocom
//
//  Created by Artem Shimanski on 22.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingProductionState.h"
#import "NCFittingProtected.h"

@implementation NCFittingProductionState

- (NCFittingCycle*) currentCycle {
	NCVerifyFittingContext(self.engine);
	auto state = std::dynamic_pointer_cast<dgmpp::ProductionState>(self.state);
	return state ? [NCFittingCycle cycle:state->getCurrentCycle() withEngine:self.engine] : nil;
	
}

- (double) efficiency {
	NCVerifyFittingContext(self.engine);
	auto state = std::dynamic_pointer_cast<dgmpp::ProductionState>(self.state);
	return state ? state->getEfficiency() : 0;
	
}


@end
