//
//  NCDBInvTypeRequiredSkill.h
//  NCDatabase
//
//  Created by Shimanski Artem on 15.06.14.
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
