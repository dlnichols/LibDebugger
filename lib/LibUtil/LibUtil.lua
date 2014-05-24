-- Copyright (c) 2014 Dan Nichols <dan@thenicholsrealm.com>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
-- the Software, and to permit persons to whom the Software is furnished to do so,
-- subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
-- FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
-- COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
-- IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
-- CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

LibUtil = LibStub:NewLibrary("LibUtil-0.0", 1)

-- Already loaded
if not LibUtil then return end

-------------------
-- Type checking --
-------------------
function LibUtil.IsNumber(value)
  return type(value) == "number"
end

function LibUtil.IsTable(value)
  return type(value) == "table"
end

function LibUtil.IsString(value)
  return type(value) == "string"
end

--------------------
-- Value checking --
--------------------
function LibUtil.IsBlank(value)
  return (value == nil) or (value == "")
end

---------------
-- Functions --
---------------
function LibUtil:Noop()
  d("Noop")
end

function LibUtil.DefaultParams(params, defaults)
  -- No params, just return defaults
  if not LibUtil.IsTable(params) then return defaults end

  -- Given params, set the metatable so that defaults are
  -- returned for any params without values
  setmetatable(params, {__index = defaults})
  return params
end
