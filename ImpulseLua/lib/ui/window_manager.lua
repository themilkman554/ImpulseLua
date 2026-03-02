--[[
    Impulse Lua - Window Manager
    Manages all floating UI windows
    Port of windowManager.cpp from Impulse C++
]]

local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local UIWindow = require("Impulse/ImpulseLua/lib/ui/window")
local ScreenPanel = require("Impulse/ImpulseLua/lib/ui/screen_panel")

-- Components (lazy loaded to avoid circular deps)
local UILoggerComponent = nil
local UISystemDataComponent = nil
local UIVehicleComponent = nil
local UIHotkeysComponent = nil

local WindowManager = {}
WindowManager.__index = WindowManager

-- Singleton instance
local instance = nil

--- Get singleton instance
---@return WindowManager
function WindowManager.GetInstance()
    if not instance then
        instance = setmetatable({}, WindowManager)
        instance:Init()
    end
    return instance
end

--- Initialize the window manager
function WindowManager:Init()
    self.windows = {}
    self.focusedWindow = nil
    
    self.menuInputDisabled = false
    self.gtaInputDisabled = false
    
    -- Mouse state
    self.lastMouseX = 0
    self.lastMouseY = 0
    
    -- Pre-built windows
    self.logWindow = nil
    self.systemDataWindow = nil
    self.vehicleInfoWindow = nil
    self.chatWindow = nil
    
    -- First open flag for instructional
    self.firstOpen = true
    
    -- Initialize panel buttons
    self:InitScreenPanel()
    
    -- Create pre-built windows
    self:CreateBuiltInWindows()
end

--- Initialize screen panel buttons
function WindowManager:InitScreenPanel()
    local panel = ScreenPanel.GetInstance()
    panel:Clear()
    
    panel:AddButton("Chat", true, function()
        if self.chatWindow then self:AddWindow(self.chatWindow) end
    end)

    panel:AddButton("Log", true, function()
        self:ShowLogWindow()
    end)
    
    panel:AddButton("System data", true, function()
        self:ShowSystemDataWindow()
    end)
    
    panel:AddButton("Profiler", true, function()
        if self.profilerWindow then self:AddWindow(self.profilerWindow) end
    end)
    
    panel:AddButton("Hotkeys", true, function()
        self:ShowHotkeysWindow()
    end)
end

--- Create built-in windows
function WindowManager:CreateBuiltInWindows()
    -- Lazy load components
    if not UILoggerComponent then
        UILoggerComponent = require("Impulse/ImpulseLua/lib/ui/components/logger")
    end
    if not UISystemDataComponent then
        UISystemDataComponent = require("Impulse/ImpulseLua/lib/ui/components/system_data")
    end
    if not UIVehicleComponent then
        UIVehicleComponent = require("Impulse/ImpulseLua/lib/ui/components/vehicle_info")
    end
    
    -- Chat window (Stub)
    self.chatWindow = UIWindow.new("Chat", true, 0.6, 0.5, 0.3, 0.3)
    -- local chatComp = UITextBoxComponent.new(...) -- TODO
    -- self.chatWindow:AddComponent(chatComp)
    
    -- System data window
    self.systemDataWindow = UIWindow.new("System data", true, 0.6, 0.5, 0.15, 0.2)
    local sysComp = UISystemDataComponent.new()
    self.systemDataWindow:AddComponent(sysComp)

    -- Log window
    self.logWindow = UIWindow.new("Log", true, 0.6, 0.6, 0.2, 0.25)
    local logComp = UILoggerComponent.new(12)
    self.logWindow:AddComponent(logComp)
    self.logComponent = logComp
    
    -- Profiler window (Stub)
    self.profilerWindow = UIWindow.new("Profiler", true, 0.6, 0.6, 0.2, 0.2)
    -- self.profilerWindow:AddComponent(...)
    
    -- Developer Log (Stub)
    self.devLogWindow = UIWindow.new("Developer log", false, 0.6, 0.6, 0.3, 0.25)
    -- self.devLogWindow:AddComponent(...)
    
    -- Vehicle info window (Floating, not in panel)
    -- Vehicle Info Window (Single button style: canClose=false -> Minimize only)
    self.vehicleInfoWindow = UIWindow.new("", false, 0.85, 0.6, 0.17, 0.25)
    local vehicleInfo = UIVehicleComponent.new()
    self.vehicleInfoWindow:AddComponent(vehicleInfo)
    -- TODO: Add logic to show this automatically when inside vehicle submenus
    
    -- Hotkeys window
    if not UIHotkeysComponent then
        UIHotkeysComponent = require("Impulse/ImpulseLua/lib/ui/components/hotkeys")
    end
    self.hotkeysWindow = UIWindow.new("Hotkeys", true, 0.4, 0.2, 0.2, 0.25)
    local hotkeysComp = UIHotkeysComponent.new()
    self.hotkeysWindow:AddComponent(hotkeysComp)
end

--- Show log window
function WindowManager:ShowLogWindow()
    if self.logWindow then
        self:AddWindow(self.logWindow)
    end
end

--- Show system data window
function WindowManager:ShowSystemDataWindow()
    if self.systemDataWindow then
        self:AddWindow(self.systemDataWindow)
    end
end

