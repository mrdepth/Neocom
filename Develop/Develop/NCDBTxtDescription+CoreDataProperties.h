//
//  NCDBTxtDescription+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBTxtDescription+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBTxtDescription (CoreDataProperties)

+ (NSFetchRequest<NCDBTxtDescription *> *)fetchRequest;

@property (nullable, nonatomic, retain) NSObject *text;
@property (nullable, nonatomic, retain) NCDBCertCertificate *certificate;
@property (nullable, nonatomic, retain) NCDBInvType *type;

@end

NS_ASSUME_NONNULL_END
