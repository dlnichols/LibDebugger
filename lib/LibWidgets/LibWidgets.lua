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

LibWidgets = LibStub:NewLibrary("LibWidgets-0.0", 1)

-- Already loaded
if not LibWidgets then return end

-- Load libraries
local LU = LibStub:GetLibrary("LibUtil-0.0")

local LastWindow
local BackdropCounter = 1

-------------
-- Helpers --
-------------

local function LibWidgets_ExtendedObject(object)
  return object and object.extended
end

function LibWidgets_AddChild(container, object)
  if not container then return end
  if container.extended == nil then container.extended = { children = {} } end
  table.insert(container.extended.children, object)
end

function LibWidgets_GetLastChild(container)
  -- The API functions GetChild and GetNumChildren don't work properly
  -- unless you name everything...
  d("container: "..tostring(container))
  if not container or not container.extended then return end

  children = container.extended.children
  if not children then return end

  return children[#children]
end

----------------------------
-- Default Event Handlers --
----------------------------

-- DefaultClose
local function LibWidgets_DefaultClose(button)
  button:GetParent():SetHidden(true)
end

---------------------
-- TopLevel Window --
---------------------

function LibWidgets.TopLevelWindow(params)
  params = LU.DefaultParams(params, {
    name = nil,
    minWidth = 320,
    width = 640,
    maxWidth = 1280,
    minHeight = 240,
    height = 480,
    maxHeight = 960,
    windowPadding = 7,
    clamped = true,
    mouse = true,
    movable = true,
    hidden = false,
    resize = 0,
    topmost = true,
    backdrop = true,
    closeButton = true,
    closeFunction = LibWidgets_DefaultClose,
    title = nil,
    titleDivider = true
  })

  -- Basic window definition
  local window = WINDOW_MANAGER:CreateTopLevelWindow(params.name)
  window:SetDimensions(params.width, params.height)
  window:SetDimensionConstraints(params.minWidth, params.minHeight, params.maxWidth, params.maxHeight)
  window:SetAnchor(CENTER, GuiRoot, CENTER)
  window:SetClampedToScreen(params.clamped)
  window:SetMouseEnabled(params.mouse)
  window:SetMovable(params.movable)
  window:SetHidden(params.hidden)
  window:SetAllowBringToTop(true)
  window:SetTopmost(params.topmost)
  window:SetResizeHandleSize(params.resize)

  -- Create extended object
  window.extended = {
    LIB_WIDGETS_EXTENDED = true,
    children = {}
  }

  -- We have to name the backdrop or we get a naming error because of the way
  -- it is defined (not something we can change)...
  if params.backdrop then
  --  local backdrop = WINDOW_MANAGER:CreateControlFromVirtual("_BACKDROP_"..BackdropCounter, window, "ZO_DefaultBackdrop")
  --  BackdropCounter = BackdropCounter + 1
    local backdrop = window:CreateControl(nil, CT_BACKDROP)
    backdrop:SetAnchorFill(window)
    backdrop:SetCenterTexture("hCraftingAssistant/textures/backdrop.dds", 256)
    backdrop:SetEdgeTexture("hCraftingAssistant/textures/edge.dds", 256, 256, 4, 0)
    LibWidgets_AddChild(window, backdrop)
  end

  local containerAnchor = nil

  if not LU.IsBlank(params.title) then
    local title = window:CreateControl(nil, CT_LABEL)
    title:SetAnchor(TOPLEFT, window, TOPLEFT, params.windowPadding, params.windowPadding)
    title:SetAnchor(TOPRIGHT, window, TOPRIGHT, -1 * params.windowPadding, params.windowPadding)
    title:SetFont("ZoFontWindowTitle")
    title:SetText(params.title)
    LibWidgets_AddChild(window, title)
    containerAnchor = title

    if params.titleDivider then
      local bar = window:CreateControl(nil, CT_TEXTURE)
      bar:SetDimensions(window:GetWidth(), 3)
      bar:SetAnchor(TOPLEFT, title, BOTTOMLEFT, 0, 0)
      bar:SetAnchor(TOPRIGHT, title, BOTTOMRIGHT, 0, 0)
      bar:SetTexture("/esoui/art/quest/questjournal_divider.dds")
      --"/esoui/art/miscellaneous/centerscreen_topDivider.dds"
      LibWidgets_AddChild(window, bar)
      containerAnchor = bar
    end
  end

  -- Close button
  if params.closeButton then
    local button = WINDOW_MANAGER:CreateControlFromVirtual(nil, window, "ZO_CloseButton")
    button:SetDimensions(16, 16)
    button:SetAnchor(TOPRIGHT, window, TOPRIGHT, -1 * params.windowPadding, params.windowPadding)
    button:SetHandler("OnClicked", params.closeFunction)
    LibWidgets_AddChild(window, button)
  end

  -- Main container (fills the window initially)
  local container = window:CreateControl(nil, CT_CONTROL)
  local anchor, aPoint, paddingTop, paddingLeft, paddingRight, paddingBottom
  if containerAnchor then
    anchor = containerAnchor
    aPoint = BOTTOMLEFT
    paddingTop = 20
    paddingLeft = 0
  else
    anchor = window
    aPoint = TOPLEFT
    paddingTop = params.windowPadding
    paddingLeft = params.windowPadding
  end
  container:SetAnchor(TOPLEFT, anchor, aPoint, paddingLeft, paddingTop)
  container:SetAnchor(BOTTOMRIGHT, window, BOTTOMRIGHT, -1 * params.windowPadding, -1 * params.windowPadding)
  LibWidgets_AddChild(window, container)

  -- Store the last window so further calls to this library add UI
  -- components to this window by default
  LastWindow = window
  LastContainer = container

  return window, container
end

-------------
-- Widgets --
-------------

function LibWidgets.TextWithEditBox(params)
  params = LU.DefaultParams(params, {
    name = nil,
    parent = LastContainer,
    maxhistory = 1024,
    inputFunction = LU.Noop
  })

  local editbg = WINDOW_MANAGER:CreateControlFromVirtual(nil, params.parent, "ZO_EditBackdrop")
  editbg:SetHeight(28)
  editbg:SetAnchor(BOTTOMLEFT, params.parent, BOTTOMLEFT, 0, 0)
  editbg:SetAnchor(BOTTOMRIGHT, params.parent, BOTTOMRIGHT, 0, 0)
  LibWidgets_AddChild(params.parent, editbg)

  local edit = WINDOW_MANAGER:CreateControlFromVirtual(nil, editbg, "ZO_DefaultEditForBackdrop")
  -- TESO uses the OnEnter event when the user presses 'Enter'
  edit:SetHandler("OnEnter", params.inputFunction)
  LibWidgets_AddChild(params.parent, edit)

  local dbg = params.parent:CreateControl(nil, CT_TEXTBUFFER)
  dbg:SetAnchor(TOPLEFT, params.parent, TOPLEFT, 0, 0)
  dbg:SetAnchor(BOTTOMRIGHT, editbg, TOPRIGHT, 0, 0)
  dbg:SetMaxHistoryLines(params.maxhistory)
  dbg:SetFont("ZoFontEditChat")
  LibWidgets_AddChild(params.parent, dbg)

  return dbg, edit
end
