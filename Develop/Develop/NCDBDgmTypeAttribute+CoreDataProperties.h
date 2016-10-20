//
//  NCDBDgmTypeAttribute+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBDgmTypeAttribute+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBDgmTypeAttribute (CoreDataProperties)

+ (NSFetchRequest<NCDBDgmTypeAttribute *> *)fetchRequest;

@property (nonatomic) float value;
@property (nullable, nonatomic, retain) NCDBDgmAttributeType *attributeType;
@property (nullable, nonatomic, retain) NCDBInvType *type;

@end

NS_ASSUME_NONNULL_END
