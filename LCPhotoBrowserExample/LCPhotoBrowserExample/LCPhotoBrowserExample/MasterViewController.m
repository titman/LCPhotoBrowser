//
//  MasterViewController.m
//  LCPhotoBrowserExample
//
//  Created by Guolicheng on 2016/12/14.
//  Copyright © 2016年 titman. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "LCPhotoBrowser.h"

@interface MasterViewController ()

@property NSMutableArray *objects;
@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    self.objects = [NSMutableArray array];
    
    [self.objects addObject:@[@"1.gif", @"http://image.tianjimedia.com/uploadImages/upload/20150818/2z2qe0dqi5xgif.gif"]];
    [self.objects addObject:@[@"2.gif", @"http://image.tianjimedia.com/uploadImages/upload/20150818/m2yoqll1by4gif.gif"]];
    [self.objects addObject:@[@"3.gif", @"http://image.tianjimedia.com/uploadImages/upload/20150818/3qmnrrtlvqbgif.gif"]];
    [self.objects addObject:@[@"4.gif", @"http://image.tianjimedia.com/uploadImages/upload/20150818/azgulan2yumgif.gif"]];
    [self.objects addObject:@[@"5.gif", @"http://image.tianjimedia.com/uploadImages/upload/20150818/ajiowjxkc0wgif.gif"]];

    
}


- (void)viewWillAppear:(BOOL)animated {
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)insertNewObject:(id)sender {
}

-(void) imageTapAction:(UITapGestureRecognizer *)tap
{
    NSMutableArray * photoItems = [NSMutableArray array];
    
    [self.objects enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        LCPhotoItem * item = [[LCPhotoItem alloc] init];
        item.placeholder   = [UIImage imageNamed:obj[0]];
        item.urlString     = obj[1];
        
        if (idx == tap.view.tag) item.referenceView = tap.view;

        [photoItems addObject:item];
    }];
    
    LCPhotoBrowser * browser     = [[LCPhotoBrowser alloc] init];
    browser.items                = photoItems;
    browser.currentIndex         = tap.view.tag;
    browser.loadingStyle         = LCPhotoBrowserLoadingStyleProgress;
    browser.backgroundStyle      = LCPhotoBrowserBackgroundStyleBlur;
    browser.backgroundBlurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
    [browser show];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDate *object = self.objects[indexPath.row];
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        [controller setDetailItem:object];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.objects.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    NSArray * object = self.objects[indexPath.row];
    cell.textLabel.text = object[1];
    cell.imageView.image = [UIImage imageNamed:object[0]];
    cell.imageView.tag = indexPath.row;
    cell.imageView.userInteractionEnabled = YES;
    
    if (cell.imageView.gestureRecognizers.count) {
        [cell.imageView removeGestureRecognizer:cell.imageView.gestureRecognizers.firstObject];
    }
    
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapAction:)];
    [cell.imageView addGestureRecognizer:tap];
    
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}


@end
