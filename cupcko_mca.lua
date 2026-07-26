-- cupcko_mca.lua
-- 作者: cupcko
-- 功能：
--   1) 读取外部数据 externalMountData(模拟.json -> lua)
--   2) 按照版本(侧栏)筛选显示坐骑
--   3) 对比游戏内坐骑 SpellID，找出新增/未记录的坐骑
--   4) 差异弹窗，显示新增坐骑的数据（可复制）
--   5) 当前版本筛选下，按 source 进行分组显示
-- UI: 现代化「深色金边」主题，组件由 cupcko_theme.lua 提供

print("|cff00ff00[cupcko debug]|r cupcko.lua loaded!")

local addonName, addonTable = ...
local MyScanner = addonTable.MyScanner
local Theme = addonTable.Theme
local C = Theme.colors

----------------------------------------------------------------
-- 0) 读取外部数据表
----------------------------------------------------------------
if not externalMountData then
    externalMountData = {}
end

----------------------------------------------------------------
-- 0.1) 版本表 & source 表
----------------------------------------------------------------
local expansions = {
    { name = "总览" },
    { name = "至暗之夜" },
    { name = "地心之战" },
    { name = "巨龙时代" },
    { name = "暗影国度" },
    { name = "争霸艾泽拉斯" },
    { name = "军团再临" },
    { name = "德拉诺之王" },
    { name = "熊猫人之谜" },
    { name = "大地的裂变" },
    { name = "巫妖王之怒" },
    { name = "燃烧的远征" },
    { name = "经典旧世" },
    { name = "事件" },
    { name = "促销" },
    { name = "专业" },
    { name = "打架" },
    { name = "其他" },
    { name = "限时活动" },
    { name = "绝版" },
    { name = "未分类" },
}

local sources = {
    "无用占位符",
    "成就",
    "声望",
    "副本掉落",
    "野外稀有",
    "团本掉落",
    "商人出售",
    "宝箱",
    "世界BOSS",
    "版本活动",
    "任务",
    "法夜",
    "通灵",
    "温西尔",
    "格里恩",
    "指挥台",
    "巅峰大使",
    "碎片合成",
    "商栈",
    "招募/复活卷轴",
    "商城出售",
    "典藏礼包",
    "嘉年华",
    "活动",
    "种族购买",
    "绝版",
    "周年庆",
    "工程",
    "锻造",
    "制皮",
    "珠宝",
    "裁缝",
    "附魔",
    "炼金",
    "钓鱼",
    "考古",
    "铭文",
    "采药",
    "挖矿",
    "烹饪",
    "公会商人",
    "黑市",
    "角斗士",
    "占位符",
    "解密",
    "商城下架",
    "商人下架",
    "美酒节",
    "卡牌",
    "万圣节",
    "情人节",
    "暗月马戏团",
    "复活节",
    "冬幕节",
    "春节",
    "死亡骑士",
    "圣骑士",
    "恶魔猎手",
    "术士",
    "兽人",
    "牛头人",
    "亡灵",
    "巨魔",
    "暗夜精灵",
    "狼人",
    "熊猫人",
    "光铸德莱尼",
    "至高岭牛头人",
    "夜之子",
    "虚空精灵",
    "赞达拉巨魔",
    "玛格汉兽人",
    "黑铁矮人",
    "库尔提拉斯人",
    "机械侏儒",
    "狐人",
    "血精灵",
    "龙希尔",
    "土灵",
    "矮人",
    "人类",
    "侏儒",
    "地精",
    "德莱尼",
    "哈兰",
    "灵翼之龙",
    "沙塔尔天空卫队",
    "纳格兰",
    "银色锦标赛",
    "霍迪尔之子",
    "龙眠联军",
    "巴拉丁",
    "拉穆卡恒",
    "云端祥龙骑士团",
    "影踪派",
    "阡陌客",
    "永恒岛",
    "金莲教",
    "至尊天神",
    "要塞兽栏",
    "要塞入侵",
    "德拉诺黄金挑战",
    "阿拉希",
    "黑海岸",
    "突袭",
    "惊魂幻象",
    "原生体合成",
    "托加斯特",
    "盟约通用",
    "幻境新生:熊猫人",
    "幻境新生:军团",
    "时光漫游",
    "熊猫人黄金挑战",
    "炉石传说",
    "搏击俱乐部",
    "邪气鞍座",
    "典藏版",
    "投票",
    "荣誉等级",
    "职业坐骑",
    "风暴英雄",
    "地区",
    "限时",
    "海岛探险",
    "霸业风暴",
    "魔兽争霸",
    "钥石大师",
    "怀旧服",
    "暗黑破坏神",
    "临时",
    "时光裂隙",
    "翡翠梦境",
    "前夕绝版",
    "坐骑收集",
    "传家宝",
    "未实装",
    "未分类",
    "奥特兰克山谷",
    "甲虫的召唤",
    "联名活动",
    "卑鄙双雄",
    "不知道",
    "地下堡"
}

