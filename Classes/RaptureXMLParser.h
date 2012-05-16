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

@property (nonatomic, retain) NSDateFormatter *parseFormatter;
@property (nonatomic, retain) NSMutableData *xmlData;
@property (nonatomic, retain) NSURLConnection *rssConnection;

- (void)downloadAndParse:(NSURL *)url;
@end
