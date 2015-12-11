//
//  NCDBCertSkill+CoreDataProperties.h
//  NCDatabase
//
//  Created by Artem Shimanski on 29.11.15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBCertSkill.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBCertSkill (CoreDataProperties)

@property (nonatomic) int16_t skillLevel;
@property (nullable, nonatomic, retain) NCDBCertMastery *mastery;
@property (nullable, nonatomic, retain) NCDBInvType *type;

@end

NS_ASSUME_NONNULL_END
