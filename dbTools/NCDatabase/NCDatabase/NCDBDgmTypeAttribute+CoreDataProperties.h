//
//  NCDBDgmTypeAttribute+CoreDataProperties.h
//  NCDatabase
//
//  Created by Артем Шиманский on 14.03.16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBDgmTypeAttribute.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBDgmTypeAttribute (CoreDataProperties)

@property (nonatomic) float value;
@property (nullable, nonatomic, retain) NCDBDgmAttributeType *attributeType;
@property (nullable, nonatomic, retain) NCDBInvType *type;

@end

NS_ASSUME_NONNULL_END
