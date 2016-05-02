//
//  NCDBEveIconImage+CoreDataProperties.h
//  NCDatabase
//
//  Created by Артем Шиманский on 14.03.16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBEveIconImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBEveIconImage (CoreDataProperties)

@property (nullable, nonatomic, retain) id image;
@property (nullable, nonatomic, retain) NCDBEveIcon *icon;

@end

NS_ASSUME_NONNULL_END
