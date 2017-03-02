//
//  Product+CoreDataProperties.h
//  CKCoreDataHelper
//
//  Created by Enix Yu on 2/3/2017.
//  Copyright © 2017 RobotBros. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Product.h"

NS_ASSUME_NONNULL_BEGIN

@interface Product (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSDecimalNumber *price;
@property (nullable, nonatomic, retain) NSNumber *stock;
@property (nullable, nonatomic, retain) NSNumber *attr1;
@property (nullable, nonatomic, retain) NSNumber *attr2;
@property (nullable, nonatomic, retain) NSNumber *attr3;
@property (nullable, nonatomic, retain) NSNumber *attr4;
@property (nullable, nonatomic, retain) NSNumber *attr5;
@property (nullable, nonatomic, retain) NSNumber *attr6;
@property (nullable, nonatomic, retain) NSDate *attr7;
@property (nullable, nonatomic, retain) Shop *shop;

@end

NS_ASSUME_NONNULL_END
