# CKCoreDataHelper
An implementation of Core Data Helper origin from Textbook: 《Learning Core Data for iOS》.

## Installation:

### Pod

```ruby
pod 'CKCoreDataHelper'
```

## Usage:

### Core Data Setup

```objc
// Your database file name
NSString *storeFileName = @"test.sqlite";

// Initialized a core data manager
CKCoreDataManager *manager = [CKCoreDataManager sharedInstanced];

// Setup core data manager with given store file
NSError *error;
BOOL flag = [manager setupCoreDataWithStoreFileName:storeFileName // Store file name
                               lightWeightMigration:YES           // enable lightweight data migration
                                              error:&error];      // get the error if init failed
```

### Import data

There are two importer you can use to import data into persistent store. One for XML format, another for JSON format.

#### XML

```objc
// Initialize
_importer = [[CKCoreDataXMLImporter alloc]
                 initWithCoordinator:self.manager.coordinator
                 entitiesUniqueAttributes:@{@"Product": @"name",
                                            @"Shop": @"name"}];

NSURL *productXML = [bundle URLForResource:@"preload_product" withExtension:@"xml"];
    
[_importer importDataFrom:shopXML                                         // XML URL Path
                forEntity:@"Shop"                                         // The name for the Entity you need to import to
               completion:^(BOOL success, NSError * _Nullable error) {    // A callback when import finished.
                   XCTAssertTrue(success);
                   XCTAssertNil(error);
               }];
```

### JSON
```objc

// Initialize
_importer = [[CKCoreDataJSONImporter alloc]
                 initWithCoordinator:self.manager.coordinator
                 entitiesUniqueAttributes:@{@"Product": @"name",
                                            @"Shop": @"name"}];

NSURL *path = [bundle URLForResource:@"preload_product_withoutrel" withExtension:@"json"];

[_importer importDataFrom:path
                forEntity:@"Product"
               completion:^(BOOL success, NSError * _Nullable error) {
                   XCTAssertTrue(success);
                   XCTAssertNil(error);
               }];
```

## Entity CURD

### Retrieve record

```objc
NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Entity"];
NSArray *results = [_manager.context executeFetchRequest:fetchRequest error:nil];
```

### Sorting

```objc
NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"attribute Name" ascending:YES];
[fetchRequest setSortDescriptors:@[sort]];
```

### Filter (Using NSPredicate). [NSPredicate manual](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/Predicates/AdditionalChapters/Introduction.html#//apple_ref/doc/uid/TP40001789)

```objc
NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.name == %@", @"Enix"];
[fetchRequest setPredicate:predicate];
```

### 筛选 (Fetch Request Template)

1. Select Model.xcdatamodeld
2. Editor > Add Fetch Request
3. Set a name for your fetch request，eg, fetchByName
4. Add filtering expression
5. Get your fetch request template in code:

```objc
NSFetchRequest *req = [[_manager model]
                       fetchRequestTemplateForName:@"your fetch request name"];
```

### Create Entity instance

```objc
Entity *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"Entity"
                                                inManagedObjectContext:context];
```

### Delete record

```objc
// Get the record which is pending to remove
NSArray *results = [[coreDataHelper context] executeFetchRequest:fetchRequest error:nil];

// Delete the record
[[_manager context] deleteObject:[results firstObject]];
```

### Save

```objc
NSError *error = nil;
[context save:&error];
```
