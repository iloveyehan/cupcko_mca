-------------------------------------------------------------------------------
-- cupcko.lua
-- 作者: 你的名字
-- 功能：
--   1) 读取外部数据 externalMountData(模拟.json -> lua)，形如:
--         externalMountData[spellID] = { itemID=xxxxx, versionID=2 }
--   2) 按照版本(通过手动Tab)筛选显示坐骑
--   3) 对比游戏内坐骑 SpellID，找出新增/未记录的坐骑
--   4) 插件界面加个按钮弹窗，显示新增坐骑的数据（可复制）
-------------------------------------------------------------------------------

print("|cff00ff00[cupcko debug]|r cupcko.lua loaded!")

local addonName, addonTable = ...
local MyScanner = addonTable.MyScanner
----------------------------------------------------------------
-- 0) 读取外部数据表
----------------------------------------------------------------
if not externalMountData then
    externalMountData = {} -- 如果没加载到，则给个空表
end

----------------------------------------------------------------
-- 0.1) 定义一个版本表 & 当前版本过滤
-- 你可以根据需要增删版本；0表示“全部”
----------------------------------------------------------------
local expansions = {
    { versionID = 0, name = "总览" },
    { versionID = 1, name = "经典旧世" },
    { versionID = 2, name = "燃烧的远征" },
    { versionID = 3, name = "巫妖王之怒" },
    { versionID = 4, name = "大地的裂变" },
    { versionID = 5, name = "熊猫人之谜" },
    { versionID = 6, name = "德拉诺之王" },
    { versionID = 7, name = "军团再临" },
    { versionID = 8, name = "争霸艾泽拉斯" },
    { versionID = 9, name = "暗影国度" },
    { versionID = 10, name = "巨龙时代" },
    { versionID = 11, name = "地心之战" },
    { versionID = 100, name = "事件" },
    { versionID = 101, name = "促销" },
    { versionID = 102, name = "专业" },
    { versionID = 103, name = "打架" },
    { versionID = 104, name = "任务成就" },
    { versionID = 105, name = "绝版" },
    { versionID = 106, name = "未分类" },
    { versionID = 107, name = "收藏" },
}
local source = {
    { cls = 0, name = "任务" },
    { cls = 1, name = "成就" },
    { cls = 2, name = "声望" },
    { cls = 3, name = "副本掉落" },
    { cls = 4, name = "野外稀有" },
    { cls = 5, name = "解密" },
    { cls = 6, name = "商人出售" },
    { cls = 7, name = "宝箱" },
    { cls = 8, name = "专业" },
    { cls = 9, name = "版本活动" },
    { cls = 10, name = "版本玩法" },
    { cls = 11, name = "法夜" },
    { cls = 12, name = "通灵" },
    { cls = 13, name = "温西尔" },
    { cls = 14, name = "格里恩" },
    { cls = 15, name = "指挥台" },
    { cls = 16, name = "巅峰大使" },
    { cls = 17, name = "宝箱" },
    { cls = 18, name = "商栈" },
    { cls = 19, name = "招募/复活卷轴" },
    { cls = 20, name = "商城出售" },
    { cls = 21, name = "典藏礼包" },
    { cls = 22, name = "嘉年华" },
    { cls = 23, name = "活动" },
    { cls = 24, name = "种族购买" },
    { cls = 25, name = "绝版" },
    { cls = 26, name = "周年庆" },
    { cls = 27, name = "工程" },
    { cls = 28, name = "锻造" },
    { cls = 29, name = "制皮" },
    { cls = 30, name = "珠宝" },
    { cls = 31, name = "裁缝" },
    { cls = 32, name = "附魔" },
    { cls = 33, name = "炼金" },
    { cls = 34, name = "钓鱼" },
    { cls = 35, name = "考古" },
    { cls = 36, name = "铭文" },
    { cls = 37, name = "采药" },
    { cls = 38, name = "挖矿" },
    { cls = 39, name = "烹饪" },
    { cls = 40, name = "情人节" },
    { cls = 41, name = "黑市" },

}
local currentVersionFilter = 0  -- 0表示显示全部

