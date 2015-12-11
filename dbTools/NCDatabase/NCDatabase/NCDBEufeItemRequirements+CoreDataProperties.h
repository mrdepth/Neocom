//
//  NCDBEufeItemRequirements+CoreDataProperties.h
//  NCDatabase
//
//  Created by Артем Шиманский on 07.12.15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBEufeItemRequirements.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBEufeItemRequirements (CoreDataProperties)

@property (nonatomic) float calibration;
@property (nonatomic) float cpu;
@property (nonatomic) float powerGrid;
@property (nullable, nonatomic, retain) NCDBEufeItem *item;

@end

NS_ASSUME_NONNULL_END