local currentVersionFilter = "总览"

----------------------------------------------------------------
-- 1) 主窗口
----------------------------------------------------------------
local CupckoFrame_MCA = CreateFrame("Frame", "CupckoMainFrame", UIParent, "BackdropTemplate")
CupckoFrame_MCA:SetPoint("CENTER")
CupckoFrame_MCA:SetSize(880, 600)
CupckoFrame_MCA:SetMovable(true)
CupckoFrame_MCA:EnableMouse(true)
CupckoFrame_MCA:RegisterForDrag("LeftButton")
CupckoFrame_MCA:SetScript("OnDragStart", CupckoFrame_MCA.StartMoving)
CupckoFrame_MCA:SetScript("OnDragStop", CupckoFrame_MCA.StopMovingOrSizing)
CupckoFrame_MCA:SetClampedToScreen(true)
CupckoFrame_MCA:SetResizable(true)
CupckoFrame_MCA:SetResizeBounds(560, 360, 1400, 960)
Theme.ApplyPanel(CupckoFrame_MCA, { bg = C.bg, border = C.border })
CupckoFrame_MCA:Hide()

-- 允许通过 ESC 键关闭
tinsert(UISpecialFrames, "CupckoMainFrame")

----------------------------------------------------------------
-- 1.1) 顶栏
----------------------------------------------------------------
local header = Theme.CreateHeader(CupckoFrame_MCA, "坐骑收集")
local closeButton = Theme.CreateCloseButton(CupckoFrame_MCA)
closeButton:SetPoint("TOPRIGHT", -8, -6)

----------------------------------------------------------------
-- 1.2) 左侧版本侧栏（可滚动）
----------------------------------------------------------------
local SIDE_W = 132
local sideBar = CreateFrame("Frame", nil, CupckoFrame_MCA, "BackdropTemplate")
sideBar:SetPoint("TOPLEFT", CupckoFrame_MCA, "TOPLEFT", 8, -44)
sideBar:SetPoint("BOTTOMLEFT", CupckoFrame_MCA, "BOTTOMLEFT", 8, 44)
sideBar:SetWidth(SIDE_W)
Theme.ApplyPanel(sideBar, { bg = C.canvas, border = C.borderInner })

local sContainer, sScroll, sContent, sSlider = Theme.CreateScrollArea(sideBar)
sContainer:SetPoint("TOPLEFT", sideBar, "TOPLEFT", 6, -6)
sContainer:SetPoint("BOTTOMRIGHT", sideBar, "BOTTOMRIGHT", -6, 6)

local tabs = {}
local function SetSelectedTab(idx)
    for i, tab in ipairs(tabs) do
        tab:SetSelected(i == idx)
    end
end

