--[[
    Impulse Lua - Feature State Library
    Helper functions for interacting with FeatureMgr
]]

local FeatureState = {}

--- Helper to safely get feature toggle state
---@param featureName string
---@param playerId? number Optional player ID
---@return boolean
function FeatureState.Get(featureName, playerId)
    local success, result = pcall(function()
        local feature
        if playerId then
            feature = FeatureMgr.GetFeatureByName(featureName, playerId)
        else
            feature = FeatureMgr.GetFeatureByName(featureName)
        end
        
        if feature then
            return feature:IsToggled()
        end
        return false
    end)
    return success and result or false
end

--- Trigger a feature callback safely
---@param featureName string
---@param playerId? number Optional player ID
---@return boolean
function FeatureState.Trigger(featureName, playerId)
    local success, result = pcall(function()
        local feature
        if playerId then
            feature = FeatureMgr.GetFeatureByName(featureName, playerId)
        else
            feature = FeatureMgr.GetFeatureByName(featureName)
        end
        
        if feature then
            feature:TriggerCallback()
            return true
        end
        return false
    end)
    return success and result or false
end

--- Set feature toggle state safely
---@param featureName string
---@param state boolean
---@param playerId? number Optional player ID
---@return boolean
function FeatureState.Toggle(featureName, state, playerId)
    local success, result = pcall(function()
        local feature
        if playerId then
            feature = FeatureMgr.GetFeatureByName(featureName, playerId)
        else
            feature = FeatureMgr.GetFeatureByName(featureName)
        end
        
        if feature then
             -- Use the boolean state
             feature:Toggle(state)
             return true
        end
        return false
    end)
    return success and result or false
end

--- Set feature toggle state safely (deferred via Script.QueueJob)
---@param featureName string
---@param state boolean
---@param playerId? number Optional player ID
function FeatureState.ToggleDeferred(featureName, state, playerId)
    -- QueueJob arguments: function, ...args
    Script.QueueJob(function(featureName, state, playerId)
        local success, result = pcall(function()
            local feature
            if playerId then
                feature = FeatureMgr.GetFeatureByName(featureName, playerId)
            else
                feature = FeatureMgr.GetFeatureByName(featureName)
            end
            
            if feature then
                 -- Check state again inside job just in case
                 -- or force sync. The user issue is likely the Toggle call itself.
                 -- Let's just do toggle to match state.
                 if feature:IsToggled() ~= state then
                     feature:Toggle()
                 end
            end
        end)
    end, featureName, state, playerId)
end



return FeatureState
