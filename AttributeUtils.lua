-- Localisation
local vrNodeSetValue = vrNodeSetValue
local vrNodeGetValue = vrNodeGetValue
local vrNodeGetMetaNode = vrNodeGetMetaNode
local vrMetaNodeGetPropertyCount = vrMetaNodeGetPropertyCount
local vrMetaNodeGetPropertyByIndex = vrMetaNodeGetPropertyByIndex
local vrMetaNodeExists = vrMetaNodeExists
local vrCreateNode = vrCreateNode
local vrDeleteNode = vrDeleteNode
local vrTreeRoot = vrTreeRoot

-- Utility used by the createAttributeTable functions
-- Creates a new attribute table node of a given size
-- If the right size metanode exists that is used, otherwise one is created.
local function createAttributeTableNode(parent, propCount)

  -- find the existing attribute table metanode if it exists
  local metaname = "AttributeTable" .. propCount
  local existingMetaNode = vrMetaNodeExists(metaname, false)
  if existingMetaNode then
    local newNode = vrCreateNode(metaname, "AttributeTable", parent)
    return newNode
  end

  -- OK lets make one..
  local metaroot = vrTreeRoot():find("root/System/MetaRoot")
  local metanode = vrCreateNode("MetaNode", metaname, metaroot)

  -- add in the properties
  local c = 0
  while c < propCount do
    local val = vrCreateNode("MetaValue", "P" .. c, metanode)
    val.Type = 7 -- string
    val.DataSize = 8 -- 64bits
    val.Count = 1 -- only one value in this property
    c = c + 1
  end

  -- create the first instance of the metanode. 
  local newNode = vrCreateNode(metaname, "AttributeTable", parent)

  -- this is a bit weird, when the metanode is instantiated VRTree will create a new metanode node
  -- so we can now delete the one we just made. We can then also add the AttributeTable trait to it
  -- so the GUI treats it as an attribute table.
  vrDeleteNode(metanode)

  metanode = vrTreeRoot():find("root/System/MetaRoot/" .. metaname)  
  local trait = vrCreateNode("Trait_AttributeTable", "Trait_AttributeTable.1", metanode)
  trait.PrimaryProperty = -1

  return newNode
end

--[[ Put some data in an attribute table node

Used for storing data in the scene tree itself. Adapted from Barry King's comment on PS-184

This is the original version that uses an array of tables. There's a new version below that uses a Lua
string-indexed table to be consistent with the values returned by the other functions.

  data should be a array of tables with the following format:
    {
      key = "somekey",
      value = "somevalueasastring"
    }
--]]
local function createAttributeTableFromArray(parent, data)
  local propCount = #data * 2

  -- Check the data is present and has no duplicate keys
  local keys = {}
  local valid = true
  for rowIdx,dataRow in ipairs(data) do
    local rowKey, rowValue = dataRow.key,dataRow.value
    if rowKey and rowValue then
      if keys[rowKey] then
        print(string.format("Duplicate key on row %d: %s",rowIdx,dataRow.key))
        valid = false
      else
        keys[rowKey] = true
      end
    else
      print(string.format("Invalid data entry at index %d, must have 'key' and 'value'",rowIdx))
      valid = false
    end
  end

  if valid == false then return end
  
  -- Create the node itself with the utility
  local newNode = createAttributeTableNode(parent, propCount)
  
  -- After creation of the table set the values
  for rowIdx,dataRow in ipairs(data) do
    -- Get the index for the key and value property corresponding to this row index
    local keyIndex = (rowIdx-1)*2
    local valueIndex = keyIndex+1
    -- Set the key
    vrNodeSetValue(newNode, "P" .. keyIndex, tostring(dataRow.key))
    -- And the value
    vrNodeSetValue(newNode, "P" .. valueIndex, tostring(dataRow.value))
  end

  return newNode
end

--[[ Put some data in an attribute table node

Updated version which uses a hash table input directly in line with the format returned by the
getAllAttributes accessor utility function.

  data should be a simple key-value pair table:
    {
      somekey = "somevalueasastring"
    }
    
If the values aren't strings they'll be converted with tostring, this may not give the results you
expect especially if they're VisRen nodes!
--]]
local function createAttributeTable(parent, data)

  -- Put all the data in a number-indexed array in the order key, value, key, value etc.
  local data_arr = {}
  local n=0

  for k,v in pairs(data) do
    n=n+1
    data_arr[n] = k
    n=n+1
    data_arr[n] = v
  end
  
  local propCount = #data_arr
  
  -- Create the node itself with the utility
  local newNode = createAttributeTableNode(parent, propCount)
  
  -- After creation of the table set the values
  for i,v in ipairs(data_arr) do
    vrNodeSetValue(newNode, "P" .. i-1, tostring(v))
  end

  return newNode
end

--[[ Return a function which iterates over the key-value pairs of an attribute table
Usage:

for k,v in getAttributeIterator(some_attribute_table_node) do
  print(k,v)
end
--]]
local function getAttributeIterator(attTbl)
  -- Get the metanode for this attribute table
  local metaName = vrNodeGetMetaNode(attTbl)
  -- Find the number of keys / values based on property count (which should be an even integer)
  local propCount = vrMetaNodeGetPropertyCount(metaName)

  -- Each iteration covers two property indices
  -- The even numbered properties represent keys
  -- The odd numbered properties represent values
  -- Implicit assumption that attribute table metanodes have even numbers of properties.
  local i = -1
  return function ()
    i = i + 2

    if i >= propCount then return end

    local keyPropName = vrMetaNodeGetPropertyByIndex(metaName,i-1)
    local valuePropName = vrMetaNodeGetPropertyByIndex(metaName,i)
    local key = vrNodeGetValue(attTbl,keyPropName)
    local value = vrNodeGetValue(attTbl,valuePropName)

    return key,value
  end
end

-- Gets a single attribute safely from an attribute table. Returns nil if none exists.
local function getAttribute(attTbl,attKey)
  for k,v in getAttributeIterator(attTbl) do
    if k == attKey then return v end
  end
end

-- Returns a table of the attribute keys and values associated with a given AttributeTableP node
local function getAllAttributes(attTbl,attPrefix)
  attPrefix = attPrefix or ""
  local attributes = {}
  for k,v in getAttributeIterator(attTbl) do
    if attributes[attPrefix .. k] then
      print("Warning! Duplicate attribute table key",k)
    else
      attributes[attPrefix .. k] = v
    end
  end
  return attributes
end

-- define the plugin functions as local functions
local function name()
  return "Attribute Table Utilities Plugin"
end

local function version()
  return "1.0.0"
end

local function init()
  print(name(), "Initialised")
end

local function cleanup()
end

return {
  name = name,
  version = version,
  init = init,
  cleanup = cleanup,
  getAllAttributes = getAllAttributes,
  createAttributeTableFromArray = createAttributeTableFromArray,
  createAttributeTable = createAttributeTable,
  getAttributeIterator = getAttributeIterator,
  getAttribute = getAttribute
}