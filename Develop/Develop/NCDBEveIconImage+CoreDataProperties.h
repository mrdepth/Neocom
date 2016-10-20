//
//  NCDBEveIconImage+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBEveIconImage+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBEveIconImage (CoreDataProperties)

+ (NSFetchRequest<NCDBEveIconImage *> *)fetchRequest;

@property (nullable, nonatomic, retain) NSObject *image;
@property (nullable, nonatomic, retain) NCDBEveIcon *icon;

@end

NS_ASSUME_NONNULL_END
