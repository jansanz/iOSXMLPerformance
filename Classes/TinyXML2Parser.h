//
//  TinyXML2Parser.h
//  XMLPerformance
//
//  Created by Jan Sanchez on 11/10/12.
//
//

#import "iTunesRSSParser.h"

@interface TinyXML2Parser : iTunesRSSParser

@property (nonatomic, strong) NSDateFormatter *parseFormatter;
@property (nonatomic, strong) NSMutableData *xmlData;
@property (nonatomic, strong) NSURLConnection *rssConnection;

- (void)downloadAndParse:(NSURL *)url;

@end
