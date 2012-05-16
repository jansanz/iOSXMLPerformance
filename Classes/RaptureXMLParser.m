//
//  RaptureXMLParser.m
//  XMLPerformance
//
//  Created by Jan Sanchez Dudus on 5/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RaptureXMLParser.h"
#import "Song.h"
#import "RXMLElement.h"

@implementation RaptureXMLParser

@synthesize parseFormatter, xmlData, rssConnection;

+ (NSString *)parserName {
    return @"RaptureXMLParser";
}

+ (XMLParserType)parserType {
    return XMLParserTypeRaptureXMLParser;
}

- (void)downloadAndParse:(NSURL *)url {
    
    done = NO;
    self.parseFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [parseFormatter setDateStyle:NSDateFormatterLongStyle];
    [parseFormatter setTimeStyle:NSDateFormatterNoStyle];
    // necessary because iTunes RSS feed is not localized, so if the device region has been set to other than US
    // the date formatter must be set to US locale in order to parse the dates
    [parseFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"US"] autorelease]];
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

// Constants for the XML element names that will be considered during the parse. 
// Declaring these as static constants reduces the number of objects created during the run
// and is less prone to programmer error.
static NSString *kXPath_Item = @"//item";
static NSString *kName_Title = @"title";
static NSString *kName_Category = @"category";
static NSString *kName_Artist = @"artist";
static NSString *kName_Album = @"album";
static NSString *kName_ReleaseDate = @"releasedate";

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self performSelectorOnMainThread:@selector(downloadEnded) withObject:nil waitUntilDone:NO];
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    
    RXMLElement *rootXML = [RXMLElement elementFromXMLData:xmlData];
    
    __block Song *song = nil;
    
    [rootXML iterateWithRootXPath:kXPath_Item usingBlock:^(RXMLElement *item) {
        song = [[Song alloc] init];
        
        song.title = [item child:kName_Title].text;
        song.category = [item child:kName_Category].text;
        song.artist = [item child:kName_Album].text;
        song.album = [item child:kName_Album].text;
        song.releaseDate = [parseFormatter dateFromString:[item child:kName_ReleaseDate].text];
        
        [self performSelectorOnMainThread:@selector(parsedSong:) withObject:song waitUntilDone:NO];
        
        [song release], song = nil;
    }];
     
     NSTimeInterval duration = [NSDate timeIntervalSinceReferenceDate] - start;
     [self performSelectorOnMainThread:@selector(addToParseDuration:) withObject:[NSNumber numberWithDouble:duration] waitUntilDone:NO];
     [self performSelectorOnMainThread:@selector(parseEnded) withObject:nil waitUntilDone:NO];
     self.xmlData = nil;
     // Set the condition which ends the run loop.
     done = YES; 
}

@end
