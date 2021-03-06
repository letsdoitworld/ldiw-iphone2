//
//  Database+WPField.h
//  Ldiw
//
//  Created by Lauri Eskor on 2/20/13.
//  Copyright (c) 2013 Mobi Solutions. All rights reserved.
//

#import "Database.h"
#import "WPField.h"
#import "CustomValue.h"

@interface Database (WPField)

- (void)deleteAllWPFields;
- (NSArray *)listAllWPFields;
- (NSArray *)typicalValuesForField:(WPField *)field;
- (NSArray *)allowedValuesForField:(WPField *)field;

- (WPField *)findWPFieldWithFieldName:(NSString *)fieldName orLabel:(NSString *)label;
- (WPField *)createWPFieldWithFieldName:(NSString *)fieldName andEditInstructions:(NSString *)editInstructions andLabel:(NSString *)label andMaxValue:(NSNumber *)max andMinValue:(NSNumber *)min andSuffix:(NSString *)suffix andType:(NSString *)type andTypicalValues:(NSArray *)typicalValues andAllowedValues:(NSArray *)allowedValues andIndex:(NSNumber *)index;
- (AllowedValue *)createAllowedValueWithKey:(NSString *)key andValue:(NSString *)value forWPField:(WPField *)wpField;
- (TypicalValue *)createTypicalValueWithKey:(NSString *)key andValue:(NSString *)value forWPField:(WPField *)wpField;
- (NSString *)nameOfTheCustomValue:(CustomValue *)customValue;

- (NSArray *)listAllNonCompositionFields;
- (NSArray *)listAllCompositionFields;
@end
