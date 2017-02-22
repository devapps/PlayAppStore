//
//  QMUISearchController.m
//  Test
//
//  Created by MoLice on 16/5/25.
//  Copyright © 2016年 MoLice. All rights reserved.
//

#import "QMUISearchController.h"
#import "QMUICommonDefines.h"
#import "QMUIConfiguration.h"
#import "QMUISearchBar.h"
#import "QMUICommonTableViewController.h"
#import "QMUIEmptyView.h"
#import "UISearchBar+QMUI.h"
#import "UITableView+QMUI.h"

BeginIgnoreDeprecatedWarning

@class QMUISearchResultsTableViewController;

@protocol QMUISearchResultsTableViewControllerDelegate <NSObject>

- (void)didLoadTableViewInSearchResultsTableViewController:(QMUISearchResultsTableViewController *)viewController;
@end

@interface QMUISearchResultsTableViewController : QMUICommonTableViewController

@property(nonatomic,weak) id<QMUISearchResultsTableViewControllerDelegate> delegate;
@end

@implementation QMUISearchResultsTableViewController

- (void)initTableView {
    [super initTableView];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    if ([self.delegate respondsToSelector:@selector(didLoadTableViewInSearchResultsTableViewController:)]) {
        [self.delegate didLoadTableViewInSearchResultsTableViewController:self];
    }
}

@end

@interface QMUISearchController ()<UISearchResultsUpdating,UISearchControllerDelegate,QMUISearchResultsTableViewControllerDelegate,UISearchDisplayDelegate>

// iOS8及以后使用这个
@property(nonatomic,strong) UISearchController *searchController;

// iOS7及以前使用这个
@property(nonatomic,strong) UISearchDisplayController *searchDisplayController;
@end

@implementation QMUISearchController

- (instancetype)initWithContentsViewController:(UIViewController *)viewController {
    if (self = [self init]) {
        if (NSStringFromClass([UISearchController class])) {
            // 将definesPresentationContext置为YES有两个作用：
            // 1、保证从搜索结果界面进入子界面后，顶部的searchBar不会依然停留在navigationBar上
            // 2、使搜索结果界面的tableView的contentInset.top正确适配searchBar
            viewController.definesPresentationContext = YES;
            
            QMUISearchResultsTableViewController *viewController = [[QMUISearchResultsTableViewController alloc] init];
            viewController.delegate = self;
            self.searchController = [[UISearchController alloc] initWithSearchResultsController:viewController];
            self.searchController.searchResultsUpdater = self;
            self.searchController.delegate = self;
            _searchBar = self.searchController.searchBar;
            if (CGRectIsEmpty(self.searchBar.frame)) {
                // iOS8 下 searchBar.frame 默认是 CGRectZero，不 sizeToFit 就看不到了
                [self.searchBar sizeToFit];
            }
            [self.searchBar qmui_styledAsQMUISearchBar];
        } else {
            _searchBar = [[QMUISearchBar alloc] init];
            self.searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:viewController];
            self.searchDisplayController.delegate = self;
        }
    }
    return self;
}

- (void)dealloc {
    self.searchDisplayController.delegate = nil;
}

- (void)setSearchResultsDelegate:(id<QMUISearchControllerDelegate>)searchResultsDelegate {
    _searchResultsDelegate = searchResultsDelegate;
    
    if (self.searchController) {
        self.tableView.dataSource = _searchResultsDelegate;
        self.tableView.delegate = _searchResultsDelegate;
    } else {
        self.searchDisplayController.searchResultsDataSource = _searchResultsDelegate;
        self.searchDisplayController.searchResultsDelegate = _searchResultsDelegate;
    }
}

- (BOOL)active {
    if (self.searchController) {
        return self.searchController.active;
    } else {
        return self.searchDisplayController.active;
    }
}

- (UITableView *)tableView {
    if (self.searchController) {
        return ((QMUICommonTableViewController *)self.searchController.searchResultsController).tableView;
    } else {
        return self.searchDisplayController.searchResultsTableView;
    }
}

- (void)removeDefaultEmptyLabelInSearchDisplayController {
    // 移除UISearchDisplayController自带的“无结果”的label
    for (UIView *subview in self.searchDisplayController.searchResultsTableView.subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            [subview removeFromSuperview];
            subview.hidden = YES;
            break;
        }
    }
}

#pragma mark - QMUIEmptyView

- (void)showEmptyView {
    // 搜索框文字为空时，界面会显示遮罩，此时不需要显示emptyView了
    // 为什么加这个是因为当搜索框被点击时（进入搜索状态）会触发searchController:updateResultsForSearchString:，里面如果直接根据搜索结果为空来showEmptyView的话，就会导致在遮罩层上有emptyView出现，要么在那边showEmptyView之前判断一下searchBar.text.length，要么在showEmptyView里判断，为了方便，这里选择后者。
    if (self.searchBar.text.length <= 0) {
        return;
    }
    
    [super showEmptyView];
    
    // 格式化样式，以适应当前项目的需求
    self.emptyView.backgroundColor = TableViewBackgroundColor;
    if ([self.searchResultsDelegate respondsToSelector:@selector(searchController:willShowEmptyView:)]) {
        [self.searchResultsDelegate searchController:self willShowEmptyView:self.emptyView];
    }
    
    if (self.searchController) {
        UIView *superview = self.searchController.searchResultsController.view;
        [superview addSubview:self.emptyView];
    } else if (self.searchDisplayController) {
        // 加到searchResultsTableView里的好处是当搜索框的文字被清空时，搜索界面会出现黑色半透明遮罩，此时searchResultsTableView会被隐藏掉，刚好上面的emptyView也就看不到了
        UIView *superview = self.searchDisplayController.searchResultsTableView;
        [superview addSubview:self.emptyView];
    } else {
        NSAssert(NO, @"QMUISearchController无法为emptyView找到合适的superview");
    }
    
    [self layoutEmptyView];
}

