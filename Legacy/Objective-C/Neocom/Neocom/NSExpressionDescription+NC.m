//
//  NSExpressionDescription+NC.m
//  Neocom
//
//  Created by Artem Shimanski on 20.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NSExpressionDescription+NC.h"

@implementation NSExpressionDescription (NC)

+ (instancetype) expressionDescriptionWithName:(NSString*) name resultType:(NSAttributeType) resultType expression:(NSExpression*) expression {
	NSExpressionDescription* expressionDescription = [NSExpressionDescription new];
	expressionDescription.name = name;
	expressionDescription.expressionResultType = resultType;
	expressionDescription.expression = expression;
	return expressionDescription;
}

@end
