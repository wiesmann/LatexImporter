#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h> 
#import <AppKit/AppKit.h>
#import "LatexParser.h"


/* -----------------------------------------------------------------------------
   Step 1
   Set the UTI types the importer supports
  
   Modify the CFBundleDocumentTypes entry in Info.plist to contain
   an array of Uniform Type Identifiers (UTI) for the LSItemContentTypes 
   that your importer can handle
  
   ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   Step 2 
   Implement the GetMetadataForFile function
  
   Implement the GetMetadataForFile function below to scrape the relevant
   metadata from your document and return it as a CFDictionary using standard keys
   (defined in MDItem.h) whenever possible.
   ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   Step 3 (optional) 
   If you have defined new attributes, update the schema.xml file
  
   Edit the schema.xml file to include the metadata keys that your importer returns.
   Add them to the <allattrs> and <displayattrs> elements.
  
   Add any custom types that your importer requires to the <attributes> element
  
   <attribute name="com_mycompany_metadatakey" type="CFString" multivalued="true"/>
  
   ----------------------------------------------------------------------------- */



/* -----------------------------------------------------------------------------
    Get metadata attributes from file
   
   This function's job is to extract useful information your file format supports
   and return it as a dictionary

   Not many changes from the original template by Apple. 

   ----------------------------------------------------------------------------- */

Boolean GetMetadataForFile(void* thisInterface, 
			   CFMutableDictionaryRef attributes, 
			   CFStringRef contentTypeUTI,
			   CFStringRef pathToFile)
{
    Boolean result = FALSE ; 
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    NSMutableDictionary * dictionary = (NSMutableDictionary *) attributes ; 
    NSString *path = (NSString *) pathToFile ; 
    NSData *latex_data = [NSData dataWithContentsOfFile: path] ;     
    if (latex_data) {
	LatexParser *parser = [[LatexParser alloc] initWithLatexData: latex_data commandName: @"commands" commandType: @"plist"] ;
	NSString *title = [parser getTitle] ; 
	if (title) {
	    [dictionary setObject:title forKey:(id)kMDItemTitle] ; 
	} 
	NSString *authors = [parser getAuthors] ; 
	if (authors) {
	    [dictionary setObject:authors forKey:(id)kMDItemAuthors] ; 
	} 
	NSString *full_text = [parser getFullText] ; 
	if (full_text) {
	    [dictionary setObject: full_text forKey: (id) kMDItemTextContent] ; 
	} 
	NSArray *citations = [parser getCitations] ; 
	if (citations) {
	    [dictionary setObject:citations forKey: @"org_tug_latex_cite"];
	}
	
	[parser release] ;
	result = TRUE ; 
    } /* path */
    [pool release];
    return result;
}
