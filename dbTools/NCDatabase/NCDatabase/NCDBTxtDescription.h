//
//  NCDBTxtDescription.h
//  NCDatabase
//
//  Created by Shimanski Artem on 15.06.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBCertCertificate, NCDBInvType;

@interface NCDBTxtDescription : NSManagedObject

@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NCDBCertCertificate *certificate;
@property (nonatomic, retain) NCDBInvType *type;

@end
