//
//  NCDBRamInstallationTypeContent.h
//  NCDatabase
//
//  Created by Shimanski Artem on 15.06.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBInvType, NCDBRamAssemblyLineType;

@interface NCDBRamInstallationTypeContent : NSManagedObject

@property (nonatomic) int32_t quantity;
@property (nonatomic, retain) NCDBRamAssemblyLineType *assemblyLineType;
@property (nonatomic, retain) NCDBInvType *installationType;

@end
