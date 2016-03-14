//
//  NCDBDgmppItemSpaceStructureResources+CoreDataProperties.h
//  NCDatabase
//
//  Created by Артем Шиманский on 14.03.16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBDgmppItemSpaceStructureResources.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBDgmppItemSpaceStructureResources (CoreDataProperties)

@property (nonatomic) int16_t hiSlots;
@property (nonatomic) int16_t launchers;
@property (nonatomic) int16_t lowSlots;
@property (nonatomic) int16_t medSlots;
@property (nonatomic) int16_t rigSlots;
@property (nonatomic) int16_t turrets;
@property (nonatomic) int16_t serviceSlots;
@property (nullable, nonatomic, retain) NCDBDgmppItem *item;

@end

NS_ASSUME_NONNULL_END