- (BOOL)layoutEmptyView {
    if ([self.emptyView.superview isKindOfClass:[UITableView class]]) {
        // iOS7 UISearchDisplayController里，会把emptyView加到searchResultsTableView上，参照showEmptyView里的代码
        UITableView *tableView = (UITableView *)self.emptyView.superview;
        CGSize newEmptyViewSize = CGSizeMake(CGRectGetWidth(tableView.bounds) - UIEdgeInsetsGetHorizontalValue(tableView.contentInset), CGRectGetHeight(tableView.frame) - UIEdgeInsetsGetVerticalValue(tableView.contentInset));
        CGSize oldEmptyViewSize = self.emptyView.frame.size;
        if (!CGSizeEqualToSize(newEmptyViewSize, oldEmptyViewSize)) {
            self.emptyView.frame = CGRectMake(CGRectGetMinX(self.emptyView.frame), CGRectGetMinY(self.emptyView.frame), newEmptyViewSize.width, newEmptyViewSize.height);
        }
        return YES;
    } else {
        return [super layoutEmptyView];
    }
}

#pragma mark - <QMUISearchResultsTableViewControllerDelegate>

- (void)didLoadTableViewInSearchResultsTableViewController:(QMUISearchResultsTableViewController *)viewController {
    if ([self.searchResultsDelegate respondsToSelector:@selector(searchController:didLoadSearchResultsTableView:)]) {
        [self.searchResultsDelegate searchController:self didLoadSearchResultsTableView:viewController.tableView];
    }
}

#pragma mark - <UISearchResultsUpdating>

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    if ([self.searchResultsDelegate respondsToSelector:@selector(searchController:updateResultsForSearchString:)]) {
        [self.searchResultsDelegate searchController:self updateResultsForSearchString:searchController.searchBar.text];
    }
}

#pragma mark - <UISearchControllerDelegate>

- (void)willPresentSearchController:(UISearchController *)searchController {
    if ([self.searchResultsDelegate respondsToSelector:@selector(willPresentSearchController:)]) {
        [self.searchResultsDelegate willPresentSearchController:self];
    }
}

- (void)didPresentSearchController:(UISearchController *)searchController {
    if ([self.searchResultsDelegate respondsToSelector:@selector(didPresentSearchController:)]) {
        [self.searchResultsDelegate didPresentSearchController:self];
    }
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    if ([self.searchResultsDelegate respondsToSelector:@selector(willDismissSearchController:)]) {
        [self.searchResultsDelegate willDismissSearchController:self];
    }
}

- (void)didDismissSearchController:(UISearchController *)searchController {
    // 退出搜索必定先隐藏emptyView
    [self hideEmptyView];
    
    if ([self.searchResultsDelegate respondsToSelector:@selector(didDismissSearchController:)]) {
        [self.searchResultsDelegate didDismissSearchController:self];
    }
}

#pragma mark - <UISearchDisplayDelegate>

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    if ([self.searchResultsDelegate respondsToSelector:@selector(willPresentSearchController:)]) {
        [self.searchResultsDelegate willPresentSearchController:self];
    }
    
    // UISearchController在点击搜索框进入搜索状态时，会调用updateSearchResults，为了让iOS7下也保持一致的调用时机，这里补了这句
    [self searchDisplayController:controller shouldReloadTableForSearchString:@""];
}

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller {
    if ([self.searchResultsDelegate respondsToSelector:@selector(didPresentSearchController:)]) {
        [self.searchResultsDelegate didPresentSearchController:self];
    }
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
    if ([self.searchResultsDelegate respondsToSelector:@selector(willDismissSearchController:)]) {
        [self.searchResultsDelegate willDismissSearchController:self];
    }
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    // 退出搜索必定先隐藏emptyView
    [self hideEmptyView];
    
    if ([self.searchResultsDelegate respondsToSelector:@selector(didDismissSearchController:)]) {
        [self.searchResultsDelegate didDismissSearchController:self];
    }
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {
    [tableView qmui_styledAsQMUITableView];
    tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    if ([self.searchResultsDelegate respondsToSelector:@selector(searchController:didLoadSearchResultsTableView:)]) {
        [self.searchResultsDelegate searchController:self didLoadSearchResultsTableView:tableView];
    }
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView {
    // 移除搜索框底部的阴影
    for (UIView *subview in tableView.subviews) {
        if ([NSStringFromClass(subview.class) isEqualToString:@"_UISearchBarShadowView"]) {
            subview.hidden = YES;
            // 用hidden而不要用removeFromSuperview，后者会导致subview被释放，从而可能产生野指针
//            [subview removeFromSuperview];
            break;
        }
    }
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(nullable NSString *)searchString {
    [self removeDefaultEmptyLabelInSearchDisplayController];
    
    if ([self.searchResultsDelegate respondsToSelector:@selector(searchController:updateResultsForSearchString:)]) {
        [self.searchResultsDelegate searchController:self updateResultsForSearchString:self.searchBar.text];
    }
    return YES;
}

@end

EndIgnoreDeprecatedWarning
