//
//  NCDBEufeItemDamage+CoreDataProperties.h
//  NCDatabase
//
//  Created by Артем Шиманский on 07.12.15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBEufeItemDamage.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBEufeItemDamage (CoreDataProperties)

@property (nonatomic) float emAmount;
@property (nonatomic) float explosiveAmount;
@property (nonatomic) float kineticAmount;
@property (nonatomic) float thermalAmount;
@property (nullable, nonatomic, retain) NCDBEufeItem *item;

@end

NS_ASSUME_NONNULL_END
