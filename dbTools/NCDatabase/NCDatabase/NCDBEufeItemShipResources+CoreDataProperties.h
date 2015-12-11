//
//  NCDBEufeItemShipResources+CoreDataProperties.h
//  NCDatabase
//
//  Created by Артем Шиманский on 07.12.15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBEufeItemShipResources.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBEufeItemShipResources (CoreDataProperties)

@property (nonatomic) int16_t hiSlots;
@property (nonatomic) int16_t lowSlots;
@property (nonatomic) int16_t medSlots;
@property (nonatomic) int16_t rigSlots;
@property (nonatomic) int16_t turrets;
@property (nonatomic) int16_t launchers;
@property (nullable, nonatomic, retain) NCDBEufeItem *item;

@end

NS_ASSUME_NONNULL_END
