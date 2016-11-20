//
//  NSExpressionDescription+NC.h
//  Neocom
//
//  Created by Artem Shimanski on 20.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSExpressionDescription (NC)

+ (instancetype) expressionDescriptionWithName:(NSString*) name resultType:(NSAttributeType) resultType expression:(NSExpression*) expression;

@end
