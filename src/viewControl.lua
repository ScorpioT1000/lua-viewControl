if(_G["WM"] == nil) then WM = (function(m,h) h(nil,(function() end), (function(e) _G[m] = e end)) end) end -- WLPM MM fallback

-- Warcraft 3 viewControl module by ScorpioT1000 / 2020
-- Thanks to NazarPunk for common.j.lua
-- Manipulates camera using mouse
-- Fires "view.control" event
WM("viewControl", function(import, export, exportDefault)
  local eventDispatcher = (_G["eventDispatcher"] == nil) and import("eventDispatcher") or eventDispatcher
  local wGeometry = (_G["wGeometry"] == nil) and import("wGeometry") or wGeometry
  local Vector3 = wGeometry.Vector3
  local Camera = wGeometry.Camera
  local updatePeriod = nil
  

  viewControlUpdateTrigger = CreateTrigger()
  viewControlInitTrigger = CreateTrigger()
  viewControlMouseMoveTriggers = {}
  viewControlMouseDownTriggers = {}
  viewControlMouseUpTriggers = {}
  viewControlKeyTriggers = {}
  
  local defaultSettings = {
    -- Activate view control when holding left mouse button
    activateOnMouseLeftButton = true,
    -- Activate view control when holding right mouse button
    activateOnMouseRightButton = true,
    -- Activate view control when mouse buttons released
    activateOnMouseButtonsReleased = false,
    -- Deactivate view control when holding ALT key (or OPTION key for Mac OS)
    deactivateOnAltKey = false,
    -- Deactivate view control when holding CTRL key (or COMMAND key for Mac OS)
    deactivateOnCtrlKey = false,
    -- Control left-right rotation (yaw) from "inputMovement" library LEFT/RIGHT event
    useInputMovementLeftRight = true
  }
  
  local enabledStates = {} -- enabled/disabled system per player
  local activeStates = {} -- active/inactive movement per player
  local settings = {} -- per player
  local keyStates = {} -- {"mouseLeft"=false,"mouseRight"=false,"alt"=false,"ctrl"=false} per player
  
  local states = {} -- target vectors, per player
  local cameras = {} -- wGeometry Camera, per player
  
  -- ========== SETTINGS & ACTIVE STATES ==========
  
  --- @param pl Player
  --- @param activate boolean
  local activateForPlayer = function(pl, activate)
    if(not enabledStates[pl]) then
      return
    end
    activeStates[pl] = false
    if(not activate) then
      states[pl] = Vector3:new()
    end
  end
  
  -- checks settings and keys and switches the state
  local updateActiveStateForPlayer = function(pl)
    local setting = settings[pl]
    local keyState = keyStates[pl]
    
    local active = true
    
    if(setting.activateOnMouseLeftButton) then
      active = keyState.mouseLeft
    end
    if(setting.activateOnMouseRightButton) then
      active = active or keyState.mouseRight
    end
    if(setting.activateOnMouseButtonsReleased) then
      active = not (keyState.mouseLeft or keyState.mouseRight)
    end
    if(setting.deactivateOnAltKey) then
      active = active and (not keyState.alt)
    end
    if(setting.deactivateOnCtrlKey) then
      active = active and (not keyState.ctrl)
    end
    print("viewControl active:", active)
    
    activateForPlayer(pl, active)
  end
  
  local setSettingsForPlayer = function(pl, newSettings)
    if(settings[pl] == nil) then
      settings[pl] = {}
    end
    for k, v in pairs(newSettings) do 
      settings[pl][k] = v
    end
    updateActiveStateForPlayer(pl)
  end
  
  local setSettingsForAllPlayers = function(newSettings)
    ForForce(GetPlayersByMapControl(MAP_CONTROL_USER), function ()
      setSettingsForPlayer(GetEnumPlayer(), newSettings)
    end)
  end
  
  --- @param pl Player
  --- @param enable boolean
  local enableForPlayer = function(pl, enable)
    if(enable) then
      updateActiveStateForPlayer(pl)
    else
      activateForPlayer(pl, false)
    end
    enabledStates[pl] = enable
  end
  
  local onUserMouseDownEvent = function()
    local pl = GetTriggerPlayer()
    local btn = BlzGetTriggerPlayerMouseButton()
    if(GetLocalPlayer() == pl) then
      EnableUserControl(true)
    end
    if(btn == MOUSE_BUTTON_TYPE_LEFT) then
      keyStates[pl].mouseLeft = true
    elseif(btn == MOUSE_BUTTON_TYPE_RIGHT) then
      keyStates[pl].mouseRight = true
    end
    updateActiveStateForPlayer(pl)
  end
  
  local onUserMouseUpEvent = function()
    local pl = GetTriggerPlayer()
    local btn = BlzGetTriggerPlayerMouseButton()
    if(GetLocalPlayer() == pl) then
      EnableUserControl(true)
    end
    if(btn == MOUSE_BUTTON_TYPE_LEFT) then
      keyStates[pl].mouseLeft = false
    elseif(btn == MOUSE_BUTTON_TYPE_RIGHT) then
      keyStates[pl].mouseRight = false
    end
    updateActiveStateForPlayer(pl)
  end
  
  local onUserKeyEvent = function()
    local pl = GetTriggerPlayer()
    local key = BlzGetTriggerPlayerKey()
    local isDown = BlzGetTriggerPlayerIsKeyDown()
    if(key == OSKEY_LCONTROL) then
      if(keyStates[pl].ctrl == isDown) then
        return
      end
      keyStates[pl].ctrl = isDown
    elseif(key == OSKEY_LALT) then
      if(keyStates[pl].alt == isDown) then
        return
      end
      keyStates[pl].alt = isDown
    end
    updateActiveStateForPlayer(pl)
  end
  
  -- ========== MOVEMENT ==========
  
  local onUpdate = function()
  
  end
  
  local onUserMoveEvent = function()
    local pl = GetTriggerPlayer()
    local eventLocation = BlzGetTriggerPlayerMousePosition()
    local worldCoords = Vector3:copyFromLocation(eventLocation)
    removeLocation(eventLocation)
  end
  
  -- ========== REGISTRATION ==========
  
  -- Registers input for all active players when it's imported
  local registerForUserPlayers = function(newUpdatePeriod)
    updatePeriod = newUpdatePeriod
    
    ForForce(GetPlayersByMapControl(MAP_CONTROL_USER), function ()
      local id = #viewControlMouseMoveTriggers + 1
      local pl = GetEnumPlayer()
      
      keyStates[pl] = {
        mouseLeft = false,
        mouseRight = false,
        alt = false,
        ctrl = false
      }
      
      -- mouse move
      viewControlMouseMoveTriggers[id] = CreateTrigger()
      TriggerRegisterPlayerEvent(viewControlMouseMoveTriggers[id], pl, EVENT_PLAYER_MOUSE_MOVE)
      TriggerAddAction(viewControlMouseMoveTriggers[id], onUserMoveEvent)
      
      -- mouse up
      viewControlMouseDownTriggers[id] = CreateTrigger()
      TriggerRegisterPlayerEvent(viewControlMouseDownTriggers[id], pl, EVENT_PLAYER_MOUSE_DOWN)
      TriggerAddAction(viewControlMouseDownTriggers[id], onUserMouseDownEvent)    
      
      -- mouse down
      viewControlMouseUpTriggers[id] = CreateTrigger()
      TriggerRegisterPlayerEvent(viewControlMouseUpTriggers[id], pl, EVENT_PLAYER_MOUSE_UP)
      TriggerAddAction(viewControlMouseUpTriggers[id], onUserMouseUpEvent)     

      -- keyboard ctrl and alt
      viewControlKeyTriggers[id] = CreateTrigger()
      BlzTriggerRegisterPlayerKeyEvent(viewControlKeyTriggers[id], pl, OSKEY_LCONTROL, 0, true)
      BlzTriggerRegisterPlayerKeyEvent(viewControlKeyTriggers[id], pl, OSKEY_LCONTROL, 0, false)
      BlzTriggerRegisterPlayerKeyEvent(viewControlKeyTriggers[id], pl, OSKEY_LCONTROL, 2, true)
      BlzTriggerRegisterPlayerKeyEvent(viewControlKeyTriggers[id], pl, OSKEY_LCONTROL, 2, false)
      BlzTriggerRegisterPlayerKeyEvent(viewControlKeyTriggers[id], pl, OSKEY_LCONTROL, 4, true)
      BlzTriggerRegisterPlayerKeyEvent(viewControlKeyTriggers[id], pl, OSKEY_LCONTROL, 4, false)
      BlzTriggerRegisterPlayerKeyEvent(viewControlKeyTriggers[id], pl, OSKEY_LALT, 0, true)
      BlzTriggerRegisterPlayerKeyEvent(viewControlKeyTriggers[id], pl, OSKEY_LALT, 0, false)
      BlzTriggerRegisterPlayerKeyEvent(viewControlKeyTriggers[id], pl, OSKEY_LALT, 2, true)
      BlzTriggerRegisterPlayerKeyEvent(viewControlKeyTriggers[id], pl, OSKEY_LALT, 2, false)
      BlzTriggerRegisterPlayerKeyEvent(viewControlKeyTriggers[id], pl, OSKEY_LALT, 4, true)
      BlzTriggerRegisterPlayerKeyEvent(viewControlKeyTriggers[id], pl, OSKEY_LALT, 4, false)
      TriggerAddAction(viewControlKeyTriggers[id], onUserKeyEvent)    
      
      enableForPlayer(pl, true)
      
      cameras[pl] = Camera:new()
    end)
  end
  
  -- un-registers all events
  local unRegisterForUserPlayers = function()
    for i, trigger in ipairs(viewControlMouseMoveTriggers) do
      DestroyTrigger(trigger)
    end
    for i, trigger in ipairs(viewControlMouseDownTriggers) do
      DestroyTrigger(trigger)
    end
    for i, trigger in ipairs(viewControlMouseUpTriggers) do
      DestroyTrigger(trigger)
    end
    for i, trigger in ipairs(viewControlKeyTriggers) do
      DestroyTrigger(trigger)
    end
    viewControlMouseMoveTriggers = {}
    viewControlMouseDownTriggers = {}
    viewControlMouseUpTriggers = {}
    viewControlKeyTriggers = {}
    
    states = {}
    keyStates = {}
  end
  
  local reinitialize = function(newUpdatePeriod)
    unRegisterForUserPlayers()
    registerForUserPlayers(newUpdatePeriod)
  end
  
  
  TriggerRegisterTimerEventSingle(viewControlInitTrigger, 0.)
  TriggerAddAction(viewControlInitTrigger, function()
    setSettingsForAllPlayers(defaultSettings)
    registerForUserPlayers(0.02)
  end)
  
  TriggerRegisterTimerEventPeriodic(viewControlUpdateTrigger, 0.02)
  TriggerAddAction(viewControlUpdateTrigger, onUpdate)

  exportDefault({
    reinitialize = reinitialize,
    activateForPlayer = activateForPlayer,
    enableForPlayer = enableForPlayer,
    setSettingsForPlayer = setSettingsForPlayer,
    setSettingsForAllPlayers = setSettingsForAllPlayers
  })
end)