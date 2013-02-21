iOS XMLPerformance
=================

Benchmark results and more information in my [blog post](http://jansanchez.com/blog/2013/01/22/state-of-ios-xml-libraries-in-2013/).

XML Parser performance on iOS. Based on code take from [this blog post](http://www.raywenderlich.com/553/how-to-chose-the-best-xml-parser-for-your-iphone-project)
which in turn is based on Apple's [XMLPerformance](http://developer.apple.com/library/ios/#samplecode/XMLPerformance/Introduction/Intro.html#//apple_ref/doc/uid/DTS40008094-Intro-DontLinkElementID_2).

Support for RaptureXML, TinyXML2 was added as well as all XML parsing libraries have been updated to their latest versions.

ARC required. Some XML parsing libraries do not use ARC.

## **Instructions**
1. Clone this project
2. git submodule init && git submodule update
3. Build and run it

## XML Parsers included
- NSXMLParser
- libxml2
- TBXML
- TouchXML
- KissXML
- TinyXML
- GDataXML
- RaptureXML
- TinyXML2

## Future Plans
- Fully revamp this test, there is no need for downloading the file over the internet. Include few XML samples, both smaller and bigger
