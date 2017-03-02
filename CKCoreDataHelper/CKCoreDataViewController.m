//
//  CKCoreDataViewController.m
//  FoodReminder
//
//  Created by Enix Yu on 27/2/2017.
//  Copyright © 2017 RobotBros. All rights reserved.
//

#import "CKCoreDataViewController.h"

//-----------------------------------------------------------------
#pragma MARK - Static Var.
//-----------------------------------------------------------------

static NSString *const kCKErrorDomain = @"CKCoreDataViewControllerErrorDomain";
static NSInteger const kCKErrorNullFetchController = -1;

@interface CKCoreDataViewController ()

@end

//-----------------------------------------------------------------
#pragma MARK - Class Imp.
//-----------------------------------------------------------------

@implementation CKCoreDataViewController

@dynamic tableView;

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)performFetchWithError:(NSError **)error {
    if (self.frc) {
        if ( ![self.frc performFetch:error] ) {
            return NO;
        }
        
        [self.tableView reloadData];
        return YES;
    } else {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey:
                                   NSLocalizedString(@"Fetch result controller is null", @"")};
        *error = [NSError errorWithDomain:kCKErrorDomain
                                     code:kCKErrorNullFetchController
                                 userInfo:userInfo];
        return NO;
    }
}

//-----------------------------------------------------------------
#pragma MARK - NSFetchedResultsControllerDelegate
//-----------------------------------------------------------------

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type {
    
    NSIndexSet *section = [NSIndexSet indexSetWithIndex:sectionIndex];
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:section
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:section
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
        default:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
        case NSFetchedResultsChangeUpdate:
            if (!newIndexPath) {
                [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                                      withRowAnimation:UITableViewRowAnimationNone];
            } else {
                [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                                      withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView insertRowsAtIndexPaths:@[newIndexPath]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            break;
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        default:
            break;
    }
}

@end
