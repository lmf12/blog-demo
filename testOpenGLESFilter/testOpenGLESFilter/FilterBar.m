//
//  FilterBar.m
//  testOpenGLESFilter
//
//  Created by Lyman Li on 2019/3/30.
//  Copyright © 2019年 Lyman Li. All rights reserved.
//

#import "FilterBarCell.h"

#import "FilterBar.h"

static NSString * const kFilterBarCellIdentifier = @"FilterBarCell";

@interface FilterBar () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *collectionViewLayout;

@property (nonatomic, assign) NSInteger currentIndex;

@end

@implementation FilterBar

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

#pragma mark - Private

- (void)commonInit {
    
    [self createCollectionViewLayout];
    
    _collectionView = [[UICollectionView alloc] initWithFrame:[self bounds] collectionViewLayout:_collectionViewLayout];
    [self addSubview:_collectionView];
    
    _collectionView.backgroundColor = [UIColor whiteColor];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.showsVerticalScrollIndicator = NO;
    _collectionView.showsHorizontalScrollIndicator = NO;
    [_collectionView registerClass:[FilterBarCell class] forCellWithReuseIdentifier:kFilterBarCellIdentifier];
}

- (void)createCollectionViewLayout {
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];

    flowLayout.minimumLineSpacing = 0;
    flowLayout.minimumInteritemSpacing = 0;

    CGFloat itemW = 100;
    CGFloat itemH = CGRectGetHeight(self.frame);
    flowLayout.itemSize = CGSizeMake(itemW, itemH);
    
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    _collectionViewLayout = flowLayout;
}

- (void)selectIndex:(NSIndexPath *)indexPath {
    
    _currentIndex = indexPath.row;
    [_collectionView reloadData];
    
    [_collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(filterBar:didScrollToIndex:)]) {
        [self.delegate filterBar:self didScrollToIndex:indexPath.row];
    }
}

#pragma mark - setter

- (void)setItemList:(NSArray<NSString *> *)itemList {
    
    _itemList = itemList;
    [_collectionView reloadData];
}

#pragma mark - UICollectionViewDelegate & UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return [_itemList count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FilterBarCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kFilterBarCellIdentifier forIndexPath:indexPath];
    cell.title = self.itemList[indexPath.row];
    cell.isSelect = indexPath.row == _currentIndex;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    [self selectIndex:indexPath];
}

@end
