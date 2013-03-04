//
//  FieldView.h
//  Ldiw
//
//  Created by Lauri Eskor on 2/27/13.
//  Copyright (c) 2013 Mobi Solutions. All rights reserved.
//

#import "WPField.h"
#import "FieldDelegate.h"

@interface FieldView : UIView
@property (nonatomic, assign) id<FieldDelegate> delegate;
@property (nonatomic, strong) WPField *wastePointField;
@property (nonatomic, strong) NSMutableArray *tickButtonArray;
@property (nonatomic, strong) UILabel *valueLabel;

- (id)initWithWPField:(WPField *)field;
- (void)setValue:(NSString *)value;
@end
