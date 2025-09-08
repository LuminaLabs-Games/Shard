--[[ 
	Shard math is mainly used for formatting numbers with suffixes and full names. It supports OOP and functional programming.
	```lua
    -- // OOP:
	local ShardMath = require(script.Parent.ShardMath)
    local shardMath = ShardMath.new(1000000)
    print(shardMath:formatWithSuffix()) -- 1M
    print(shardMath:formatWithFullName()) -- 1 Million

    -- // Functional:
    print(ShardMath.formatNumberWithSuffix(1000000)) -- 1M
    print(ShardMath.formatNumberWithFullName(1000000)) -- 1 Million

    -- // With decimal places:
    print(ShardMath.formatNumberWithSuffix(1000000, 2)) -- 1.00M
	```
]]

local ShardMath = {}
ShardMath.__index = ShardMath

local suffixes = require(script.Suffixes)
local fullNames = require(script.FullNames)

type ShardMath = {
    number: number,
    decimalPlaces: number,
    formatWithSuffix: (self: ShardMath) -> string,
    formatWithFullName: (self: ShardMath) -> string,
}

function ShardMath.new(number: number, decimalPlaces: number?): ShardMath
    local self = setmetatable({}, ShardMath)
    self.number = number
    self.decimalPlaces = decimalPlaces or 1
    return self
end

local function roundToDecimal(number, decimalPlaces)
    local factor = 10 ^ decimalPlaces
    return math.floor(number * factor) / factor
end

function ShardMath.formatNumberWithSuffix(number: number, decimalPlaces: number?): string
    local absoluteNumber = math.abs(number)
    decimalPlaces = decimalPlaces or 1
    
    if absoluteNumber < 1000 then
        return tostring(number)
    end

    local suffixIndex = math.floor(math.log10(absoluteNumber) / 3)
    local suffix = suffixes[suffixIndex] or ""

    local scaledNumber = roundToDecimal(number / (1000 ^ suffixIndex), decimalPlaces)

    return string.format(`%.{decimalPlaces}f%s`, scaledNumber, suffix)
end

function ShardMath:formatWithSuffix(): string
    return ShardMath.formatNumberWithSuffix(self.number, self.decimalPlaces)
end

function ShardMath.formatNumberWithFullName(number: number, decimalPlaces: number): string
    local absoluteNumber = math.abs(number)
    decimalPlaces = decimalPlaces or 1

    if absoluteNumber < 1000 then
        return tostring(number)
    end

    local suffixIndex = math.floor(math.log10(absoluteNumber) / 3)
    local suffix = fullNames[suffixIndex] or ""

    local scaledNumber = roundToDecimal(number / (1000 ^ suffixIndex), decimalPlaces)

    return string.format(`%.{decimalPlaces}f %s`, scaledNumber, suffix)
end

function ShardMath:formatWithFullName(): string
    return ShardMath.formatNumberWithFullName(self.number, self.decimalPlaces)
end

return ShardMath
