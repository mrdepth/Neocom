//
//  NCDBWhType.h
//  NCDatabase
//
//  Created by Артем Шиманский on 17.04.15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBInvType;

@interface NCDBWhType : NSManagedObject

@property (nonatomic) int32_t targetSystemClass;
@property (nonatomic) float maxStableTime;
@property (nonatomic) float maxStableMass;
@property (nonatomic) float maxRegeneration;
@property (nonatomic) float maxJumpMass;
@property (nonatomic, retain) NSString * targetSystemClassDisplayName;
@property (nonatomic, retain) NCDBInvType *type;

@end
