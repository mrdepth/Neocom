//
//  NCDBRamInstallationTypeContent.h
//  Neocom
//
//  Created by Артем Шиманский on 18.09.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBInvType, NCDBRamAssemblyLineType;

@interface NCDBRamInstallationTypeContent : NSManagedObject

@property (nonatomic) int32_t quantity;
@property (nonatomic, retain) NCDBRamAssemblyLineType *assemblyLineType;
@property (nonatomic, retain) NCDBInvType *installationType;

@end
