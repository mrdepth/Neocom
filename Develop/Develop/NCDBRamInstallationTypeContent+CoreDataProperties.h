//
//  NCDBRamInstallationTypeContent+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBRamInstallationTypeContent+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBRamInstallationTypeContent (CoreDataProperties)

+ (NSFetchRequest<NCDBRamInstallationTypeContent *> *)fetchRequest;

@property (nonatomic) int32_t quantity;
@property (nullable, nonatomic, retain) NCDBRamAssemblyLineType *assemblyLineType;
@property (nullable, nonatomic, retain) NCDBInvType *installationType;

@end

NS_ASSUME_NONNULL_END