local function OnTabClick(self)
    local idx = self:GetID()
    currentVersionFilter = expansions[idx].name
    SetSelectedTab(idx)
    RefreshMountList()
end

for i, expInfo in ipairs(expansions) do
    local tab = Theme.CreateTab(sContent, expInfo.name, SIDE_W - 26, 24)
    tab:SetID(i)
    tab:SetScript("OnClick", OnTabClick)
    if i == 1 then
        tab:SetPoint("TOPLEFT", sContent, "TOPLEFT", 0, -2)
    else
        tab:SetPoint("TOPLEFT", tabs[i - 1], "BOTTOMLEFT", 0, -3)
    end
    tabs[i] = tab
end
SetSelectedTab(1)

local function GotoTabByVersion(vName)
    for i, expInfo in ipairs(expansions) do
        if expInfo.name == vName then
            currentVersionFilter = vName
            SetSelectedTab(i)
            RefreshMountList()
            return
        end
    end
end

----------------------------------------------------------------
-- 1.3) 内容滚动区
----------------------------------------------------------------
local contentPanel = CreateFrame("Frame", nil, CupckoFrame_MCA, "BackdropTemplate")
contentPanel:SetPoint("TOPLEFT", sideBar, "TOPRIGHT", 8, 0)
contentPanel:SetPoint("BOTTOMRIGHT", CupckoFrame_MCA, "BOTTOMRIGHT", -8, 44)
Theme.ApplyPanel(contentPanel, { bg = C.canvas, border = C.borderInner })

local cContainer, cScroll, cContent, cSlider = Theme.CreateScrollArea(contentPanel)
cContainer:SetPoint("TOPLEFT", contentPanel, "TOPLEFT", 6, -6)
cContainer:SetPoint("BOTTOMRIGHT", contentPanel, "BOTTOMRIGHT", -6, 6)

----------------------------------------------------------------
-- 2) 收集“新增坐骑信息”的表
----------------------------------------------------------------
local newMounts = {}

