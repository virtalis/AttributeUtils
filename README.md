# Attribute Table Utilities Plugin

This Lua plugin provides some helpful utility functions for interacting with Visionary Render's attribute table nodes.

The underlying representation of attribute tables in Visionary Render introduces some complexity in using Lua to interact with them, including the following:
- Each size of attribute table is represented by a different metanode in Visionary Render
- Accessing an attribute table value without knowing its keys requires you to index the node properties directly
- All values in attribute tables are stored as strings

This plugin provides the following utility functions to abstract away some of this complexity:

- [getAttributeIterator](#getattributeiterator)
- [getAllAttributes](#getallattributes)
- [getAttribute](#getattribute)
- [createAttributeTable](#createattributetable)
- [createAttributeTableFromArray](#createattributetablefromarray)

It should be noted that all these functions impose an additional constraint that rows in the attribute table must have unique keys. This constraint isn't inherent to attribute tables but in order to provide a simpler interface it's recommended not to use duplicate keys. The functions in this plugin apply this constraint in the following ways:
- The [getter functions](#getter-functions) will return the value from the first row with the given key if duplicates exist.
- The [createAttributeTable](#createattributetable) function uses a Lua table so specifying duplicate keys is not possible.
- The [createAttributeTableFromArray](#createattributetablefromarray) function will print a warning and take no action if duplicate keys are provided.

## Getter functions

### getAttributeIterator

Usage:
```lua
AttributeUtils.getAttributeIterator(attTbl)
```
This function creates an iterator function which can be used like the `pairs` function to iterate over the key-value pairs in the attribute table  `attTbl`.

This can be used as follows. Given the attribute table:

| Key  | Value  |
|------|--------|
| key1 | value1 |
| key2 | value2 |

The code:
```lua
for k,v in AttributeUtils.getAttributeIterator(attTbl) do
	print("Key",k,"Value",v)
end
```
Outputs
```
Key	key1	Value	value1
Key	key2	Value	value2
```

This function is used by the getAllAttributes and getAttribute functions.

### getAllAttributes

Usage:
```lua
AttributeUtils.getAllAttributes(attTbl)

AttributeUtils.getAllAttributes(attTbl,attPrefix)
```

This function collects all the attributes from an attribute table `attTbl` and returns a Lua table with key-value pairs the same as the the attribute table.

As an example, the attribute table:

| Key  | Value  |
|------|--------|
| key1 | value1 |
| key2 | value2 |

Would be returned as the following table:
```lua
{
	key1 = "value1",
	key2 = "value2"
}
```

The optional argument `attPrefix` allows you to append a prefix to the keys in the returned table. This could be useful if you want to combine the contents of multiple attribute tables but want to avoid duplicate keys. For example given the table above and `attPrefix` of `"test"` the returned table would be:
```lua
{
	testkey1 = "value1",
	testkey2 = "value2"
}
```

Notes:
- All values are stored as strings, this function doesn't attempt to convert them.
- If the attribute table contains duplicate keys, the value in the *first* row for a given key is used.
- This will print warnings when duplicate keys are found.

### getAttribute

Usage:
```lua
AttributeUtils.getAttribute(attTbl,attKey)
```

This function gets the value corresponding to the attribute with the key `attKey` from the attribute table `attTbl`. If the attribute table doesn't contain a key with the given value this function returns `nil`.

As an example, given the attribute table `attTbl`:
| Key  | Value  |
|------|--------|
| key1 | value1 |
| key2 | value2 |

```lua
print(AttributeUtils.getAttribute(attTbl,"key1"))
```

Would output `value1`.

Notes:
- This function is equivalent to accessing the attribute table itself as if it were a Lua table e.g. `attTbl["key1"]`. However this function should be used where the key may not exist, as the `__index` override for attribute tables throws an error if the key isn't present.
- All values are stored as strings, this function doesn't attempt to convert them.
- If the attribute table contains duplicate keys, the value of the *first* row in the table which matches the given key is used.
- This function exits as soon as the key is found, so no warnings are issued about duplicates.

## Creation functions

The maximum number of rows in any single attribute table is 125, and both [createAttributeTable](#createattributetable) and [createAttributeTableFromArray](#createattributetablefromarray) will print a warning and not create the table if given more data than this.

However, the Visionary Render user interface automatically combines multiple attribute tables which are the child of the same node, so if you want to store and display more than 125 rows of data it's recommended to split your data into chunks of 125 rows or less, then use these functions to create an attribute table for each chunk.


### createAttributeTable

Usage:
```lua
AttributeUtils.createAttributeTable(parent,data)
```

This function creates an attribute table node under `parent` and populates it using the *table* `data`.

`data` should be a Lua table with key-value pairs corresponding to the keys and values to be used in the table.

For example, given the following value of `data`:
```lua
{
	key1 = "value1",
	key2 = "value2"
}
```

The following attribute table will be created:
| Key  | Value  |
|------|--------|
| key1 | value1 |
| key2 | value2 |

Notes:
- This function will create a new metanode if none exists for the attribute table of the size required to contain `data`
- This function will print a warning and fail to create the node if given more than 125 rows of data
- All keys and values in `data` will be converted to strings using `tostring`
- Because the input to this is consistent with the format returned by [getAllAttributes](#getallattributes) it's recommended to use this function instead of [createAttributeTableFromArray](#createattributetablefromarray)

### createAttributeTableFromArray

Usage:
```lua
AttributeUtils.createAttributeTableFromArray(parent,data)
```

This function creates an attribute table node under `parent` and populates it using the *array* `data`.

`data` should be a Lua array of tables, each of the tables in the array should contain a single key-value pair in the following format:
```lua
{
	key = "somekey",
	value = "somevalueasastring"
}
```

For example, given the following value of `data`:
```lua
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
```

The following attribute table will be created:
| Key  | Value  |
|------|--------|
| key1 | value1 |
| key2 | value2 |

Notes:
- This function will create a new metanode if none exists for the attribute table of the size required to contain `data`
- This function will print a warning and fail to create the node if the data is invalid in one of the following ways:
  - Contains more than 125 rows of data
  - Contains two rows with the same key
  - Contains a row which doesn't contain a key and a value
- All keys and values in `data` will be converted to strings using `tostring`