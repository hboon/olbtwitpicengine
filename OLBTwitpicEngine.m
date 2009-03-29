//
//  OLBTwitpicEngine.m
// ----------------------------------------------------------------------
// Controller class for uploading a UIImage to TwitPic.com and post to Twitter.com.
// This procedure automatically posts to the Twitter account specified.
//
// (c) 2008 Oskar Lissheim-Boethius (www.OLBproductions.com)
// ----------------------------------------------------------------------
// This code may be used without restriction in any software, commercial,
// free, or otherwise. There are no attribution requirements, and no
// requirement that you distribute your changes, although bugfixes and 
// enhancements are welcome.
// 
// If you do choose to re-distribute the source code, you must retain the
// copyright notice and this license information. I also request that you
// place comments in to identify your changes.
// ----------------------------------------------------------------------
// What you need to do:
// 1. Import the OLBTwitpicEngine.h header file into your Controller class.
// 2. Download and import the RegexKitLite class (just google it). It's used for parsing the TwitPic post URL from the XML response we get back.
// 3. Set the delegate in your Controller and implement the OLBTwitpicEngineDelegate protocol.
// 4. Call the "uploadImageToTwitpic:withMessage:username:password:" and send along the UIImage, the user's Twitter username and password, as well as the text to post alongside the TwitPic link in the Twitter post.
// 5. Get called back with the delegate method when the thread is done uploading (or has failed doing so).
// 6. Profit.


#import "OLBTwitpicEngine.h"
#import "RegexKitLite.h"

#define kTwitpicUploadURL @"https://twitpic.com/api/uploadAndPost"  // Note: This URL automatically posts to Twitter on upload
#define kTwitpicImageJPEGCompression 0.4  // Between 0.1 and 1.0, where 1.0 is the highest quality JPEG compression setting


@implementation OLBTwitpicEngine


- (id)initWithDelegate:(id)theDelegate
{
	if (self = [super init])
	{
		delegate = theDelegate;  // Set delegate (don't make the mistake and release this later...)
	}
	return self;
}


- (void)uploadingDataWithURLRequest:(NSURLRequest *)urlRequest
{
	// Called on a separate thread; upload and handle server response
	NSHTTPURLResponse *urlResponse;
	NSError			  *error;
	NSString		  *responseString;
	NSData			  *responseData;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];		// Each thread must have its own NSAutoreleasePool
	
	[urlRequest retain];  // Retain since we autoreleased it before
	
	// Send the request
	urlResponse = nil;  
	responseData = [NSURLConnection sendSynchronousRequest:urlRequest
										 returningResponse:&urlResponse   
													 error:&error];  
	responseString = [[NSString alloc] initWithData:responseData
										   encoding:NSUTF8StringEncoding];
	
	// Handle the error or success
	// If error, create error message and throw up UIAlertView
//	NSLog(@"Response Code: %d", [urlResponse statusCode]);
	if ([urlResponse statusCode] >= 200 && [urlResponse statusCode] < 300)
	{
//		NSLog(@"urlResultString: %@", responseString);

		NSString *match = [responseString stringByMatching:@"http[a-zA-Z0-9.:/]*"];  // Match the URL for the twitpic.com post
//		NSLog(@"match: %@", match);
		
		NSRange matchedRange = [responseString rangeOfRegex:@"code=\"(\\d+)\"" capture:1];
		if (matchedRange.location == NSNotFound) {
			// Send back notice to delegate
			[delegate twitpicEngine:self didUploadImageWithResponse:match statusCode:200];
		} else {
			NSString *matchCode = [responseString substringWithRange:matchedRange];
//			NSLog(@"code: %@", matchCode);
			// Send back notice to delegate
			[delegate twitpicEngine:self didUploadImageWithResponse:match statusCode:[matchCode integerValue]];
		}
	}
	else
	{
		NSLog(@"Error while uploading, got 400 error back or no response at all: %@", [urlResponse statusCode]);
		[delegate twitpicEngine:self didUploadImageWithResponse:nil statusCode:[urlResponse statusCode]];  // Nil should mean "upload failed" to the delegate
	}
	
	[pool release];	 // Release everything except responseData and urlResponse–they're autoreleased on creation
	[responseString release];  
	[urlRequest release];
}


- (BOOL)uploadImageToTwitpic:(UIImage *)image withMessage:(NSString *)theMessage 
					username:(NSString *)username password:(NSString *)password
{
	NSString			*stringBoundary, *contentType, *message, *baseURLString, *urlString;
	NSData				*imageData;
	NSURL				*url;
	NSMutableURLRequest *urlRequest;
	NSMutableData		*postBody;
	
	// Create POST request from message, imageData, username and password
	baseURLString	= kTwitpicUploadURL;
	urlString		= [NSString stringWithFormat:@"%@", baseURLString];  
	url				= [NSURL URLWithString:urlString];
	urlRequest		= [[[NSMutableURLRequest alloc] initWithURL:url] autorelease];
	[urlRequest setHTTPMethod:@"POST"];	
	
	// Set the params
//	message		  = ([theMessage length] > 1) ? theMessage : @"Here's my new Light Table collage.";
	message = theMessage;
	imageData	  = UIImageJPEGRepresentation(image, kTwitpicImageJPEGCompression);
	
	// Setup POST body
	stringBoundary = [NSString stringWithString:@"0xKhTmLbOuNdArY"];
	contentType    = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", stringBoundary];
	[urlRequest addValue:contentType forHTTPHeaderField:@"Content-Type"]; 
	
	// Setting up the POST request's multipart/form-data body
	postBody = [NSMutableData data];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n\r\n--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"source\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:@"simplytweetcom"] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"username\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:username] dataUsingEncoding:NSUTF8StringEncoding]];  // username
	
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"password\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:password] dataUsingEncoding:NSUTF8StringEncoding]];  // password
	
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"message\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:message] dataUsingEncoding:NSUTF8StringEncoding]];  // message
	
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"media\"; filename=\"%@\"\r\n", @"lighttable_twitpic_image.jpg" ] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:@"Content-Type: image/jpg\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];  // jpeg as data
	[postBody appendData:[[NSString stringWithString:@"Content-Transfer-Encoding: binary\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:imageData];  // Tack on the imageData to the end
	
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[urlRequest setHTTPBody:postBody];
	
	// Spawn a new thread so the UI isn't blocked while we're uploading the image
    [NSThread detachNewThreadSelector:@selector(uploadingDataWithURLRequest:) toTarget:self withObject:urlRequest];	
	
	return YES;  // TODO: Should raise exception on error
}


#pragma mark -
#pragma mark Misc


- (void)dealloc 
{	
	// No ivars to release
    [super dealloc];
}


@end
