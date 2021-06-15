local AttributeUtils = require "AttributeUtils"
-- Table printing utility
local function tprint(tbl, prefix, indent)
  if not indent then indent = 0 end
  if not prefix then prefix = "" end

  if type(tbl) ~= 'table' then
    print(prefix .. tostring(tbl))
    return
  end

  for k, v in pairs(tbl) do
    local formatting = prefix .. string.rep("  ", indent) .. k .. ": "
    local valueType = type(v)
    if valueType == "table" then
      print(formatting)
      tprint(v, indent+1, prefix)
    else
      print(formatting .. tostring(v))
    end
  end
end

-- Test data setup
local testDataTable =
{
  key1 = "value1",
  key2 = "value2"
}

local testDataArray =
{
  {
    key = "key1",
    value = "value1"
  },
  {
    key = "key2",
    value = "value2"
  }
}

--[[ Both of these should create the following attribute table:
| Key    | Value  |
|--------|--------|
| key1   | value1 |
| key1   | value2 |
--]]
--======= createAttributeTable =======--
-- Table input
local testAttTbl = AttributeUtils.createAttributeTable(vrScenesNode(), testDataTable)

vrNodeSetName(testAttTbl,"testDataTable")

--======= createAttributeTableFromArray =======--
-- Array input
local testAttTbl_Array = AttributeUtils.createAttributeTableFromArray(vrScenesNode(), testDataArray)

vrNodeSetName(testAttTbl_Array,"testDataArray")

--======= getAttributeIterator =======--
--[[ Should print:
Key  key1  Value  value1
Key  key2  Value  value2
--]]
for k,v in AttributeUtils.getAttributeIterator(testAttTbl) do
  print("Key",k,"Value",v)
end

--======= getAllAttributes =======--
--[[ Should print:
key1: value1
key2: value2
--]]
tprint(AttributeUtils.getAllAttributes(testAttTbl))

--[[ Should print:
PREFIX_key1: value1
PREFIX_key2: value2
--]]
tprint(AttributeUtils.getAllAttributes(testAttTbl,"PREFIX_"))

--======= getAttribute =======--
-- Should print "value1"
print(AttributeUtils.getAttribute(testAttTbl,"key1"))