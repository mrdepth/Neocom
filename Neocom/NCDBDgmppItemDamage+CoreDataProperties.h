//
//  NCDBDgmppItemDamage+CoreDataProperties.h
//  Neocom
//
//  Created by Артем Шиманский on 07.12.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBDgmppItemDamage.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBDgmppItemDamage (CoreDataProperties)

@property (nonatomic) float emAmount;
@property (nonatomic) float explosiveAmount;
@property (nonatomic) float kineticAmount;
@property (nonatomic) float thermalAmount;
@property (nullable, nonatomic, retain) NCDBDgmppItem *item;

@end

NS_ASSUME_NONNULL_END
