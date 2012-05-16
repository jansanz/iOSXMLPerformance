//
//  KissXMLParser.m
//  XMLPerformance
//
//  Created by Ray Wenderlich on 2/24/10.
//  Copyright 2010 Ray Wenderlich. All rights reserved.
//

#import "KissXMLParser.h"
#import "Song.h"
#import "DDXML.h"
#import "DDXMLElementAdditions.h"

@implementation KissXMLParser

@synthesize parseFormatter, xmlData, rssConnection;

+ (NSString *)parserName {
    return @"KissXMLParser";
}

+ (XMLParserType)parserType {
    return XMLParserTypeKissXMLParser;
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
    
    DDXMLDocument *doc = [[DDXMLDocument alloc] initWithData:xmlData options:0 error:nil];
    NSArray *items = [doc nodesForXPath:kXPath_Item error:nil];
    for (DDXMLElement *item in items) {
        Song * song = [[Song alloc] init];        
        DDXMLElement *title = [item elementForName:kName_Title];
        if (title) {
            song.title = title.stringValue;
        }
        DDXMLElement *category = [item elementForName:kName_Category];
        if (category) {
            song.category = category.stringValue;
        }
        DDXMLElement *artist = [item elementForName:kName_Artist];
        if (artist) {
            song.artist = artist.stringValue;
        }
        DDXMLElement *album = [item elementForName:kName_Album];
        if (album) {
            song.album = album.stringValue;
        }
        DDXMLElement *releaseDate = [item elementForName:kName_ReleaseDate];
        if (releaseDate) {
            NSString *releaseDateStr = releaseDate.stringValue;
            song.releaseDate = [parseFormatter dateFromString:releaseDateStr];
        }
        [self performSelectorOnMainThread:@selector(parsedSong:) withObject:song waitUntilDone:NO];
        // performSelectorOnMainThread: will retain the object until the selector has been performed
        // so we can release our reference
        [song release];
    }
    [doc release];
    NSTimeInterval duration = [NSDate timeIntervalSinceReferenceDate] - start;
    [self performSelectorOnMainThread:@selector(addToParseDuration:) withObject:[NSNumber numberWithDouble:duration] waitUntilDone:NO];
    [self performSelectorOnMainThread:@selector(parseEnded) withObject:nil waitUntilDone:NO];
    self.xmlData = nil;
    // Set the condition which ends the run loop.
    done = YES; 
}


@end
