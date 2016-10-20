//
//  NCDBIndRequiredSkill+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBIndRequiredSkill+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBIndRequiredSkill (CoreDataProperties)

+ (NSFetchRequest<NCDBIndRequiredSkill *> *)fetchRequest;

@property (nonatomic) int16_t skillLevel;
@property (nullable, nonatomic, retain) NCDBIndActivity *activity;
@property (nullable, nonatomic, retain) NCDBInvType *skillType;

@end

NS_ASSUME_NONNULL_END
