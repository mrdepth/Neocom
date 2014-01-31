//
//  NCFitShip.h
//  Neocom
//
//  Created by Артем Шиманский on 31.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCLoadout.h"
#import "eufe.h"

@interface NCFitShip : NSObject
@property (nonatomic, strong) NCLoadout* loadout;
@property (nonatomic, assign) eufe::Character* character;
@property (nonatomic, assign) EVEDBInvType* type;
@property (nonatomic, strong) NSString* loadoutName;

- (id) initWithLoadout:(NCLoadout*) loadout;
- (id) initWithType:(EVEDBInvType*) type;

- (void) save;
- (void) load;

- (void) setSkillLevels:(NSDictionary*) skillLevels;


@end
