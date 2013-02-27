//
//  WastePointViews.h
//  Ldiw
//
//  Created by Timo Kallaste on 2/25/13.
//  Copyright (c) 2013 Mobi Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WastePoint.h"

@interface WastePointViews : UIView

@property (nonatomic, strong) NSMutableArray *checkArray;

- (id)initWithWastePoint:(WastePoint *)wp;
- (NSArray *)wpCheckFields;

@end