----------------------------------------------------------------
-- 1) 主插件框体
----------------------------------------------------------------
local CupckoFrame = CreateFrame("Frame", "CupckoMainFrame", UIParent, "BackdropTemplate")
CupckoFrame:SetPoint("CENTER")
CupckoFrame:SetSize(400, 500)
CupckoFrame:EnableMouse(true)
CupckoFrame:SetMovable(true)
CupckoFrame:RegisterForDrag("LeftButton")
CupckoFrame:SetScript("OnDragStart", CupckoFrame.StartMoving)
CupckoFrame:SetScript("OnDragStop", CupckoFrame.StopMovingOrSizing)
CupckoFrame:SetClampedToScreen(true)
CupckoFrame:Hide()
print(1)
-- 背景
CupckoFrame:SetBackdrop({
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile     = true, tileSize = 32, edgeSize = 32,
    insets   = { left = 8, right = 8, top = 8, bottom = 8 }
})

local title = CupckoFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
title:SetPoint("TOP", 0, -16)
title:SetText("cupcko - Mount list")

local closeButton = CreateFrame("Button", nil, CupckoFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -3, -3)

-- 滚动区域
local scrollFrame = CreateFrame("ScrollFrame", "CupckoScrollFrame", CupckoFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 20, -60)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 60)

local contentFrame = CreateFrame("Frame", "CupckoScrollChild", scrollFrame)
contentFrame:SetSize(1, 1)
scrollFrame:SetScrollChild(contentFrame)
-- print(2)
----------------------------------------------------------------
-- 2) 收集“新增坐骑信息”的表
----------------------------------------------------------------
local newMounts = {} -- [spellID] = { name=..., itemID=?, versionID=? }

----------------------------------------------------------------
-- 2.1) 手动创建Tab，并维护“选中”状态
----------------------------------------------------------------
local tabs = {}  -- 存储所有Tab按钮
-- print(3)
-- 函数：设置哪个Tab被选中
local function SetSelectedTab(idx)
    for i, expInfo in ipairs(expansions) do
        local tab = tabs[i]
        if i == idx then
            -- 选中状态：禁用按钮(某些模板里是这样表现“选中”的)
            tab:Disable()
        else
            -- 未选中状态
            tab:Enable()
        end
    end
end
print(2)
-- 当点击某个Tab时
local function OnTabClick(self)
    local idx = self:GetID()
    currentVersionFilter = expansions[idx].versionID
    SetSelectedTab(idx)
    print("currentVersionFilter =>", currentVersionFilter)
    RefreshMountList()
end
print(3)
-- 创建各个Tab按钮
for i, expInfo in ipairs(expansions) do
    print(3.1)
    -- 这里使用 "CharacterFrameTabButtonTemplate" 也行，你可以换 "UIPanelButtonTemplate"
    local tab = CreateFrame("Button", "CupckoTab"..i, CupckoFrame, "UIPanelButtonTemplate")
    print(3.2)
    tab:SetID(i)
    tab:SetSize(120, 24)
    print(3.3)
    tab:SetNormalTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Real")
    tab:SetPushedTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Real-Pressed")
    print(3.4)
    tab:SetText(expInfo.name)
    tab:SetScript("OnClick", OnTabClick)
    print(3.5)
    tabs[i] = tab
    print(3.6)
    -- 设置Tab按钮的位置
    if i == 1 then
        -- 第一个Tab放在框体底部(也可放顶部,看你需求)
        print(3.7)
        tab:SetPoint("TOPLEFT", CupckoFrame, "TOPLEFT", -120, -40)
    else
        print(3.8)
        -- 后面的Tab紧挨着前一个Tab
        tab:SetPoint("TOPLEFT", tabs[i-1], "BOTTOMLEFT", 0, -5)
    end
    print(3.9)
