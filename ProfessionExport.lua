local _, ProfessionExport = ...

local ProfexFrame = nil
local ProfexString = nil
local filter = {
        -- Player Info
        ["playerInfo"] = true,
        ["name"] = true,
        ["class"] = true,
        ["profession1"] = true,
        ["profession2"] = true,

        -- Recipe Info
        ["recipeID"] = true,
        ["recipeName"] = true,
        ["craftingDataID"] = false,

        -- Skill
        ["baseSkill"] = false,
        ["bonusSkill"] = false,
        ["upperSkillTreshold"] = false,
        ["lowerSkillThreshold"] = false,

        -- Difficulty
        ["baseDifficulty"] = false,
        ["bonusDifficulty"] = false,

        -- Rating
        ["ratingPct"] = false,
        ["ratingDescription"] = false,
        ["bonusRatingPct"] = false,

        -- Bonus Stats
        ["bonusStats"] = false,
        ["bonusStatValue"] = false,
        ["bonusStatName"] = false,

        -- Quality
        ["isQualityCraft"] = false,
        ["quality"] = true,
        ["craftingQuality"] = false,
        ["craftingQualityID"] = false,
        ["guaranteedCraftingQualityID"] = false,
}

function ProfessionExport:EventHandler(event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        if ProfessionInfo == nil then ProfessionInfo = {} end
    elseif event == "PLAYER_LEAVING_WORLD" then
        ProfessionInfo = ProfexString

        if ProfessionsFrame:IsShown() then
            ProfessionsFrame.CloseButton:Click()
        end
    end
end

function ProfessionExport:JSON(tbl, indent)
    indent = indent or 0
    local json_str = "{"
    for k, v in pairs(tbl) do
        if (type(k) == "number") or (filter[k]) then

            local key_str = ""
            if type(k) == "string" then
                key_str = format("\"%s\":", k)
            else
                key_str = format("%s:", tostring(k))
            end

            local value_str = ""
            if type(v) == "table" then
                value_str = ProfessionExport:JSON(v, indent + 2)
            elseif type(v) == "string" then
                value_str = format("\"%s\"", v)
            else
                value_str = tostring(v)
            end

            json_str = format("%s\n%s%s%s,", json_str, string.rep(" ", indent + 2), key_str, value_str)
        end
    end
    json_str = json_str:sub(1, -2) .. "\n" .. string.rep(" ", indent) .. "}"
    return json_str
end

function ProfessionExport:GetMainFrame(text)
    if not ProfexFrame then
        local f = CreateFrame("Frame", "ProfexFrame", UIParent, "DialogBoxFrame")
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", UIParent, "CENTER", -280, 280)
        f:SetPoint("BOTTOMRIGHT", UIParent, "CENTER", 280, -280)

        local sf = CreateFrame("ScrollFrame", "ProfexScrollFrame", f, "UIPanelScrollFrameTemplate")
        sf:SetPoint("LEFT", 16, 0)
        sf:SetPoint("RIGHT", -32, 0)
        sf:SetPoint("TOP", 0, -32)
        sf:SetPoint("BOTTOM", ProfexFrameButton, "TOP", 0, 0)

        local eb = CreateFrame("EditBox", "ProfexEditBox", ProfexScrollFrame)
        eb:SetSize(sf:GetSize())
        eb:SetMultiLine(true)
        eb:SetAutoFocus(true)
        eb:SetFontObject("ChatFontNormal")
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        sf:SetScrollChild(eb)

        ProfexFrame = f
    end
    ProfexEditBox:SetText(text)
    ProfexEditBox:HighlightText()
    return ProfexFrame
end

function ProfessionExport:ExportRecipeList()
    local recipeData = nil
    local prof1, prof2 = GetProfessions()
    local data = {
        ["playerInfo"] = {
            ["name"] = UnitName("player"),
            ["class"] = UnitClass("player"),
            ["profession1"] = GetProfessionInfo(prof1),
            ["profession2"] = GetProfessionInfo(prof2),
        }
    }

    for i=0, 1, 0.2 do
        for _,recipe in pairs({ProfessionsFrame.CraftingPage.RecipeList.ScrollBox.ScrollTarget:GetChildren()}) do
            if recipe:IsShown() then
                if recipe["SetSelected"] and recipe["learned"]
                and (recipe["Label"]:GetText() ~= "Recraft Equipment") and (recipe["Label"]:GetText() ~= "Illustrious Insight")
                then
                    recipe:Click()
                    if ProfessionsFrame.CraftingPage.SchematicForm:GetRecipeOperationInfo() then
                        recipeData = ProfessionsFrame.CraftingPage.SchematicForm:GetRecipeOperationInfo()
                        recipeData["recipeName"] = GetSpellInfo(recipeData["recipeID"])
                        data[recipeData["recipeID"]] = recipeData
                    end
                end
            end
        end
        ProfessionsFrame.CraftingPage.RecipeList.ScrollBar:SetScrollPercentage(i)
    end
    ProfessionsFrame.CraftingPage.RecipeList.ScrollBar:SetScrollPercentage(0)

    ProfexString = ProfessionExport:JSON(data)
    local f = ProfessionExport:GetMainFrame(ProfexString)
    f:Show()
end

local eFrame = CreateFrame("Frame")
eFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
eFrame:SetScript("OnEvent", ProfessionExport.EventHandler)

local btn = CreateFrame("Button", "ProfexRunButton", ProfessionsFrame.CraftingPage, "UIPanelDynamicResizeButtonTemplate")
btn:SetText("Export Recipe List")
btn:SetPoint("BOTTOMLEFT", ProfessionsFrame.CraftingPage, "BOTTOMLEFT", 320, 6.9)
btn:SetPoint("BOTTOMRIGHT", ProfessionsFrame.CraftingPage, "BOTTOMLEFT", 320 + (btn:GetTextWidth() + 40), 6.9)
btn:SetScript("OnClick", ProfessionExport.ExportRecipeList)
btn:Show()