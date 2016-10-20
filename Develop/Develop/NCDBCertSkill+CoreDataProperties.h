//
//  NCDBCertSkill+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBCertSkill+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBCertSkill (CoreDataProperties)

+ (NSFetchRequest<NCDBCertSkill *> *)fetchRequest;

@property (nonatomic) int16_t skillLevel;
@property (nullable, nonatomic, retain) NCDBCertMastery *mastery;
@property (nullable, nonatomic, retain) NCDBInvType *type;

@end

NS_ASSUME_NONNULL_END
