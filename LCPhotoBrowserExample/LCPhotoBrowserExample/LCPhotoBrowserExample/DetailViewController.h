//
//  DetailViewController.h
//  LCPhotoBrowserExample
//
//  Created by Guolicheng on 2016/12/14.
//  Copyright © 2016年 titman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) NSDate *detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

