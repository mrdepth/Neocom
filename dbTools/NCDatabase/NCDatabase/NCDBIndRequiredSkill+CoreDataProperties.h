//
//  NCDBIndRequiredSkill+CoreDataProperties.h
//  NCDatabase
//
//  Created by Артем Шиманский on 30.12.15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBIndRequiredSkill.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBIndRequiredSkill (CoreDataProperties)

@property (nonatomic) int16_t skillLevel;
@property (nullable, nonatomic, retain) NCDBIndActivity *activity;
@property (nullable, nonatomic, retain) NCDBInvType *skillType;

@end

NS_ASSUME_NONNULL_END
