//
//  Shop+CoreDataProperties.h
//  CKCoreDataHelper
//
//  Created by Enix Yu on 1/3/2017.
//  Copyright © 2017 RobotBros. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Shop.h"

NS_ASSUME_NONNULL_BEGIN

@interface Shop (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *address;
@property (nullable, nonatomic, retain) NSSet<NSManagedObject *> *products;

@end

@interface Shop (CoreDataGeneratedAccessors)

- (void)addProductsObject:(NSManagedObject *)value;
- (void)removeProductsObject:(NSManagedObject *)value;
- (void)addProducts:(NSSet<NSManagedObject *> *)values;
- (void)removeProducts:(NSSet<NSManagedObject *> *)values;

@end

NS_ASSUME_NONNULL_END
