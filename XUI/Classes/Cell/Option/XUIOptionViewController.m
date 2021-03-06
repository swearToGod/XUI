//
//  XUIOptionViewController.m
//  XXTExplorer
//
//  Created by Zheng on 17/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIOptionViewController.h"

#import "XUIPrivate.h"
#import "XUITheme.h"
#import "XUIOptionCell.h"
#import "XUIOptionModel.h"
#import "XUIBaseOptionCell.h"

@interface XUIOptionViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) NSInteger selectedIndex;

@end

@implementation XUIOptionViewController {
    
}

@synthesize theme = _theme;

- (instancetype)initWithCell:(XUIOptionCell *)cell {
    if (self = [super init]) {
        _cell = cell;
        id rawValue = cell.xui_value;
        if (rawValue) {
            NSUInteger rawIndex = [self.cell.xui_options indexOfObjectPassingTest:^BOOL(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                id value = obj[XUIOptionValueKey];
                if ([rawValue isEqual:value]) {
                    return YES;
                }
                return NO;
            }];
            if ((rawIndex) != NSNotFound) {
                _selectedIndex = rawIndex;
            }
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.tableView];
}

#pragma mark - UIView Getters

- (UITableView *)tableView {
    if (!_tableView) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.editing = NO;
        XUI_START_IGNORE_PARTIAL
        if (@available(iOS 9.0, *)) {
            tableView.cellLayoutMarginsFollowReadableWidth = NO;
        }
        XUI_END_IGNORE_PARTIAL
        _tableView = tableView;
    }
    return _tableView;
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.cell.xui_options.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.f;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (0 == section) {
        return [self.adapter localizedStringForKey:self.cell.xui_footerText value:self.cell.xui_footerText];
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0)
    {
        XUIBaseOptionCell *cell =
        [tableView dequeueReusableCellWithIdentifier:XUIBaseOptionCellReuseIdentifier];
        if (nil == cell)
        {
            cell = [[XUIBaseOptionCell alloc] initWithStyle:UITableViewCellStyleDefault
                                            reuseIdentifier:XUIBaseOptionCellReuseIdentifier];
        }
        cell.adapter = self.adapter;
        NSDictionary *optionDictionary = self.cell.xui_options[(NSUInteger) indexPath.row];
        cell.xui_icon = optionDictionary[XUIOptionIconKey];
        cell.xui_label = optionDictionary[XUIOptionTitleKey];
        cell.tintColor = self.theme.tintColor;
        if (self.selectedIndex == indexPath.row) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        return cell;
    }
    return [UITableViewCell new];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        self.selectedIndex = indexPath.row;
        for (UITableViewCell *cell in tableView.visibleCells) {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        UITableViewCell *selectCell = [tableView cellForRowAtIndexPath:indexPath];
        selectCell.accessoryType = UITableViewCellAccessoryCheckmark;
        id selectedValue = self.cell.xui_options[self.selectedIndex][XUIOptionValueKey];
        if (selectedValue) {
            self.cell.xui_value = selectedValue;
        }
        if (_delegate && [_delegate respondsToSelector:@selector(optionViewController:didSelectOption:)]) {
            [_delegate optionViewController:self didSelectOption:self.selectedIndex];
        }
    }
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XUIOptionViewController dealloc]");
#endif
}

@end
