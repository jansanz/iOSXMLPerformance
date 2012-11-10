//
//  RaptureXMLParser.h
//  XMLPerformance
//
//  Created by Jan Sanchez Dudus on 5/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iTunesRSSParser.h"

@interface RaptureXMLParser : iTunesRSSParser {
    BOOL done;
    
}

@property (nonatomic, strong) NSDateFormatter *parseFormatter;
@property (nonatomic, strong) NSMutableData *xmlData;
@property (nonatomic, strong) NSURLConnection *rssConnection;

- (void)downloadAndParse:(NSURL *)url;
@end
