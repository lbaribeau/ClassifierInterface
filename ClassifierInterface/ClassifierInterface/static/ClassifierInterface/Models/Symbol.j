@implementation Symbol : CPObject
{
    CPString symbolName @accessors;
    int count @accessors;
}
- (Symbol)init:(CPString)symbolName:(int)count
{
    [self symbolName] = symbolName;
    [self count] = count;
}
- (CPString)stringAndCountOutput
{
    return [[self symbolName] stringByAppendingFormat:@" (%d)", [self count]];
}
@end
