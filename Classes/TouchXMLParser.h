//
//  TouchXMLParser.h
//  XMLPerformance
//
//  Created by Ray Wenderlich on 2/24/10.
//  Copyright 2010 Ray Wenderlich. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iTunesRSSParser.h"

@interface TouchXMLParser : iTunesRSSParser {

    NSDateFormatter *parseFormatter;
    NSMutableData *xmlData;
    BOOL done;
    NSURLConnection *rssConnection;

}

@property (nonatomic, strong) NSDateFormatter *parseFormatter;
@property (nonatomic, strong) NSMutableData *xmlData;
@property (nonatomic, strong) NSURLConnection *rssConnection;

- (void)downloadAndParse:(NSURL *)url;

@end
