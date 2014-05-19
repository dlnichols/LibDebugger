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

LibDebugger = LibStub:NewLibrary("LibDebugger-0.0", 1)

-- Already loaded
if not LibDebugger then return end

-- Grab the utility libs
local LU      = LibStub:GetLibrary("LibUtil-0.0")
local Widgets = LibStub:GetLibrary("LibWidgets-0.0")

---------------
-- Variables --
---------------

LibDebugger._VERSION = "LibDebugger-0.0.1"

LIB_DEBUGGER_INFO   = 1
LIB_DEBUGGER_NOTICE = 4
LIB_DEBUGGER_WARN   = 7
LIB_DEBUGGER_ERROR  = 10
LIB_DEBUGGER_DEBUG  = 11

LibDebugger.ErrorColors = {
  [LIB_DEBUGGER_INFO]   = { r = 1, g = 1, b = 1 },
  [LIB_DEBUGGER_NOTICE] = { r = 0, g = 1, b = 0 },
  [LIB_DEBUGGER_WARN]   = { r = 1, g = 1, b = 0 },
  [LIB_DEBUGGER_ERROR]  = { r = 1, g = 0, b = 0 },
  Default = { r = 1, g = 1, b = 1 }
}

LibDebugger.ErrorTypes = {
  [LIB_DEBUGGER_INFO]   = "[Info] ",
  [LIB_DEBUGGER_NOTICE] = "[Notice] ",
  [LIB_DEBUGGER_WARN]   = "[Warn] ",
  [LIB_DEBUGGER_ERROR]  = "[Error] ",
  [LIB_DEBUGGER_DEBUG]  = "",
  Default = "[Message] "
}

-- Library data
LibDebugger.Prebuffer = {
  messages = {},
  AddMessage = function(self, msg, level)
    table.insert(self.messages, {msg, level})
  end,
  Process = function(self, buffer)
    if LU.IsBlank(buffer) then return end
    for k, v in ipairs(self.messages) do
      buffer:AddMessage(unpack(v))
    end
    self.messages = {}
  end
}
LibDebugger.Buffer = LibDebugger.Prebuffer
LibDebugger.Window = nil
LibDebugger.LogLevel = LIB_DEBUGGER_INFO
LibDebugger._partial = ''

-- Add a message to the debug buffer
function LibDebugger:AddMessage(msg, level)
  -- No message, return
  if not msg then return end

  -- Default to Info
  if not level or not LU.IsNumber(level) then
    level = LIB_DEBUGGER_INFO
  end

  if level >= self.LogLevel then
    prepend = self.ErrorTypes[level] or self.ErrorTypes.Default
    color = self.ErrorColors[level] or self.ErrorColors.Default
    self.Buffer:AddMessage(prepend..msg, color.r, color.g, color.b)
  end
end

----------
-- REPL --
----------
function LibDebugger:Name()
  return "REPL"
end

function LibDebugger:CompileChunk(chunk)
  return zo_loadstring(chunk, self:Name())
end

function LibDebugger:GetContext()
 return _G
end

function LibDebugger:GatherResults(success, ...)
  return success, { ... }
end