end
print(4)
-- 默认选中第1个Tab(“全部”)
SetSelectedTab(1)
print(5)
----------------------------------------------------------------
-- 3) 刷新坐骑列表 & 对比 externalMountData
----------------------------------------------------------------
function RefreshMountList()
    -- 清理旧行
    for _, child in ipairs({contentFrame:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    if not C_MountJournal or not C_MountJournal.GetMountIDs then
        return
    end

    local mountIDs = C_MountJournal.GetMountIDs()
    if not mountIDs then return end

    -- 每次刷新前先清空 newMounts
    wipe(newMounts)

    local offsetY = -5
    for _, mID in ipairs(mountIDs) do
        local name, spellID, icon, _, _, _, _, _, _, _, isCollected =
            C_MountJournal.GetMountInfoByID(mID)
        if name and spellID then

            -- 从 externalMountData 里拿 itemID, versionID
            local data = externalMountData[spellID]
            local mountItemID  = 0
            local mountVersion = 0
            if data then
                mountItemID  = data.itemID or 0
                mountVersion = data.versionID or 0
            end

            -- 根据 currentVersionFilter 做版本筛选
            if currentVersionFilter ~= 0 and mountVersion ~= currentVersionFilter then
                -- 不匹配 => 跳过
            else
                -- 显示此坐骑
                local row = CreateFrame("Button", nil, contentFrame, "BackdropTemplate")
                row:SetSize(350, 20)
                row:SetPoint("TOPLEFT", 0, offsetY)
                row:EnableMouse(true)
                row:RegisterForClicks("AnyUp")
                
                offsetY = offsetY - 24

                -- 图标
                local iconTexture = row:CreateTexture(nil, "ARTWORK")
                iconTexture:SetSize(20, 20)
                iconTexture:SetPoint("LEFT", row, "LEFT", 0, 0)
                iconTexture:SetTexture(icon)

                -- 坐骑名称
                local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                text:SetPoint("LEFT", iconTexture, "RIGHT", 5, 0)
                text:SetText(name)

                if not isCollected then
                    text:SetTextColor(0.5, 0.5, 0.5, 1)
                    iconTexture:SetVertexColor(0.5, 0.5, 0.5, 1)
                else
                    text:SetTextColor(1, 1, 1, 1)
                    iconTexture:SetVertexColor(1, 1, 1, 1)
                end

                -- 鼠标提示
                row:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:ClearLines()
                    if mountItemID > 0 then
                        GameTooltip:SetItemByID(mountItemID)
                    else
                        GameTooltip:SetSpellByID(spellID)
                    end
                    GameTooltip:Show()
                end)
                row:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)

                -- 点击(Ctrl=试衣间,Shift=分享)
                row:SetScript("OnClick", function(self, button)
                    if button == "LeftButton" then
                        -- SHIFT =>分享
                        if IsShiftKeyDown() then
                            local mountLink = C_MountJournal.GetMountLink(spellID)
                            if mountItemID > 0 then
                                local itemName, itemLink = GetItemInfo(mountItemID)
                                if itemLink then
                                    ChatEdit_InsertLink(itemLink)
                                end
                            end
                            if mountLink then
                                ChatEdit_InsertLink(mountLink)
                            end
                        -- CTRL =>试衣间
                        elseif IsControlKeyDown() then
                            if DressUpMount and type(DressUpMount)=="function" then
                                DressUpMount(mID)
                            else
                                local mountLink = C_MountJournal.GetMountLink(spellID)
                                if mountLink then
                                    DressUpLink(mountLink)
                                end
                            end
                        end
                    end
                end)
            end

            -- 若 externalMountData[spellID] 不存在 => 新增
            if not data then
                newMounts[spellID] = {
                    name      = name,
                    itemID    = 0,   -- 先默认0
                    versionID = 0,   -- 先默认0
                }
            end
        end
    end

    contentFrame:SetHeight(math.abs(offsetY) + 10)
end

