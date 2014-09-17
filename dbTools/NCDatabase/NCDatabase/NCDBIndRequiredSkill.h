//
//  NCDBIndRequiredSkill.h
//  NCDatabase
//
//  Created by Артем Шиманский on 17.09.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBIndActivity, NCDBInvType;

@interface NCDBIndRequiredSkill : NSManagedObject

@property (nonatomic) int16_t skillLevel;
@property (nonatomic, retain) NCDBIndActivity *activity;
@property (nonatomic, retain) NCDBInvType *skillType;

@end
