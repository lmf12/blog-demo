//
//  ViewController.m
//  testOpenGL
//
//  Created by Lyman Li on 2018/3/22.
//  Copyright © 2018年 Lyman Li. All rights reserved.
//

#import "OGTableViewCell.h"

#import "ViewController.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initDataSource];
    [self initTableView];
}

// 初始化tableview
- (void)initTableView {
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:[self.view bounds]];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:tableView];
}

// 初始化数据
- (void)initDataSource {
    
    _dataSource = [[NSMutableArray alloc] init];
    
    [_dataSource addObject:@"example 0"];
    [_dataSource addObject:@"example 1"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [_dataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OGTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OGTableViewCell"];
    if (!cell) {
        cell = (OGTableViewCell *)[[[NSBundle mainBundle] loadNibNamed:@"OGTableViewCell" owner:self options:nil] lastObject];
    }
    [cell configTitle:_dataSource[indexPath.row]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Class class = NSClassFromString([NSString stringWithFormat:@"OGViewController%ld", (long)indexPath.row]);
    
    [self.navigationController pushViewController:[[class alloc] init] animated:YES];
    
}

@end
