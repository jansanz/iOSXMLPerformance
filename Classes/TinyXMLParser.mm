//
//  TinyXMLParser.m
//  XMLPerformance
//
//  Created by Ray Wenderlich on 2/24/10.
//  Copyright 2010 Ray Wenderlich. All rights reserved.
//

#import "TinyXMLParser.h"
#import "Song.h"
#include "tinyxml.h"

@implementation TinyXMLParser

@synthesize parseFormatter, xmlData, rssConnection;

+ (NSString *)parserName {
    return @"TinyXMLParser";
}

+ (XMLParserType)parserType {
    return XMLParserTypeTinyXMLParser;
}

- (void)downloadAndParse:(NSURL *)url {
    
    done = NO;
    self.parseFormatter = [[NSDateFormatter alloc] init];
    [parseFormatter setDateStyle:NSDateFormatterLongStyle];
    [parseFormatter setTimeStyle:NSDateFormatterNoStyle];
    // necessary because iTunes RSS feed is not localized, so if the device region has been set to other than US
    // the date formatter must be set to US locale in order to parse the dates
    [parseFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"US"]];
    self.xmlData = [NSMutableData data];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSURLRequest *theRequest = [NSURLRequest requestWithURL:url];
    // create the connection with the request and start loading the data
    rssConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    [self performSelectorOnMainThread:@selector(downloadStarted) withObject:nil waitUntilDone:NO];
    if (rssConnection != nil) {
        do {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        } while (!done);
    }
    self.rssConnection = nil;
    self.parseFormatter = nil;
    
}

#pragma mark NSURLConnection Delegate methods

/*
 Disable caching so that each time we run this app we are starting with a clean slate. You may not want to do this in your application.
 */
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

// Forward errors to the delegate.
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    done = YES;
    [self performSelectorOnMainThread:@selector(parseError:) withObject:error waitUntilDone:NO];
}

// Called when a chunk of data has been downloaded.
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the downloaded chunk of data.
    [xmlData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self performSelectorOnMainThread:@selector(downloadEnded) withObject:nil waitUntilDone:NO];
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    
    // Need to null terminate data...
    char *buffer = new char[xmlData.length+1];
    [xmlData getBytes:buffer];
    buffer[xmlData.length] = '\0';
    
    TiXmlDocument * doc = new TiXmlDocument();
    doc->Parse(buffer, 0, TIXML_ENCODING_UTF8);
    TiXmlHandle docHandle(doc);
    
    // We could have used TinyXPath to do this query instead, but I didn't feel like integrating it :P
    
    TiXmlElement *item = docHandle.FirstChild("rss").FirstChild("channel").FirstChild("item").ToElement();
    while (item != NULL) {
        Song * song = [[Song alloc] init];
        TiXmlElement *title = item->FirstChildElement("title");
        if (title != NULL) {
            song.title = [NSString stringWithUTF8String:title->GetText()];
        }
        TiXmlElement *category = item->FirstChildElement("category");
        if (category != NULL) {
            song.category = [NSString stringWithUTF8String:category->GetText()];
        }
        TiXmlElement *artist = item->FirstChildElement("itms:artist");
        if (artist != NULL) {
            song.artist = [NSString stringWithUTF8String:artist->GetText()];
        }
        TiXmlElement *album = item->FirstChildElement("itms:album");
        if (album != NULL) {
            song.album = [NSString stringWithUTF8String:album->GetText()];
        }
        TiXmlElement *releaseDate = item->FirstChildElement("itms:releasedate");
        if (releaseDate != NULL) {
            NSString *releaseDateStr = [NSString stringWithUTF8String:releaseDate->GetText()];
            song.releaseDate = [parseFormatter dateFromString:releaseDateStr];
        }
        item = item->NextSiblingElement();
        [self performSelectorOnMainThread:@selector(parsedSong:) withObject:song waitUntilDone:NO];
        // performSelectorOnMainThread: will retain the object until the selector has been performed
        // so we can release our reference
    }
    
    delete [] buffer;
    delete doc;
    
    NSTimeInterval duration = [NSDate timeIntervalSinceReferenceDate] - start;
    [self performSelectorOnMainThread:@selector(addToParseDuration:) withObject:[NSNumber numberWithDouble:duration] waitUntilDone:NO];
    [self performSelectorOnMainThread:@selector(parseEnded) withObject:nil waitUntilDone:NO];
    self.xmlData = nil;
    // Set the condition which ends the run loop.
    done = YES; 
}

@end
