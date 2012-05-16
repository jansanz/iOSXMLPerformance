//
//  TBXMLParser.m
//  XMLPerformance
//
//  Created by Ray Wenderlich on 2/24/10.
//  Copyright 2010 Ray Wenderlich. All rights reserved.
//

#import "TBXMLParser.h"
#import "Song.h"
#import "TBXML.h"

@implementation TBXMLParser

@synthesize parseFormatter, xmlData, rssConnection;

+ (NSString *)parserName {
    return @"TBXMLParser";
}

+ (XMLParserType)parserType {
    return XMLParserTypeTBXMLParser;
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
static NSString *kName_Channel = @"channel";
static NSString *kName_Item = @"item";
static NSString *kName_Title = @"title";
static NSString *kName_Category = @"category";
static NSString *kName_Artist = @"itms:artist";
static NSString *kName_Album = @"itms:album";
static NSString *kName_ReleaseDate = @"itms:releasedate";

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self performSelectorOnMainThread:@selector(downloadEnded) withObject:nil waitUntilDone:NO];
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    NSError *error;
    TBXML * tbxml = [[TBXML alloc] initWithXMLData:xmlData error:&error];
    TBXMLElement *root = tbxml.rootXMLElement;
    if (root) {
        TBXMLElement * channel = [TBXML childElementNamed:kName_Channel parentElement:root];
        if (channel) {
            TBXMLElement *item = [TBXML childElementNamed:kName_Item parentElement:channel];
            while (item != nil) {
                Song * song = [[Song alloc] init];
                TBXMLElement *title = [TBXML childElementNamed:kName_Title parentElement:item];
                if (title != nil) {
                    song.title = [TBXML textForElement:title];
                }
                TBXMLElement *category = [TBXML childElementNamed:kName_Category parentElement:item];
                if (category != nil) {
                    song.category = [TBXML textForElement:category];
                }
                TBXMLElement *artist = [TBXML childElementNamed:kName_Artist parentElement:item];
                if (artist != nil) {
                    song.artist = [TBXML textForElement:artist];
                }
                TBXMLElement *album = [TBXML childElementNamed:kName_Album parentElement:item];
                if (album != nil) {
                    song.album = [TBXML textForElement:album];
                }
                TBXMLElement *releaseDate = [TBXML childElementNamed:kName_ReleaseDate parentElement:item];
                if (releaseDate != nil) {
                    NSString *releaseDateStr = [TBXML textForElement:releaseDate];
                    song.releaseDate = [parseFormatter dateFromString:releaseDateStr];
                }
                [self performSelectorOnMainThread:@selector(parsedSong:) withObject:song waitUntilDone:NO];
                // performSelectorOnMainThread: will retain the object until the selector has been performed
                // so we can release our reference
                [song release];
                item = [TBXML nextSiblingNamed:kName_Item searchFromElement:item];
            }
        }
    }
    [tbxml release];
    NSTimeInterval duration = [NSDate timeIntervalSinceReferenceDate] - start;
    [self performSelectorOnMainThread:@selector(addToParseDuration:) withObject:[NSNumber numberWithDouble:duration] waitUntilDone:NO];
    [self performSelectorOnMainThread:@selector(parseEnded) withObject:nil waitUntilDone:NO];
    self.xmlData = nil;
    // Set the condition which ends the run loop.
    done = YES; 
}

@end
