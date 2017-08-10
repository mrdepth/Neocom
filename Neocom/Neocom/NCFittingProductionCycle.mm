//
//  NCFittingProductionCycle.m
//  Neocom
//
//  Created by Artem Shimanski on 22.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingProductionCycle.h"
#import "NCFittingProtected.h"

@implementation NCFittingProductionCycle

- (NCFittingCommodity*) yield {
	NCVerifyFittingContext(self.engine);
	auto cycle = std::dynamic_pointer_cast<dgmpp::ProductionCycle>(self.cycle);
	return cycle ? [[NCFittingCommodity alloc] initWithCommodity:cycle->getYield() engine:self.engine] : nil;

}

- (NCFittingCommodity*) waste {
	NCVerifyFittingContext(self.engine);
	auto cycle = std::dynamic_pointer_cast<dgmpp::ProductionCycle>(self.cycle);
	return cycle ? [[NCFittingCommodity alloc] initWithCommodity:cycle->getWaste() engine:self.engine] : nil;
}


@end
