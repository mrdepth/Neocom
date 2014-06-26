//
//  NCDBRamTypeRequirement.h
//  NCDatabase
//
//  Created by Артем Шиманский on 19.06.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBInvType, NCDBRamActivity;

@interface NCDBRamTypeRequirement : NSManagedObject

@property (nonatomic) float damagePerJob;
@property (nonatomic) int32_t quantity;
@property (nonatomic) int32_t recycle;
@property (nonatomic, retain) NCDBRamActivity *activity;
@property (nonatomic, retain) NCDBInvType *requiredType;
@property (nonatomic, retain) NCDBInvType *type;

@end
