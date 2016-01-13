//
//  NCDBInvTypeRequiredSkill+CoreDataProperties.h
//  NCDatabase
//
//  Created by Артем Шиманский on 30.12.15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBInvTypeRequiredSkill.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBInvTypeRequiredSkill (CoreDataProperties)

@property (nonatomic) int16_t skillLevel;
@property (nullable, nonatomic, retain) NCDBInvType *skillType;
@property (nullable, nonatomic, retain) NCDBInvType *type;

@end

NS_ASSUME_NONNULL_END
