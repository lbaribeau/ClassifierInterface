@implementation Symbol : CPObject
{
    CPString symbolName @accessors;
    int count @accessors;
}
- (Symbol)init:(CPString)aSymbolName
{
    [self setSymbolName:aSymbolName];
    [self setCount:1];
    return self;
}
- (void)increment
{
    [self setCount:[self count] + 1];
}
- (Boolean)isEqual:(Symbol)aSymbol
{
    return [self symbolName] === [aSymbol symbolName];
}
- (CPString)stringAndCountOutput
{
    return [[self symbolName] stringByAppendingFormat:@" (%d)", [self count]];
}
@end
