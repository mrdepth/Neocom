//
//  NCDBEveIconImage+CoreDataProperties.h
//  Neocom
//
//  Created by Artem Shimanski on 29.11.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
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
