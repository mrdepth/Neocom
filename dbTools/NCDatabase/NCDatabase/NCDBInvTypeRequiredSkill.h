//
//  NCDBInvTypeRequiredSkill.h
//  NCDatabase
//
//  Created by Артем Шиманский on 19.06.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBInvType;

@interface NCDBInvTypeRequiredSkill : NSManagedObject

@property (nonatomic) int16_t skillLevel;
@property (nonatomic, retain) NCDBInvType *skillType;
@property (nonatomic, retain) NCDBInvType *type;

@end
