//
//  XUICheckboxCell.m
//  XXTExplorer
//
//  Created by Zheng on 09/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUICheckboxCell.h"
#import "XUITextTagCollectionView.h"

#import "XUIPrivate.h"
#import "XUILogger.h"
#import "XUIViewShaker.h"
#import "XUIOptionModel.h"

@interface XUICheckboxCell () <XUITextTagCollectionViewDelegate>

@property (nonatomic, strong) XUIViewShaker *viewShaker;
@property (weak, nonatomic) IBOutlet XUITextTagCollectionView *tagView;
@property (assign, nonatomic) BOOL shouldUpdateValue;

@end

@implementation XUICheckboxCell

@synthesize xui_value = _xui_value;

+ (BOOL)xibBasedLayout {
    return YES;
}

+ (BOOL)layoutNeedsTextLabel {
    return NO;
}

+ (BOOL)layoutNeedsImageView {
    return NO;
}

+ (BOOL)layoutRequiresDynamicRowHeight {
    return YES;
}

+ (BOOL)layoutUsesAutoResizing {
    return YES;
}

+ (NSDictionary <NSString *, Class> *)entryValueTypes {
    return
    @{
      @"options": [NSArray class],
      @"maxCount": [NSNumber class],
      @"minCount": [NSNumber class],
      @"value": [NSArray class]
      };
}

+ (NSDictionary <NSString *, Class> *)optionValueTypes {
    return
    @{
      XUIOptionTitleKey: [NSString class],
      XUIOptionShortTitleKey: [NSString class],
      XUIOptionIconKey: [NSString class],
      };
}

+ (BOOL)testEntry:(NSDictionary *)cellEntry withError:(NSError **)error {
    BOOL superResult = [super testEntry:cellEntry withError:error];
    return superResult;
}

- (void)setupCell {
    [super setupCell];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.tagView.scrollView.scrollEnabled = NO;
    self.tagView.contentInset = UIEdgeInsetsZero;
    self.tagView.scrollDirection = XUITagCollectionScrollDirectionVertical;
    self.tagView.defaultConfig.tagCornerRadius = 8.f;
    self.tagView.defaultConfig.tagSelectedCornerRadius = 8.f;
    self.tagView.defaultConfig.tagShadowColor = UIColor.clearColor;
    
    // Alignment
    self.tagView.alignment = XUITagCollectionAlignmentLeft;
    
    // Use manual calculate height
    self.tagView.delegate = self;
    self.tagView.manualCalculateHeight = YES;
    
    self.viewShaker = [[XUIViewShaker alloc] initWithView:self.tagView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.tagView.preferredMaxLayoutWidth = CGRectGetWidth(self.frame) - 32.f;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(CGRectGetWidth(self.bounds), self.tagView.intrinsicContentSize.height + 24.f + 1.f);
}

- (void)setXui_options:(NSArray<NSDictionary *> *)xui_options {
    for (NSDictionary *pair in xui_options) {
        for (NSString *pairKey in pair.allKeys) {
            Class pairClass = [[self class] optionValueTypes][pairKey];
            if (pairClass) {
                if (![pair[pairKey] isKindOfClass:pairClass]) {
                    return; // invalid option, ignore
                }
            }
        }
    }
    _xui_options = xui_options;
    NSMutableArray <NSString *> *xui_validTitles = [[NSMutableArray alloc] init];
    [xui_options enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *title = obj[XUIOptionTitleKey];
        if (title) {
            NSString *localizedTitle = [self.adapter localizedStringForKey:title value:title];
            [xui_validTitles addObject:localizedTitle];
        }
    }];
    [self.tagView removeAllTags];
    [self.tagView addTags:xui_validTitles];
    [self.tagView reload];
    
    [self updateValueIfNeeded];
}

- (void)setXui_value:(id)xui_value {
    _xui_value = xui_value;
    [self setNeedsUpdateValue];
    [self updateValueIfNeeded];
}

- (void)setXui_maxCount:(NSNumber *)xui_maxCount {
    _xui_maxCount = xui_maxCount;
    self.tagView.selectionLimit = [xui_maxCount unsignedIntegerValue];
}

- (void)setNeedsUpdateValue {
    self.shouldUpdateValue = YES;
}

