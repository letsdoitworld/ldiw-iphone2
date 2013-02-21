//
//  ActivityCustomCell.m
//  Ldiw
//
//  Created by sander on 2/19/13.
//  Copyright (c) 2013 Mobi Solutions. All rights reserved.
//

#import "ActivityCustomCell.h"
#import <QuartzCore/QuartzCore.h>
#import "DesignHelper.h"

#define kbgCornerRadius 8
#define kDarkBackgroundColor [UIColor colorWithRed:0.153 green:0.141 blue:0.125 alpha:1] /*#272420*/
@interface ActivityCustomCell ()


@end

@implementation ActivityCustomCell
@synthesize cellNameTitleLabel, cellSubtitleLabel, cellTitleLabel;



-(id)initWithCoder:(NSCoder *)aDecoder {
  self=[super initWithCoder:aDecoder];
  if (self) {
    [self makeDesign];
  }
  return self;
}

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self=[super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    [self makeDesign];
  }
  

  return self;
}

- (void)makeDesign
{
  UIView *bgView=[[UIView alloc] initWithFrame:CGRectMake(10, 10, 300, 130)];
  bgView.backgroundColor=[UIColor blackColor];
  [bgView.layer setCornerRadius:kbgCornerRadius];
  [bgView setClipsToBounds:YES];
  [self addSubview:bgView];
  UIImage *pointMaker=[UIImage imageNamed:@"pointmarker_feed"];
  UIImage *userIcon= [UIImage imageNamed:@"pointmarker_feed"];
  CGRect firstrect=CGRectMake(5, 5, pointMaker.size.width, pointMaker.size.height);
  CGRect secondrect=CGRectOffset(firstrect, pointMaker.size.width+ 2, 0);
  UIImageView *firstImageView=[[UIImageView alloc] initWithFrame:firstrect];
  UIImageView *secondImageView=[[UIImageView alloc] initWithFrame:secondrect];
  firstImageView.image=userIcon;
  secondImageView.image=pointMaker;
  
  CGRect subtitlelabelrect=CGRectOffset(firstrect, 0, pointMaker.size.height +6);
  cellSubtitleLabel=[[UILabel alloc] initWithFrame:subtitlelabelrect];
  [DesignHelper setActivityViewSubtitle:cellSubtitleLabel];

  CGRect namelabelrect=CGRectOffset(secondrect, secondrect.size.width + 4, 0);
  cellNameTitleLabel=[[UILabel alloc] initWithFrame:namelabelrect];
  cellNameTitleLabel.text=@"";
  [DesignHelper setActivityViewNametitle:cellNameTitleLabel];

  CGRect titlelabelrect=CGRectOffset(namelabelrect, secondrect.size.width + 4, 0);
  self.cellTitleLabel.frame=titlelabelrect;
  [DesignHelper setActivityViewNametitle:cellNameTitleLabel];
  
  
  [bgView addSubview:firstImageView];
  [bgView addSubview:secondImageView];
  [bgView addSubview:cellSubtitleLabel];
  [bgView addSubview:cellNameTitleLabel];
  

  //self.cellTitleLabel=[[UILabel alloc] initWithFrame:rect];
  //[self addSubview:cellTitleLabel];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
