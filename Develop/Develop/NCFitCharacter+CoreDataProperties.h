//
//  NCFitCharacter+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCFitCharacter+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCFitCharacter (CoreDataProperties)

+ (NSFetchRequest<NCFitCharacter *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, retain) NSObject *skills;

@end

NS_ASSUME_NONNULL_END
