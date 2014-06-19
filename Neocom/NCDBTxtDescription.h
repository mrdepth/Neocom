//
//  NCDBTxtDescription.h
//  Neocom
//
//  Created by Артем Шиманский on 19.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBCertCertificate, NCDBInvType;

@interface NCDBTxtDescription : NSManagedObject

@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NCDBCertCertificate *certificate;
@property (nonatomic, retain) NCDBInvType *type;

@end