----------------------------------------------------------------
-- 3) 刷新坐骑列表
----------------------------------------------------------------
function RefreshMountList()
    -- 清理旧内容
    for _, child in ipairs({ cContent:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end
    for _, region in ipairs({ cContent:GetRegions() }) do
        region:Hide()
        region:ClearAllPoints()
    end

    -- 确保内容宽度最新
    if cContainer.UpdateContentSize then cContainer:UpdateContentSize() end

    --------------------------------------------------------
    -- 总览
    --------------------------------------------------------
    if currentVersionFilter == "总览" then
        local mountIDs = C_MountJournal.GetMountIDs()
        if not mountIDs then return end

        local versionStats = {}
        for _, expInfo in ipairs(expansions) do
            versionStats[expInfo.name] = { total = 0, owned = 0 }
        end

        for _, mID in ipairs(mountIDs) do
            local name, spellID, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mID)
            if name and spellID then
                local data = externalMountData[spellID]
                local mountVersion = data and data.version or "未分类"
                if versionStats[mountVersion] then
                    versionStats[mountVersion].total = versionStats[mountVersion].total + 1
                    if isCollected then
                        versionStats[mountVersion].owned = versionStats[mountVersion].owned + 1
                    end
                end
            end
        end

        local usableWidth = cContent:GetWidth()
        if usableWidth < 50 then
            usableWidth = CupckoFrame_MCA:GetWidth() - SIDE_W - 60
        end

        local catWidth = 150
        local catHeight = 56
        local catSpacing = 10
        local xOff = 6
        local yOff = -6

        for _, expInfo in ipairs(expansions) do
            local stats = versionStats[expInfo.name]
            if stats and stats.total > 0 then
                local percentage = (stats.owned / stats.total) * 100
                if xOff + catWidth > usableWidth then
                    xOff = 6
                    yOff = yOff - (catHeight + catSpacing)
                end

                local card, bar, nameText, countText = Theme.CreateCard(cContent, catWidth, catHeight)
                card:SetPoint("TOPLEFT", cContent, "TOPLEFT", xOff, yOff)
                nameText:SetText(expInfo.name)

                bar:SetValue(percentage)
                -- 进度条颜色：100% 柔金，否则柔和绿->黄->红（降饱和降透明，不刺眼）
                if percentage >= 100 then
                    bar:SetStatusBarColor(C.accent[1] * 0.85, C.accent[2] * 0.85, C.accent[3] * 0.85, 0.9)
                else
                    local p = percentage / 100
                    local r = (0.55 * (1 - p)) + 0.12
                    local g = (0.55 * p) + 0.18
                    bar:SetStatusBarColor(r, g, 0.18, 0.85)
                end
                countText:SetText(string.format("%d/%d  (%d%%)", stats.owned, stats.total, percentage))

                card:SetScript("OnClick", function()
                    GotoTabByVersion(expInfo.name)
                end)

                xOff = xOff + catWidth + catSpacing
            end
        end

        cContent:SetHeight(math.abs(yOff) + catHeight + 20)
        return
    end

    --------------------------------------------------------
    -- 非总览：按 source 分组
    --------------------------------------------------------
    if not C_MountJournal or not C_MountJournal.GetMountIDs then return end

    local mountIDs = C_MountJournal.GetMountIDs()
    if not mountIDs then return end

    wipe(newMounts)

    local groupedMounts = {}
    for _, mID in ipairs(mountIDs) do
        local name, spellID, icon, _, _, _, _, _, _, _, isCollected =
            C_MountJournal.GetMountInfoByID(mID)
        if name and spellID then
            local data = externalMountData[spellID]
            local mountItemID  = data and data.itemID  or 0
            local mountVersion = data and data.version or "未分类"
            local mountSource  = data and data.source  or "未分类"

            if currentVersionFilter == "总览" or mountVersion == currentVersionFilter then
                if not groupedMounts[mountSource] then
                    groupedMounts[mountSource] = {}
                end
                table.insert(groupedMounts[mountSource], {
                    spellID     = spellID,
                    name        = name,
                    icon        = icon,
                    isCollected = isCollected,
                    itemID      = mountItemID,
                    mountID     = mID,
                })
            end

            if not data then
                newMounts[spellID] = {
                    name    = name,
                    itemID  = 0,
                    version = "未分类",
                    source  = "未分类",
                }
            end
        end
    end

    local activeSources = {}
    for _, srcName in ipairs(sources) do
        if groupedMounts[srcName] and #groupedMounts[srcName] > 0 then
            table.insert(activeSources, srcName)
        end
    end

    local usableWidth = cContent:GetWidth()
    if usableWidth < 50 then
        usableWidth = CupckoFrame_MCA:GetWidth() - SIDE_W - 60
    end

    local numColumns = math.floor(usableWidth / 300)
    if numColumns < 1 then numColumns = 1 end
    local columnWidth = usableWidth / numColumns

    local columns = {}
    for col = 1, numColumns do
        columns[col] = { x = (col - 1) * columnWidth + 8, y = -8 }
    end

    local rowsPerCol = math.floor(#activeSources / numColumns + 0.5)
    if rowsPerCol < 1 then rowsPerCol = 1 end

    for i, srcName in ipairs(activeSources) do
        local columnIndex = math.floor((i - 1) / rowsPerCol) + 1
        if columnIndex > numColumns then columnIndex = numColumns end
        local col = columns[columnIndex]

        -- 分组标题：柔和文字 + 淡分隔线
        local headerLine = cContent:CreateTexture(nil, "ARTWORK")
        headerLine:SetHeight(1)
        headerLine:SetPoint("TOPLEFT", cContent, "TOPLEFT", col.x, col.y - 18)
        headerLine:SetWidth(columnWidth - 24)
        headerLine:SetColorTexture(0.30, 0.30, 0.34, 0.7)

        local srcHeader = cContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        srcHeader:SetPoint("BOTTOMLEFT", headerLine, "TOPLEFT", 0, 0)
        srcHeader:SetText(srcName)
        srcHeader:SetJustifyH("LEFT")
        srcHeader:SetTextColor(C.text[1], C.text[2], C.text[3], C.text[4])

        col.y = col.y - 26

        local mountsThisSource = groupedMounts[srcName]
        if mountsThisSource and #mountsThisSource > 0 then
            local mountIconSize = 34
            local mountSpacing = 6
            local currentX = col.x
            local currentY = col.y

            for _, mountData in ipairs(mountsThisSource) do
                if currentX + mountIconSize > col.x + columnWidth - 12 then
                    currentX = col.x
                    currentY = currentY - mountIconSize - mountSpacing
                end

                local mountButton = Theme.CreateIconButton(cContent, mountIconSize)
                mountButton:SetPoint("TOPLEFT", cContent, "TOPLEFT", currentX, currentY)
                mountButton.icon:SetTexture(mountData.icon)
                mountButton:SetCollected(mountData.isCollected)

                -- 悬浮名称提示
                mountButton:SetScript("OnEnter", function(self)
                    self:SetHover(true)
                    GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
                    GameTooltip:ClearLines()
                    if mountData.itemID > 0 then
                        GameTooltip:SetItemByID(mountData.itemID)
                    else
                        GameTooltip:SetSpellByID(mountData.spellID)
                    end
                    GameTooltip:Show()
                end)
                mountButton:SetScript("OnLeave", function(self)
                    self:SetHover(false)
                    GameTooltip:Hide()
                end)

                mountButton:SetScript("OnClick", function(self, button)
                    if button == "RightButton" then
                        if mountData.isCollected then
                            C_MountJournal.SummonByID(mountData.mountID)
                        end
                    elseif button == "LeftButton" then
                        if IsShiftKeyDown() then
                            local mountLink = C_MountJournal.GetMountLink(mountData.spellID)
                            if mountData.itemID > 0 then
                                local _, itemLink = GetItemInfo(mountData.itemID)
                                if itemLink then
                                    ChatEdit_InsertLink(itemLink)
                                end
                            end
                            if mountLink then
                                ChatEdit_InsertLink(mountLink)
                            end
                        elseif IsControlKeyDown() then
                            if DressUpMount and type(DressUpMount) == "function" then
                                DressUpMount(mountData.mountID)
                            else
                                local mountLink = C_MountJournal.GetMountLink(mountData.spellID)
                                if mountLink then
                                    DressUpLink(mountLink)
                                end
                            end
                        end
                    end
                end)

                currentX = currentX + mountIconSize + mountSpacing
            end

            col.y = currentY - mountIconSize - mountSpacing
        end
    end

    local maxHeight = 0
    for _, col in ipairs(columns) do
        local height = math.abs(col.y) + 20
        if height > maxHeight then maxHeight = height end
    end
    cContent:SetHeight(maxHeight)
end

----------------------------------------------------------------
-- 4) 差异按钮 + 弹出复制窗口
----------------------------------------------------------------
local showDiffButton = Theme.CreateButton(CupckoFrame_MCA, "差异", 90, 26)
showDiffButton:SetPoint("BOTTOMLEFT", 12, 10)
showDiffButton:SetScript("OnClick", function()
    local diffFrame = CreateFrame("Frame", "CupckoDiffFrame", UIParent, "BackdropTemplate")
    diffFrame:SetPoint("CENTER")
    diffFrame:SetSize(460, 340)
    diffFrame:EnableMouse(true)
    diffFrame:SetMovable(true)
    diffFrame:RegisterForDrag("LeftButton")
    diffFrame:SetScript("OnDragStart", diffFrame.StartMoving)
    diffFrame:SetScript("OnDragStop", diffFrame.StopMovingOrSizing)
    diffFrame:SetClampedToScreen(true)
    Theme.ApplyPanel(diffFrame, { bg = C.bg, border = C.border })
    tinsert(UISpecialFrames, "CupckoDiffFrame")

    local dHeader = Theme.CreateHeader(diffFrame, "差异坐骑")
    local dClose = Theme.CreateCloseButton(diffFrame)
    dClose:SetPoint("TOPRIGHT", -8, -6)

    local dContainer, dScroll, dContent, dSlider = Theme.CreateScrollArea(diffFrame)
    dContainer:SetPoint("TOPLEFT", diffFrame, "TOPLEFT", 10, -46)
    dContainer:SetPoint("BOTTOMRIGHT", diffFrame, "BOTTOMRIGHT", -10, 12)
    Theme.ApplyPanel(dContainer, { bg = C.canvas, border = C.borderInner })

    local editBox = CreateFrame("EditBox", nil, dScroll)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetAutoFocus(false)
    editBox:SetWidth(math.max(dScroll:GetWidth() - 8, 1))
    editBox:SetPoint("TOPLEFT", dScroll, "TOPLEFT", 4, -4)
    dScroll:SetScrollChild(editBox)

    local lines = {}
    table.insert(lines, "-- 差异SpellID => { itemID=?, version=\"?\", source=\"?\" }")
    table.insert(lines, "{")

    local sortedKeys = {}
    for sID in pairs(newMounts) do
        table.insert(sortedKeys, sID)
    end
    table.sort(sortedKeys)

    for _, sID in ipairs(sortedKeys) do
        local info = newMounts[sID]
        table.insert(lines, string.format('  [%d] = { itemID=%d, version="%s", source="%s" }, -- %s',
            sID, info.itemID or 0, info.version or "未分类", info.source or "未分类", info.name or ""))
    end
    table.insert(lines, "}")

    local diffText = table.concat(lines, "\n")
    editBox:SetText(diffText)
    editBox:HighlightText(0)

    -- editBox 宽度随容器变化
    dContainer:HookScript("OnSizeChanged", function()
        editBox:SetWidth(math.max(dScroll:GetWidth() - 8, 1))
    end)

    diffFrame:Show()
end)

-- 调整大小手柄
Theme.CreateResizeGrip(CupckoFrame_MCA, function()
    RefreshMountList()
end)

-- 顶部标题右侧：当前版本标签
local currentVersionLabel = CupckoFrame_MCA:CreateFontString(nil, "OVERLAY", "GameFontNormal")
currentVersionLabel:SetPoint("RIGHT", closeButton, "LEFT", -10, 0)
currentVersionLabel:SetWidth(220)
currentVersionLabel:SetJustifyH("RIGHT")
currentVersionLabel:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3], C.textDim[4])
-- 在 RefreshMountList 后更新版本标签
local _origRefresh = RefreshMountList
RefreshMountList = function()
    _origRefresh()
    currentVersionLabel:SetText(currentVersionFilter)
end

----------------------------------------------------------------
-- 5) 注册事件, Slash 命令
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

CupckoFrame_MCA:SetScript("OnEvent", OnEvent)
CupckoFrame_MCA:RegisterEvent("ADDON_LOADED")
CupckoFrame_MCA:RegisterEvent("PLAYER_LOGIN")
CupckoFrame_MCA:RegisterEvent("COMPANION_UPDATE")
CupckoFrame_MCA:RegisterEvent("NEW_MOUNT_ADDED")

SLASH_CUPCKO_MCA1 = "/."
SLASH_CUPCKO_MCA2 = "/cmca"
SlashCmdList["CUPCKO_MCA"] = function()
    if CupckoFrame_MCA:IsShown() then
        CupckoFrame_MCA:Hide()
    else
        RefreshMountList()
        CupckoFrame_MCA:Show()
        CupckoFrame_MCA:SetFrameLevel(999)
    end
end
