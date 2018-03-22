//
//  OGTableViewCell.m
//  testOpenGL
//
//  Created by Lyman Li on 2018/3/22.
//  Copyright © 2018年 Lyman Li. All rights reserved.
//

#import "OGTableViewCell.h"

@interface OGTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *lblTitle;

@end

@implementation OGTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configTitle:(NSString *)title {
    
    self.lblTitle.text = title;
}

@end
