//
//  OLBTwitpicEngine.h
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


#import <UIKit/UIKit.h>

@protocol OLBTwitpicEngineDelegate;

@interface OLBTwitpicEngine : NSObject 
{
	@private
	id<OLBTwitpicEngineDelegate> delegate;
}

- (id)initWithDelegate:(id)theDelegate;
- (BOOL)uploadImageToTwitpic:(UIImage *)image withMessage:(NSString *)theMessage username:(NSString *)username password:(NSString *)password;

@end


@protocol OLBTwitpicEngineDelegate <NSObject>
- (void)twitpicEngine:(OLBTwitpicEngine *)engine didUploadImageWithResponse:(NSString *)response statusCode:(NSInteger)statusCode;
@end

