//
//  NCDBEufeItemRequirements+CoreDataProperties.h
//  Neocom
//
//  Created by Артем Шиманский on 07.12.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
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