----------------------------------------------------------------
-- 4) “显示差异”按钮 + 弹出复制窗口
----------------------------------------------------------------
local showDiffButton = CreateFrame("Button", nil, CupckoFrame, "UIPanelButtonTemplate")
showDiffButton:SetSize(100, 24)
showDiffButton:SetPoint("BOTTOMLEFT", 20, 20)
showDiffButton:SetText("差异")
showDiffButton:SetScript("OnClick", function()
    local diffFrame = CreateFrame("Frame", "CupckoDiffFrame", UIParent, "BackdropTemplate")
    diffFrame:SetPoint("CENTER")
    diffFrame:SetSize(400, 300)
    diffFrame:EnableMouse(true)
    diffFrame:SetMovable(true)
    diffFrame:RegisterForDrag("LeftButton")
    diffFrame:SetScript("OnDragStart", diffFrame.StartMoving)
    diffFrame:SetScript("OnDragStop", diffFrame.StopMovingOrSizing)

    diffFrame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true, tileSize = 32, edgeSize = 32,
        insets   = { left = 8, right = 8, top = 8, bottom = 8 }
    })

    local close = CreateFrame("Button", nil, diffFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -3, -3)

    local scroll = CreateFrame("ScrollFrame", nil, diffFrame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 15, -15)
    scroll:SetPoint("BOTTOMRIGHT", -35, 15)

    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(330)
    editBox:SetAutoFocus(false)
    scroll:SetScrollChild(editBox)

    local lines = {}
    table.insert(lines, "-- 差异SpellID => { itemID=?, versionID=? }")
    table.insert(lines, "{")

    -- \u5bf9newMounts\u7684key\u8fdb\u884c\u6392\u5e8f
    local sortedKeys = {}
    for sID in pairs(newMounts) do
        table.insert(sortedKeys, sID)
    end
    table.sort(sortedKeys)

    for _, sID in ipairs(sortedKeys) do
        local info = newMounts[sID]
        table.insert(lines, string.format("  [%d] = { itemID=%d, versionID=%d }, -- %s",
            sID, info.itemID or 0, info.versionID or 0, info.name or ""))
    end

    table.insert(lines, "}")

    local diffText = table.concat(lines, "\n")
    editBox:SetText(diffText)
    editBox:HighlightText(0)

    diffFrame:Show()
end)


----------------------------------------------------------------
-- 新增功能按钮：Scan Items
----------------------------------------------------------------
local scanItemsButton = CreateFrame("Button", nil, CupckoFrame, "UIPanelButtonTemplate")
scanItemsButton:SetSize(100, 24)
-- 放在 showDiffButton 右侧 10像素，视你布局而定
scanItemsButton:SetPoint("LEFT", showDiffButton, "RIGHT", 10, 0)
scanItemsButton:SetText("Scan Items")

scanItemsButton:SetScript("OnClick", function()
    MyScanner.StartScan(CupckoFrame) -- 传入 CupckoFrame, 让扫描协程在其 OnUpdate 里跑
end)

----------------------------------------------------------------
-- 5) 注册事件, Slash命令
----------------------------------------------------------------
local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            self:UnregisterEvent("ADDON_LOADED")
        end

    elseif event == "PLAYER_LOGIN" then
        RefreshMountList()

    elseif event == "COMPANION_UPDATE" or event == "NEW_MOUNT_ADDED" then
        RefreshMountList()
    end
end

CupckoFrame:SetScript("OnEvent", OnEvent)
CupckoFrame:RegisterEvent("ADDON_LOADED")
CupckoFrame:RegisterEvent("PLAYER_LOGIN")
CupckoFrame:RegisterEvent("COMPANION_UPDATE")
CupckoFrame:RegisterEvent("NEW_MOUNT_ADDED")

SLASH_CUPCKO1 = "/*"
SlashCmdList["CUPCKO"] = function()
    if CupckoFrame:IsShown() then
        CupckoFrame:Hide()
    else
        RefreshMountList()
        CupckoFrame:Show()
    end
end
