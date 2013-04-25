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
        var JsonObject = new Object();
        // Dynamically add properties to the object using the server names
        for (var j = 0; j < [map count]; ++j)
        {
            var objectKey = map[j][0],
                serverKey = map[j][1];
            if (serverKey !== 'data')
            {
                JsonObject[serverKey] = aGlyphArray[i][objectKey];
            }
            else
            {
                JsonObject[serverKey] = [aGlyphArray[i][objectKey] base64];
            }
        }
        [outArray addObject:JsonObject];
    }
    return outArray;
}
@end
