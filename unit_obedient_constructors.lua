--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
    return {
        name      = "Obedient constructors v5",
        desc      = "Cancel constructor's orders when it has a fight order and new order given",
        author    = "[teh]decay",
        date      = "5 oct 2013",
        license   = "GNU GPL, v2 or later",
        version   = 5,
        layer     = 5,
        enabled   = true --  loaded by default?
    }
end

-- project page on github: https://github.com/jamerlan/unit_obedient_constructors

--Changelog
-- v2 [teh]decay - fixed bug when only one constructor executes order
-- v3 [teh]decay - fix bug with queueing line of buildings after guard or fight order
-- v4 [teh]decay - fixed conflict with customformations widgets + fixed confirmation sounds + code speedup
-- v5 [teh]decay - updated for spring 98 engine (improved performance)

local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetMyTeamId = Spring.GetMyTeamID
local spGetTeamUnits = Spring.GetTeamUnits
local spGetUnitDefID = Spring.GetUnitDefID
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetCommandQueue = Spring.GetCommandQueue

local spFightCMD = CMD.FIGHT
local spGuardCMD = CMD.GUARD

local previouslySelectedUnits = {}

-------------------------------------------------------------------------------
function widget:CommandNotify(id, params, options)
    local units = spGetSelectedUnits()

-- Spring.Echo (id .. " " .. table.tostring(params) .. table.tostring(options))

    if #units < 1 then return false end

    local theSameUnits = true

    for i, unit_id in ipairs(units) do
        local unitExists = false
        for j, old_unit_id in ipairs(previouslySelectedUnits) do
            if unit_id == old_unit_id then
                unitExists = true
            end
        end

        if not unitExists or #units ~= #previouslySelectedUnits then
            theSameUnits = false
        end
    end

    local builderWithGuardFound = false;

    for i, unit_id in ipairs(units) do
--        Spring.Echo("cmds:" .. table.tostring(commands))
--        Spring.Echo("cmds size:" .. #commands)
--        Spring.Echo("id:" .. id)
--        Spring.Echo("params:" .. table.tostring(params))
--        Spring.Echo("options:" .. table.tostring(options))
--        Spring.Echo("")

        local unitDefID = spGetUnitDefID(unit_id)
        local ud = UnitDefs[unitDefID]
        if UnitDefs[unitDefID]["canReclaim"] and not ud.isFactory then
            local commands = spGetCommandQueue(unit_id, 100) -- looking for depth of 100 commands only. Should be enough
            for i, command in ipairs(commands) do
                if command.id == spFightCMD or command.id == spGuardCMD then
                    builderWithGuardFound = true
                end
            end
            break
        end
    end

    if not builderWithGuardFound then
        if id == spFightCMD or id == spGuardCMD then
            previouslySelectedUnits = {}
        end

        return false
    else
        for i, unit_id in ipairs(units) do
            local commands = spGetCommandQueue(unit_id, 100) -- looking for depth of 100 commands only. Should be enough

            local containsFightOrGuardOrder = false

            for i, command in ipairs(commands) do
                if command.id == spFightCMD or command.id == spGuardCMD then
                    containsFightOrGuardOrder = true
                end
            end

            local unitDefID = spGetUnitDefID(unit_id)
            local ud = UnitDefs[unitDefID]
            if containsFightOrGuardOrder and UnitDefs[unitDefID]["canReclaim"] and not ud.isFactory then
                builderWithGuardFound = true;

                if not theSameUnits then
                    options.shift = nil
                    previouslySelectedUnits = units
                end

                spGiveOrderToUnit(unit_id, id, params, options)
            else
                spGiveOrderToUnit(unit_id, id, params, options)
            end
        end

        if id == spFightCMD or id == spGuardCMD then
            previouslySelectedUnits = {}
        end

        return true
    end
end

function widget:PlayerChanged(playerID)
    local _, _, spec = Spring.GetPlayerInfo(Spring.GetMyPlayerID())
    if spec then
        widgetHandler:RemoveWidget()
        return false
    end
end

function widget:Initialize()
    local _, _, spec = Spring.GetPlayerInfo(Spring.GetMyPlayerID())

    if spec then
        widgetHandler:RemoveWidget()
        return false
    end

    return true
end

--------------------------------------------------------------------------------
--[[

function table.val_to_str ( v )
    if "string" == type( v ) then
        v = string.gsub( v, "\n", "\\n" )
        if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
            return "'" .. v .. "'"
        end
        return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
    else
        return "table" == type( v ) and table.tostring( v ) or
                tostring( v )
    end
end

function table.key_to_str ( k )
    if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
        return k
    else
        return "[" .. table.val_to_str( k ) .. "]"
    end
end

function table.tostring( tbl )
    local result, done = {}, {}
    for k, v in ipairs( tbl ) do
        table.insert( result, table.val_to_str( v ) )
        done[ k ] = true
    end
    for k, v in pairs( tbl ) do
        if not done[ k ] then
            table.insert( result,
                table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
        end
    end
    return "{" .. table.concat( result, "," ) .. "}"
end
]]

