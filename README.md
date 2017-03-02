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
NSURL *path = [bundle URLForResource:@"preload_product_withoutrel" withExtension:@"json"];

[_importer importDataFrom:path
                forEntity:@"Product"
               completion:^(BOOL success, NSError * _Nullable error) {
                   XCTAssertTrue(success);
                   XCTAssertNil(error);
               }];
```

## Entity操作

### 获取记录

    // 创建一个查询request，并指定查询对象
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Entity"];

    // 通过context，执行查询，结果返回一个包含符合查询条件的Entity对象的NSArray
    NSArray *results = [context executeFetchRequest:fetchRequest error:nil];

### 排序

    // 指定排序的attribute name，并指定是否升序
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"attribute Name" ascending:YES];

    // 向查询请求添加排序设置
    [fetchRequest setSortDescriptors:@[sort]];

### 筛选 (使用NSPredicate). [NSPredicate 使用说明](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/Predicates/AdditionalChapters/Introduction.html#//apple_ref/doc/uid/TP40001789)

    // 创建一个predicate，设置筛选条件，具体语法请查看apple的Predicate Programming Guide
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.name == %@", @"Enix"];

    // 把predicate添加到查询请求中
    [fetchRequest setPredicate:predicate];


### 筛选 (Fetch Request Template)

1. 选择 Model.xcdatamodeld
2. Editor > Add Fetch Request
3. 设置fetch request的名字，如 fetchByName
4. 添加筛选条件
5. 在代码中使用fetch request template

        // 使用NSManagedObjectModel对象，并通过刚才新建的fetch request名，建立查询请求
        NSFetchRequest *req = [[coreDataHelper model]
                                fetchRequestTemplateForName:@"your fetch request name"];

### 创建Entity instance

    Entity *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"Entity"
                                                    inManagedObjectContext:context];


### 删除

    // 获取需删除的对象
    NSArray *results = [[coreDataHelper context] executeFetchRequest:fetchRequest error:nil];
    
    // 通过context删除该对象
    [[coreDataHelper context] deleteObject:[results firstObject]];

### 保存

    // 除了查询，所有对Managed Object的修改，都需要显式调用save方法，改变才会真正保存到storage
    NSError *error = nil;
    [context save:&error];
