//
//  LibXMLDOMParser.m
//  XMLPerformance
//
//  Created by Ray Wenderlich on 2/25/10.
//  Copyright 2010 Ray Wenderlich. All rights reserved.
//

#import "LibXMLDOMParser.h"
#import "Song.h"
#import <libxml/parser.h>
#import <libxml/tree.h>
#import <libxml/xpath.h>

@implementation LibXMLDOMParser

@synthesize parseFormatter, xmlData, rssConnection;

+ (NSString *)parserName {
    return @"LibXMLDOMParser";
}

+ (XMLParserType)parserType {
    return XMLParserTypeLibXMLDOMParser;
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

xmlNode* findElement(xmlNode *child, xmlChar *elementName) {
 
    while (child != NULL) {
        if (child->type == XML_ELEMENT_NODE) {
            if (strncmp(child->name, elementName, strlen(elementName)) == 0) {
                return child;
            }
        }
        child = child->next;
    }
    return NULL;
    
}

xmlChar* findTextForFirstChild(xmlNode *parent, xmlChar *elementName) {
 
    xmlNode *child = findElement(parent->children, elementName);
    if (child) {
        xmlNode *text = child->children;
        if (text && text->type == XML_TEXT_NODE) {
            return text->content;
        }
    }
    return NULL;
    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self performSelectorOnMainThread:@selector(downloadEnded) withObject:nil waitUntilDone:NO];
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    xmlDoc * doc = xmlParseMemory(xmlData.bytes, xmlData.length);
    if (doc) {        
        xmlXPathContext *xPathCtx = xmlXPathNewContext(doc);
        if (xPathCtx) {
            xmlXPathObject *xPathObj = xmlXPathEvalExpression("///item", xPathCtx);
            if (xPathObj) {
                xmlNodeSet *nodeSet = xPathObj->nodesetval;                              
                for (int i = 0; i < nodeSet->nodeNr; ++i) {
                    xmlNode *item = nodeSet->nodeTab[i];
                       
                    Song * song = [[Song alloc] init];
                    xmlChar *title = findTextForFirstChild(item, "title");
                    if (title != NULL) {
                        song.title = [NSString stringWithUTF8String:title];
                    }
                    xmlChar *category = findTextForFirstChild(item, "category");
                    if (category != NULL) {
                        song.category = [NSString stringWithUTF8String:category];
                    }
                    xmlChar *artist = findTextForFirstChild(item, "artist");
                    if (artist != NULL) {
                        song.artist = [NSString stringWithUTF8String:artist];
                    }
                    xmlChar *album = findTextForFirstChild(item, "album");
                    if (album != NULL) {
                        song.album = [NSString stringWithUTF8String:album];
                    }
                    xmlChar *releaseDate = findTextForFirstChild(item, "releasedate");
                    if (releaseDate != NULL) {
                        NSString *releaseDateStr = [NSString stringWithUTF8String:releaseDate];
                        song.releaseDate = [parseFormatter dateFromString:releaseDateStr];
                    }                    
                    [self performSelectorOnMainThread:@selector(parsedSong:) withObject:song waitUntilDone:NO];
                    // performSelectorOnMainThread: will retain the object until the selector has been performed
                    // so we can release our reference
                }                
                xmlXPathFreeObject(xPathObj);
            }
            xmlXPathFreeContext(xPathCtx);
        }
        xmlFreeDoc(doc);
    }
    NSTimeInterval duration = [NSDate timeIntervalSinceReferenceDate] - start;
    [self performSelectorOnMainThread:@selector(addToParseDuration:) withObject:@(duration) waitUntilDone:NO];
    [self performSelectorOnMainThread:@selector(parseEnded) withObject:nil waitUntilDone:NO];
    self.xmlData = nil;
    // Set the condition which ends the run loop.
    done = YES; 
}

@end