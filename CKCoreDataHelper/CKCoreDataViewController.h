//
//  CKCoreDataViewController.h
//  FoodReminder
//
//  Created by Enix Yu on 27/2/2017.
//  Copyright © 2017 RobotBros. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface CKCoreDataViewController : UIViewController
    <NSFetchedResultsControllerDelegate>

@property (nonatomic, weak) UITableView *tableView;

@property (nonatomic, strong) NSFetchedResultsController *frc;

- (BOOL)performFetchWithError:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
