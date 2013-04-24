@implementation Glyph : CPObject
{
    CPString    ulx             @accessors;
    CPString    uly             @accessors;
    CPString    nRows           @accessors;
    CPString    nCols           @accessors;
    CPString    idState         @accessors;
    CPString    idName          @accessors;
    CPString    idConfidence    @accessors;
    CPString    featureScaling  @accessors;
    CPArray     features        @accessors;
    CPData      pngData         @accessors;
}

+ (CPArray)glyphProperties
{
    return [
        ['ulx', 'ulx'],
        ['uly', 'uly'],
        ['nRows', 'nrows'],
        ['nCols', 'ncols'],
        ['idState', 'id_state'],
        ['idName', 'id_name'],
        ['idConfidence', 'id_confidence'],
        ['featureScaling', 'feature_scaling'],
        ['features', 'features'],
        ['pngData', 'data']
    ];
}

- (id)initWithJson:(JSObject)jsonObject
{
    // Takes JSON and makes a glyph object.  Uses glyphProperties to
    // index the values out of the JSON dictionary.
    // Usage: foo = [[Glyph alloc] initWithJson:serverResponse];
    var self = [self init];

    if (self)
    {
        var i = 0,
            count = [[Glyph glyphProperties] count],
            map = [Glyph glyphProperties];

        for (; i < count; i++)
        {
            var objectKey = map[i][0],
                serverKey = map[i][1];

            if (map[i][1] === 'data')
            {
                [self setValue:[CPData dataWithBase64:jsonObject[serverKey]] forKey:objectKey];

                //console.log("How is the data represented anyway.  Do I need to decode AND encode?");
                //console.log(jsonObject[serverKey]);  // data field of Json (base64)
                //console.log([CPData dataWithBase64:jsonObject[serverKey]]);  // decoded Json
            }
            else
                [self setValue:jsonObject[serverKey] forKey:objectKey];
        }
    }

    return self;
}

+ (CPArray)objectsFromJson:(CPArray)aJsonArray
{
    var i = 0,
        count = [aJsonArray count],
        outArray = [];

    for (; i < count; ++i)
    {
        var glyph = [[Glyph alloc] initWithJson:[aJsonArray objectAtIndex:i]];
        [outArray addObject:glyph];
    };

    return outArray;
}
+ (CPArray)objectsToJson:(CPArray)aGlyphArray
{
    var outArray = [],
        map = [Glyph glyphProperties];

    for (var i = 0; i < [aGlyphArray count]; ++i)
    {
        //var JsonGlyph = {
        //    ""
        // Will do it in a loop in order to dynamically add the properties
        // according to the contents of glyphProperties

        //var JsonObject = [[CPObject alloc] init];
        var JsonObject = new Object();
        for (var j = 0; j < [map count]; ++j)
        {
            var objectKey = map[j][0],
                serverKey = map[j][1];

            if (serverKey !== 'data')
            {
                console.log('Not data');
                // [JsonObject setValue:aGlyphArray[i][objectKey] forKey:serverKey];
                JsonObject[serverKey] = aGlyphArray[i][objectKey];
                    // Dynamically add properties to the object
            }
            else
            {
                console.log("data.");
//                console.log("Test out reverse transformer for data: print input and output.");
//                console.log(aGlyphArray[i][objectKey]);
//                console.log([aGlyphArray[i][objectKey] base64]);  // successful reverse-convert of base64 data
//                console.log("Leaving objectsToJson");
                // [JsonObject setValue:[aGlyphArray[i][objectKey] base64] forKey:serverKey];
                    // Not key value coding-compliant
                // JsonObject[serverKey] = [aGlyphArray[i][objectKey] base64];  // Not sure why data comes out as a CFMutableData
                // JsonObject['data'] = 'Hello!';
                JsonObject[serverKey] = [aGlyphArray[i][objectKey] base64];
            }
        }
        [outArray addObject:JsonObject];
    }
    console.log(outArray);
    return outArray;
}
@end

/*
+ (CPArray)objectsToJson:(CPArray)aGlyphArray
{

    var outArray = [],
        map = [Glyph glyphProperties];

    for (var i = 0; i < [aGlyphArray count]; ++i)
    {
        var JsonObject = [[CPObject alloc] init];
        console.log("i is " + i);
        for (var j = 0; j < [map count]; ++j)
        {
            var objectKey = map[j][0],
                serverKey = map[j][1];
            console.log("j is " + j);

            if (map[j][1] === 'data')
            {
                console.log("map[j][1] better be data:" + map[j][1]);
                console.log("Try to print the same stuff over here");
                console.log(aGlyphArray[i]);  //Glyph object
                console.log(aGlyphArray[i][objectKey]);  // 471
                console.log(aGlyphArray[i]['pngData']);  // CFMutable
                //debugger;
                // console.log([aGlyphArray[i][objectKey] _base64]);  //null
                // console.log([CPData base64:aGlyphArray[i][objectKey]]);  // not a class method
                // console.log([CPData dataWithString:aGlyphArray[i][objectKey]]);
                // console.log([aGlyphArray[i][objectKey] base64]);  // Why doesn't this link?
                console.log([aGlyphArray[i][objectKey] base64]);  // unrecognized selector
                console.log("Leaving objectsToJson");
                [JsonObject setValue:[aGlyphArray[i][objectKey] base64] forKey:serverKey];
            }
            else
                console.log("Pass");
                [JsonObject setValue:aGlyphArray[i][objectKey] forKey:serverKey];

            //console.log(objectKey);
            //console.log(serverKey);
            //console.log(aGlyphArray[i][objectKey]);
            //[JsonObject setValue:aGlyphArray[i][objectKey] forKey:serverKey];
                // Data probably won't get set properly.
                // Hmmm... do I need to make a new class to write the reverse
                // transformer?  Maybe a toString on the Glyph object would be
                // much better

        }
        [outArray addObject:JsonObject];
    }
    console.log(outArray);
}
*/
