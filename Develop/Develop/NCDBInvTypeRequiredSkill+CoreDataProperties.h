//
//  NCDBInvTypeRequiredSkill+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBInvTypeRequiredSkill+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBInvTypeRequiredSkill (CoreDataProperties)

+ (NSFetchRequest<NCDBInvTypeRequiredSkill *> *)fetchRequest;

@property (nonatomic) int16_t skillLevel;
@property (nullable, nonatomic, retain) NCDBInvType *skillType;
@property (nullable, nonatomic, retain) NCDBInvType *type;

@end

NS_ASSUME_NONNULL_END
