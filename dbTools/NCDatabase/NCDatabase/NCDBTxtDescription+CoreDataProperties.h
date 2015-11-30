//
//  NCDBTxtDescription+CoreDataProperties.h
//  NCDatabase
//
//  Created by Artem Shimanski on 29.11.15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBTxtDescription.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBTxtDescription (CoreDataProperties)

@property (nullable, nonatomic, retain) id text;
@property (nullable, nonatomic, retain) NCDBCertCertificate *certificate;
@property (nullable, nonatomic, retain) NCDBInvType *type;

@end

NS_ASSUME_NONNULL_END
