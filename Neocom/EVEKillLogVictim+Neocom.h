//
//  EVEKillLogVictim+Neocom.h
//  Neocom
//
//  Created by Артем Шиманский on 24.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "EVEKillLog.h"

@class NCDBInvType;
@interface EVEKillLogVictim (Neocom)

@property (nonatomic, strong) NCDBInvType* shipType;

@end