function LibDebugger:DisplayResults(results)
  --if LU.IsBlank(results) then return end
  self:AddMessage("Results: "..#results.." ", LIB_DEBUGGER_DEBUG)
  for i = 1, #results do
    self:AddMessage("Result["..tostring(i).."]: "..tostring(results[i]), LIB_DEBUGGER_DEBUG)
  end
end

function LibDebugger:TestFunc()
  return "a", "b", "c"
end

function LibDebugger:DetectContinue(err)
  return string.match(err, "'<eof>'$")
end

function LibDebugger:Traceback(err, something)
end

function LibDebugger:Clear()
  self._partial = ''
end

--local REPLCommandLookup = {
--  "=" = ,
--  "=clear" = LibDebugger.Clear
--}

function LibDebugger:HandleLine(line)
  -- Nothing to do if there is no line
  if LU.IsBlank(line) then return end

  self:AddMessage(">> "..line, LIB_DEBUGGER_DEBUG)

  -- Build chunk from partial and new line
  local chunk = self._partial .. line
  local f, err = self:CompileChunk(chunk)

  if f then
    -- Compiled chunk, reset partial
    self._partial = ''

    -- Set the env and call the function
    setfenv(f, self:GetContext())
    local success, results = self:GatherResults(pcall(f))

    -- Display results
    if success then
      self:DisplayResults(results)
    else
      self:AddMessage("Error: "..results[1], LIB_DEBUGGER_DEBUG)
    end
  else
    if self:DetectContinue(err) then
      self._partial = chunk .. '\n'
      return 2
    else
      --self:AddMessage("Invalid expression: "..line, LIB_DEBUGGER_DEBUG)
      self:AddMessage("Error: "..err, LIB_DEBUGGER_DEBUG)
    end
  end

  return 1
end

---------------
-- GUI Setup --
---------------

-- Show the debug window
local function LibDebugger_ShowWindow()
  if (LibDebugger.Window == nil) then return end

  SetGameCameraUIMode(true)
  LibDebugger.Window:SetHidden(false)
  LibDebugger.Input:TakeFocus()
end

-- Hide the debug window
local function LibDebugger_HideWindow()
  if (LibDebugger.Window == nil) then return end

  LibDebugger.Window:SetHidden(true)
end

-- Toggle the debug window
local function LibDebugger_ToggleWindow()
  if (LibDebugger.Window == nil) then return end

  local hidden = LibDebugger.Window:IsHidden()
  LibDebugger.Window:SetHidden(not hidden)
  if hidden then SetGameCameraUIMode(true) end
end

-- Create the debug window
local function LibDebugger_CreateGUI()
  if (LibDebugger.Window) then return end

  LibDebugger:AddMessage("LUA Version: ".._VERSION)
  LibDebugger:AddMessage("Debugger Version: "..LibDebugger._VERSION)

  -- Base window
  LibDebugger.Window = Widgets.TopLevelWindow({
    hidden = true,
    resize = 8,
    title = "Debugger"
  })
  LibDebugger.Buffer, LibDebugger.Input = Widgets.TextWithEditBox({
    inputFunction = function(control)
      local line = control:GetText()
      if LU.IsBlank(line) then return end
      LibDebugger:HandleLine(line)
      control:Clear()
      control:TakeFocus()
    end
  })
  LibDebugger.Prebuffer:Process(LibDebugger.Buffer)
end

---------------
-- CLI Setup --
---------------

-- PrintDebugHelp
local function LibDebugger_PrintDebugHelp(arg)
  d("Invalid argument '"..tostring(arg).."' for /debug.  Appropriate arguments are:\n"..
    "_ show - to show the window\n"..
    "_ hide - to hide the debug window\n"..
    "_ toggle - to toggle the window")
end

-- Translate /debug arguments into functions
local DebugCommandLookup = {
  show   = LibDebugger_ShowWindow,
  hide   = LibDebugger_HideWindow,
  toggle = LibDebugger_ToggleWindow
}

-- Lookup the appropriate debug function and run it
local function LibDebugger_DebugCommand(arg)
  if LU.IsBlank(arg) then arg = "show" end
  local func = DebugCommandLookup[arg] or LibDebugger_PrintDebugHelp
  func(arg)
end

local function LibDebugger_ProcessPrebuffer()
  LibDebugger.Prebuffer:Process(LibDebugger.Buffer)
end

local function LibDebugger_PrebufferWriteLn(msg)
  LibDebugger.Prebuffer:AddMessage(msg, 1)
end

-- Translate /pre arguments into functions
local PreCommandLookup = {
  process = LibDebugger_ProcessPrebuffer
}

-- Handle the /pre command
local function LibDebugger_PreCommand(arg)
  local func = PreCommandLookup[arg] or LibDebugger_PrebufferWriteLn
  func(arg)
end

-- Handle the /writeln command
local function LibDebugger_WriteLnCommand(msg)
  LibDebugger:AddMessage(msg)
end

-- Add our slash commands
local function LibDebugger_CreateCLI()
  SLASH_COMMANDS["/debug"] = LibDebugger_DebugCommand
  SLASH_COMMANDS["/writeln"] = LibDebugger_WriteLnCommand
  SLASH_COMMANDS["/pre"] = LibDebugger_PreCommand
end

----------
-- Main --
----------

local function LibDebug_Initialize()
  LibDebugger_CreateCLI()
  LibDebugger_CreateGUI()
end

LibDebug_Initialize()