- (void)updateValueIfNeeded {
    if (self.shouldUpdateValue && self.tagView.allTags.count > 0) {
        self.shouldUpdateValue = NO;
        NSArray *selectedValues = self.xui_value;
        NSUInteger minCount = [self.xui_minCount unsignedIntegerValue];
        NSUInteger maxCount = [self.xui_maxCount unsignedIntegerValue];
        if (selectedValues.count > maxCount || selectedValues.count < minCount) {
            return; // Invalid value, ignore
        }
        for (id selectedValue in selectedValues) {
            NSUInteger selectedIndex = [self.xui_options indexOfObjectPassingTest:^BOOL(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([selectedValue isEqual:obj[XUIOptionValueKey]]) {
                    return YES;
                }
                return NO;
            }];
            if (selectedIndex != NSNotFound) {
                [self.tagView setTagAtIndex:selectedIndex selected:YES];
            }
        }
    }
}

- (id)textTagCollectionView:(XUITextTagCollectionView *)textTagCollectionView valueForTagAtIndex:(NSUInteger)selectedIndexValue {
    NSMutableArray *validValues = [[NSMutableArray alloc] init];
    for (NSDictionary *obj in self.xui_options) {
        if (obj[XUIOptionValueKey]) {
            [validValues addObject:obj[XUIOptionValueKey]];
        } else {
            return nil;
        }
    }
    if (selectedIndexValue >= validValues.count) return nil;
    id selectedValue = validValues[selectedIndexValue];
    return selectedValue;
}

- (BOOL)textTagCollectionView:(XUITextTagCollectionView *)textTagCollectionView canTapTag:(NSString *)tagText atIndex:(NSUInteger)index currentSelected:(BOOL)currentSelected {
    NSArray *selectedValues = self.xui_value;
    NSUInteger maxCount = [self.xui_maxCount unsignedIntegerValue];
    NSUInteger minCount = [self.xui_minCount unsignedIntegerValue];
    BOOL canTap = YES;
    if (selectedValues.count >= maxCount && currentSelected == NO) {
        canTap = NO;
    }
    else if (selectedValues.count <= minCount && currentSelected == YES) {
        canTap = NO;
    }
    if ([self textTagCollectionView:textTagCollectionView valueForTagAtIndex:index] == nil) {
        canTap = NO;
    }
    if (!canTap) {
        [self.viewShaker shake];
    }
    return canTap;
}

- (void)textTagCollectionView:(XUITextTagCollectionView *)textTagCollectionView
                    didTapTag:(NSString *)tagText
                      atIndex:(NSUInteger)index
                     selected:(BOOL)selected
{
    NSMutableArray *validValues = [[NSMutableArray alloc] init];
    [self.xui_options enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj[XUIOptionValueKey]) {
            [validValues addObject:obj[XUIOptionValueKey]];
        } else {
            return;
        }
    }];
    NSMutableArray *selectedValues = [[NSMutableArray alloc] init];
    NSArray <NSNumber *> *selectedIndexes = textTagCollectionView.allSelectedIndexes;
    for (NSNumber *selectedIndex in selectedIndexes) {
        NSUInteger selectedIndexValue = [selectedIndex unsignedIntegerValue];
        if (selectedIndexValue >= validValues.count) return;
        id selectedValue = validValues[selectedIndexValue];
        if (selectedValue) [selectedValues addObject:selectedValue];
    }
    self.xui_value = [selectedValues copy];
    [self.adapter saveDefaultsFromCell:self];
}

- (void)setXui_alignment:(NSString *)xui_alignment {
    _xui_alignment = xui_alignment;
    if ([xui_alignment isEqualToString:@"Left"]) {
        self.tagView.alignment = XUITagCollectionAlignmentLeft;
    }
    else if ([xui_alignment isEqualToString:@"Center"]) {
        self.tagView.alignment = XUITagCollectionAlignmentCenter;
    }
    else if ([xui_alignment isEqualToString:@"Right"]) {
        self.tagView.alignment = XUITagCollectionAlignmentRight;
    }
    else if ([xui_alignment isEqualToString:@"Natural"]) {
        self.tagView.alignment = XUITagCollectionAlignmentFillByExpandingSpace;
    }
    else if ([xui_alignment isEqualToString:@"Justified"]) {
        self.tagView.alignment = XUITagCollectionAlignmentFillByExpandingWidth;
    }
    else {
        self.tagView.alignment = XUITagCollectionAlignmentLeft;
    }
}

- (void)setXui_readonly:(NSNumber *)xui_readonly {
    [super setXui_readonly:xui_readonly];
    BOOL readonly = [xui_readonly boolValue];
    self.tagView.enableTagSelection = !readonly;
}

- (void)setTheme:(XUITheme *)theme {
    [super setTheme:theme];
    self.tagView.defaultConfig.tagBackgroundColor = theme.successColor;
    self.tagView.defaultConfig.tagSelectedBackgroundColor = theme.highlightColor;
    [self.tagView reload];
}

@end
