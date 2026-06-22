//
//  SQLProKeywordsHelper.m
//  SQLProCore
//
//  Created by Kyle Hankinson on 2020-06-05.
//  Copyright © 2020 Hankinsoft Development, Inc. All rights reserved.
//

#import <SQLProResources/SQLProKeywordsHelper.h>

@implementation SQLProKeywordsHelper
{
    NSOrderedSet<NSString*>* keywords;
    NSOrderedSet<NSString*>* functions;
    NSOrderedSet<NSString*>* functionsAndKeywords;
}

+ (NSOrderedSet<NSString*>*) defaultKeywords
{
    static NSOrderedSet<NSString*>* defaultKeywords = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // https://github.com/fibo/SQL92-keywords/blob/master/index.json
        NSString * keywordsPath = [[NSBundle bundleForClass: SQLProKeywordsHelper.class] pathForResource: @"SQLProKeywords"
                                                                                                  ofType: @"json"];

        NSData * data = [NSData dataWithContentsOfFile: keywordsPath];
        NSArray<NSString*>* keywords = nil;
        if(data)
        {
            NSError * error = nil;
            keywords = [NSJSONSerialization JSONObjectWithData: data
                                                       options: kNilOptions
                                                         error: &error];
        }

        defaultKeywords = [[NSOrderedSet alloc] initWithArray: [keywords sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)]];
    });

    return defaultKeywords;
}

- (id) initWithKeywordsResourceName: (NSString*) keywordsResourceName
              functionsResourceName: (NSString*) functionsResourceName
{
    self = [self init];
    if(self)
    {
        // Setup our targetBundle
        NSBundle * targetBundle = [NSBundle bundleForClass: SQLProKeywordsHelper.class];

        // Setup our sqlKeywords
        NSMutableArray * sqlKeywords = @[].mutableCopy;

        if(0 != keywordsResourceName.length)
        {
            NSString * keywordsPath = [targetBundle pathForResource: keywordsResourceName
                                                             ofType: @"json"];

            NSData * data = [NSData dataWithContentsOfFile: keywordsPath];
            NSArray<NSString*>* tempKeywords = nil;
            if(data)
            {
                NSError * error = nil;
                tempKeywords = [NSJSONSerialization JSONObjectWithData: data
                                                               options: kNilOptions
                                                                 error: &error];
            }

            if(tempKeywords.count)
            {
                sqlKeywords = [tempKeywords sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)].mutableCopy;
            }
        }

        // Add the default keywords
        [sqlKeywords addObjectsFromArray: SQLProKeywordsHelper.defaultKeywords.array];
        [sqlKeywords sortUsingSelector: @selector(localizedCaseInsensitiveCompare:)];

        // Setup our sqlKeywords
        NSArray * sqlFunctions = @[];
        if(0 != functionsResourceName.length)
        {
            NSString * functionsPath = [targetBundle pathForResource: functionsResourceName
                                                             ofType: @"json"];

            NSData * data = [NSData dataWithContentsOfFile: functionsPath];
            NSDictionary<NSString*,NSDictionary*>* tempFunctions = nil;
            if(data)
            {
                NSError * error = nil;
                tempFunctions = [NSJSONSerialization JSONObjectWithData: data
                                                               options: kNilOptions
                                                                 error: &error];
            }

            if(tempFunctions.allKeys.count)
            {
                sqlFunctions = [tempFunctions.allKeys sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)].mutableCopy;
            }
        }

        keywords  = [NSOrderedSet orderedSetWithArray: sqlKeywords];
        functions = [NSOrderedSet orderedSetWithArray: sqlFunctions];

        NSMutableArray* found = @[].mutableCopy;
        for(NSString * keyword in keywords)
        {
            if(NSNotFound != [sqlFunctions indexOfObject: keyword.uppercaseString])
            {
                [found addObject: keyword];
            }
        }

        // Note: some engines (e.g. ClickHouse) do not ship a keywords/functions
        // resource. A missing resource yields an empty set rather than a crash.
        if(0 == sqlKeywords.count)  { NSLog(@"[SQLProKeywordsHelper] No keywords loaded for resource '%@'.", keywordsResourceName); }
        if(0 == sqlFunctions.count) { NSLog(@"[SQLProKeywordsHelper] No functions loaded for resource '%@'.", functionsResourceName); }

        NSMutableSet * allFunctionsAndKeywords = [NSMutableSet set];

        [allFunctionsAndKeywords addObjectsFromArray: sqlKeywords];
        [allFunctionsAndKeywords addObjectsFromArray: sqlFunctions];

        // Set our sorted set
        functionsAndKeywords = [NSOrderedSet orderedSetWithArray: [allFunctionsAndKeywords.allObjects sortedArrayUsingSelector: @selector(localizedCaseInsensitiveCompare:)]];
    }

    return self;
} // End of initWithBundle:resourceName:

- (NSOrderedSet<NSString*>*) keywords
{
    return keywords;
}

- (NSOrderedSet<NSString*>*) functions
{
    return functions;
}

- (NSOrderedSet<NSString*>*) functionsAndKeywords
{
    return functionsAndKeywords;
} // End of functionsAndKeywords

@end