--- Show vehicle info window
function WindowManager:ShowVehicleInfoWindow()
    -- No longer called from button
    if self.vehicleInfoWindow then
        self:AddWindow(self.vehicleInfoWindow)
    end
end

--- Show hotkeys window
function WindowManager:ShowHotkeysWindow()
    if self.hotkeysWindow then
        self:AddWindow(self.hotkeysWindow)
    end
end

--- Log a message to the log window
---@param text string Message text
---@param color table|nil Optional color
function WindowManager:Log(text, color)
    if self.logComponent then
        self.logComponent:AddLine(text, color)
    end
end

--- Add a window to the manager
---@param window UIWindow
function WindowManager:AddWindow(window)
    -- Remove if already exists (physically remove from list to avoid duplicates)
    for i, w in ipairs(self.windows) do
        if w == window then
            table.remove(self.windows, i)
            break
        end
    end
    -- Also trigger removal logic just in case (e.g. if it had other cleanup)
    -- self:RemoveWindow(window) -- Removed this call as it triggers Close/Fade which we don't want when re-adding immediately
    
    table.insert(self.windows, window)
    window:Show()
    self.focusedWindow = window
end

--- Remove a window from the manager
---@param window UIWindow
function WindowManager:RemoveWindow(window)
    for i, w in ipairs(self.windows) do
        if w == window then
            table.remove(self.windows, i)
            if self.focusedWindow == window then
                self.focusedWindow = self.windows[#self.windows]
            end
            return
        end
    end
end

--- Bring window to front
---@param window UIWindow
function WindowManager:BringToFront(window)
    self:RemoveWindow(window)
    table.insert(self.windows, window)
    self.focusedWindow = window
end

--- Close all closeable windows
function WindowManager:CloseAllWindows()
    local count = 0
    for i = #self.windows, 1, -1 do
        local window = self.windows[i]
        if window.canBeClosed then
            table.remove(self.windows, i)
            count = count + 1
        end
    end
    return count
end

--- Disable all input this frame
function WindowManager:DisableAllInputThisFrame()
    self.gtaInputDisabled = true
    self.menuInputDisabled = true
end

--- Get mouse position (normalized 0-1)
---@return number, number
function WindowManager:GetMousePosition()
    local mouseX, mouseY = ImGui.GetMousePos()
    local screenW, screenH = ImGui.GetDisplaySize()
    return mouseX / screenW, mouseY / screenH
end

local Mouse = require("Impulse/ImpulseLua/lib/mouse")
local Settings = require("Impulse/ImpulseLua/lib/settings")
local Menu = require("Impulse/ImpulseLua/lib/menu")

-- ... (After imports)

--- Update all windows
function WindowManager:Update()
    -- Update mouse state at start of frame
    Mouse.Update()
    
    -- Check if either Cherax GUI or Impulse Menu is open
    if not GUI.IsOpen() and not Menu.isOpen then return end

    -- Handle input disabling
    if self.gtaInputDisabled then
        PAD.DISABLE_ALL_CONTROL_ACTIONS(0)
        self.gtaInputDisabled = false
    end
    self.menuInputDisabled = false
    
    -- Always get mouse state for windows/panels
    local mouseX, mouseY = Mouse.X, Mouse.Y
    local leftClick = Mouse.ButtonJustDown(Mouse.LEFT_BUTTON)
    local leftHeld = Mouse.ButtonDown(Mouse.LEFT_BUTTON)
    
    -- Update screen panel
    ScreenPanel.GetInstance():Update(mouseX, mouseY)
    
    -- Handle panel clicks
    if leftClick then
        if ScreenPanel.GetInstance():HandleClick(mouseX, mouseY) then
            return -- Consumed by panel
        end
    end
    
    self.lastMouseX = mouseX
    self.lastMouseY = mouseY

    -- Update windows in reverse order (top to bottom for input)
    for i = #self.windows, 1, -1 do
        local window = self.windows[i]
        window:Update()
        
        -- Remove windows that finished fading out
        if not window.visible and not window.isFading and window.opacity <= 0 then
            table.remove(self.windows, i)
            if self.focusedWindow == window then
                self.focusedWindow = self.windows[#self.windows]
            end
        end
    end
    
    -- Handle input for windows (reverse order - top windows first)
    local inputConsumed = false
    for i = #self.windows, 1, -1 do
        local window = self.windows[i]
        if window.visible then
            local consumed = window:HandleInput(mouseX, mouseY, leftClick and not inputConsumed, leftHeld)
            if consumed then
                inputConsumed = true
                if leftClick and window ~= self.focusedWindow then
                    self:BringToFront(window)
                end
                break
            end
        end
    end
end

--- Render all windows
function WindowManager:Render()
    -- Render screen panel
    ScreenPanel.GetInstance():Render()
    
    -- Render windows in order (bottom to top)
    for _, window in ipairs(self.windows) do
        window:Render()
    end
end

--- Create and show a simple info window
---@param title string Window title
---@param x number X position
---@param y number Y position
---@param w number Width
---@param h number Height
---@return UIWindow
function WindowManager:CreateWindow(title, x, y, w, h)
    local window = UIWindow.new(title, true, x, y, w, h)
    self:AddWindow(window)
    return window
end

return WindowManager
