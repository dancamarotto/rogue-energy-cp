local _, ns = ...

local LEM = LibStub("LibEditMode")
local frame = ns.frame
local inEditMode

function ns.GetPosition()
    local layoutName = LEM:GetActiveLayoutName()
    return (layoutName and ns.db.layouts[layoutName]) or { point = "CENTER", x = 0, y = 0 }
end

function ns.ApplyPosition()
    local pos = ns.GetPosition()
    frame:ClearAllPoints()
    frame:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
end

function ns.SavePosition(point, x, y)
    local layoutName = LEM:GetActiveLayoutName()
    if not layoutName then return end
    local pos = ns.db.layouts[layoutName]
    if not pos then
        pos = {}
        ns.db.layouts[layoutName] = pos
    end
    pos.point, pos.x, pos.y = point, x, y
end

function ns.IsInEditMode()
    return inEditMode
end

function ns.SetupEditMode()
    ns.ApplyPosition()

    -- callbacks first: AddFrame may fire "layout" right away
    LEM:RegisterCallback("enter", function()
        inEditMode = true
        frame:Show()
    end)
    LEM:RegisterCallback("exit", function()
        inEditMode = nil
        frame:Hide() -- visibility rules arrive with the energy bar
    end)
    LEM:RegisterCallback("layout", function()
        ns.ApplyPosition()
    end)
    LEM:RegisterCallback("create", function(layoutName, _, sourceLayoutName)
        local layouts = ns.db.layouts
        local source = sourceLayoutName and layouts[sourceLayoutName]
        if source and not layouts[layoutName] then
            layouts[layoutName] = CopyTable(source)
        end
        ns.ApplyPosition() -- the game may already have switched to it
    end)
    LEM:RegisterCallback("rename", function(oldName, newName)
        local layouts = ns.db.layouts
        if layouts[oldName] and not layouts[newName] then
            layouts[newName] = layouts[oldName]
        end
        layouts[oldName] = nil
    end)
    LEM:RegisterCallback("delete", function(layoutName)
        ns.db.layouts[layoutName] = nil
    end)

    LEM:AddFrame(frame, function(_, _, point, x, y)
        ns.SavePosition(point, x, y)
    end, { point = "CENTER", x = 0, y = 0 }, "Rogue Energy CP")
end
