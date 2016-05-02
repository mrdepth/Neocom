//
//  NCDBIndProduct+CoreDataProperties.h
//  NCDatabase
//
//  Created by Артем Шиманский on 14.03.16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBIndProduct.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBIndProduct (CoreDataProperties)

@property (nonatomic) float probability;
@property (nonatomic) int32_t quantity;
@property (nullable, nonatomic, retain) NCDBIndActivity *activity;
@property (nullable, nonatomic, retain) NCDBInvType *productType;

@end

NS_ASSUME_NONNULL_END
