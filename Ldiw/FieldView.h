//
//  FieldView.h
//  Ldiw
//
//  Created by Lauri Eskor on 2/27/13.
//  Copyright (c) 2013 Mobi Solutions. All rights reserved.
//

#import "WPField.h"
@protocol FieldDelegate

- (void)checkedValue:(NSString *)value forField:(NSString *)fieldName;
- (void)addDataPressedForField:(NSString *)fieldName;

@end


@interface FieldView : UIView
@property (nonatomic, assign) id<FieldDelegate> delegate;
@property (nonatomic, strong) WPField *wastePointField;

- (id)initWithWPField:(WPField *)field;

@end
