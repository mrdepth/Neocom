//
//  EVEKillLogVictim+Neocom.h
//  Neocom
//
//  Created by Артем Шиманский on 24.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "EVEKillLog.h"

@class EVEDBInvType;
@interface EVEKillLogVictim (Neocom)

@property (nonatomic, strong) EVEDBInvType* shipType;

@end
