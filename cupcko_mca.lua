-- cupcko+mca.lua
-- 作者: 你的名字
-- 功能：
--   1) 读取外部数据 externalMountData(模拟.json -> lua)，形如：
--         externalMountData[spellID] = { itemID=xxxxx, versionID=2, source=3 }
--   2) 按照版本(通过手动Tab)筛选显示坐骑
--   3) 对比游戏内坐骑 SpellID，找出新增/未记录的坐骑
--   4) 插件界面加个按钮弹窗，显示新增坐骑的数据（可复制）
--   5) 额外：在当前版本筛选下，按 source 进行分组显示

print("|cff00ff00[cupcko debug]|r cupcko.lua loaded!")

local addonName, addonTable = ...
local MyScanner = addonTable.MyScanner

----------------------------------------------------------------
-- 0) 读取外部数据表
----------------------------------------------------------------
-- 假定 externalMountData 在别的地方已经加载进来
if not externalMountData then
    externalMountData = {} -- 如果没加载到，则给个空表
end

----------------------------------------------------------------
-- 0.1) 定义一个版本表 & 当前版本过滤
-- 你可以根据需要增删版本；0表示“全部”
----------------------------------------------------------------
local expansions = {
    { versionID = 1000,  name = "总览" },
    { versionID = 11, name = "地心之战" },
    { versionID = 10, name = "巨龙时代" },
    { versionID = 9,  name = "暗影国度" },
    { versionID = 8,  name = "争霸艾泽拉斯" },
    { versionID = 7,  name = "军团再临" },
    { versionID = 6,  name = "德拉诺之王" },
    { versionID = 5,  name = "熊猫人之谜" },
    { versionID = 4,  name = "大地的裂变" },
    { versionID = 3,  name = "巫妖王之怒" },
    { versionID = 2,  name = "燃烧的远征" },
    { versionID = 1,  name = "经典旧世" },
    { versionID = 100, name = "事件" },
    { versionID = 101, name = "促销" },
    { versionID = 102, name = "专业" },
    { versionID = 103, name = "打架" },
    { versionID = 104, name = "其他" },
    { versionID = 106, name = "限时活动" },
    { versionID = 105, name = "绝版" },
    { versionID = 0, name = "未分类" },
    --{ versionID = 107, name = "收藏" },
}

-- 定义坐骑来源（source）列表
local sources = {
    { cls = 0,  name = "无用占位符" },
    { cls = 1,  name = "成就" },
    { cls = 2,  name = "声望" },
    { cls = 3,  name = "副本掉落" },
    { cls = 4,  name = "野外稀有" },
    { cls = 5,  name = "团本掉落" },
    { cls = 6,  name = "商人出售" },
    { cls = 7,  name = "宝箱" },
    { cls = 8,  name = "世界BOSS" },
    { cls = 9,  name = "版本活动" },
    { cls = 10, name = "任务" },
    { cls = 11, name = "法夜" },
    { cls = 12, name = "通灵" },
    { cls = 13, name = "温西尔" },
    { cls = 14, name = "格里恩" },
    { cls = 15, name = "指挥台" },
    { cls = 16, name = "巅峰大使" },
    { cls = 17, name = "碎片合成" },
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
    { cls = 40, name = "公会商人" },
    { cls = 41, name = "黑市" },
    { cls = 42, name = "角斗士" },
    { cls = 43, name = "占位符" },
    { cls = 44,  name = "解密" },
    { cls = 45,  name = "商城下架" },
    { cls = 46,  name = "商人下架" },
    { cls = 47,  name = "美酒节" },
    { cls = 48,  name = "卡牌" },
    { cls = 49,  name = "万圣节" },
    { cls = 50,  name = "情人节" },
    { cls = 51,  name = "暗月马戏团" },
    { cls = 52,  name = "复活节" },
    { cls = 53,  name = "冬幕节" },
    { cls = 101,  name = "死亡骑士" },
    { cls = 102,  name = "圣骑士" },
    { cls = 103,  name = "恶魔猎手" },
    { cls = 104,  name = "术士" },
    { cls = 150,  name = "兽人" },
    { cls = 151,  name = "牛头人" },
    { cls = 152,  name = "亡灵" },
    { cls = 153,  name = "巨魔" },
    { cls = 154,  name = "暗夜精灵" },
    { cls = 155,  name = "狼人" },
    { cls = 156,  name = "熊猫人" },
    { cls = 157,  name = "光铸德莱尼" },
    { cls = 158,  name = "至高岭牛头人" },
    { cls = 159,  name = "夜之子" },
    { cls = 160,  name = "虚空精灵" },
    { cls = 161,  name = "赞达拉巨魔" },
    { cls = 162,  name = "玛格汉兽人" },
    { cls = 163,  name = "黑铁矮人" },
    { cls = 164,  name = "库尔提拉斯人" },
    { cls = 165,  name = "机械侏儒" },
    { cls = 166,  name = "狐人" },
    { cls = 167,  name = "血精灵" },
    { cls = 168,  name = "龙希尔" },
    { cls = 169,  name = "土灵" },
    { cls = 170,  name = "矮人" },
    { cls = 171,  name = "人类" },
    { cls = 172,  name = "侏儒" },
    { cls = 173,  name = "地精" },
    { cls = 174,  name = "德莱尼" },
    { cls = 201,  name = "哈兰" },
    { cls = 202,  name = "灵翼之龙" },
    { cls = 203,  name = "沙塔尔天空卫队" },
    { cls = 203,  name = "纳格兰" },
    { cls = 301,  name = "银色锦标赛" },
    { cls = 302,  name = "霍迪尔之子" },
    { cls = 303,  name = "龙眠联军" },
    { cls = 401,  name = "巴拉丁" },
    { cls = 402,  name = "拉穆卡恒" },
    { cls = 501,  name = "云端祥龙骑士团" },
    { cls = 502,  name = "影踪派" },
    { cls = 503,  name = "阡陌客" },
    { cls = 504,  name = "永恒岛" },
    { cls = 505,  name = "金莲教" },
    { cls = 506,  name = "至尊天神" },
    { cls = 601,  name = "要塞兽栏" },
    { cls = 602,  name = "要塞入侵" },
    { cls = 603,  name = "德拉诺黄金挑战" },
    { cls = 801,  name = "阿拉希" },
    { cls = 802,  name = "黑海岸" },
    { cls = 803,  name = "突袭" },
    { cls = 804,  name = "惊魂幻象" },
    { cls = 904,  name = "温西尔" },
    { cls = 905,  name = "法夜" },
    { cls = 906,  name = "通灵" },
    { cls = 907,  name = "格里恩" },
    { cls = 908,  name = "原生体合成" },
    { cls = 909,  name = "托加斯特" },
    { cls = 908,  name = "盟约通用" },
    { cls = 1001,  name = "熊猫人幻境新生" },
    { cls = 1002,  name = "时光漫游" },
    { cls = 1003,  name = "熊猫人黄金挑战" },
    { cls = 1004,  name = "炉石传说" },
    { cls = 1005,  name = "搏击俱乐部" },
    { cls = 1006,  name = "邪气鞍座" },
    { cls = 1007,  name = "典藏版" },
    { cls = 1008,  name = "投票" },
    { cls = 1009,  name = "荣誉等级" },
    { cls = 1010,  name = "职业坐骑" },
    { cls = 1011,  name = "风暴英雄" },
    { cls = 1012,  name = "地区" },
    { cls = 1013,  name = "限时" },
    { cls = 1014,  name = "海岛探险" },
    { cls = 1015,  name = "霸业风暴" },
    { cls = 1016,  name = "魔兽争霸" },
    { cls = 1017,  name = "钥石大师" },
    { cls = 1018,  name = "怀旧服" },
    { cls = 1019,  name = "暗黑破坏神" },
    { cls = 1020,  name = "临时" },
    { cls = 1021,  name = "时光裂隙" },
    { cls = 1022,  name = "翡翠梦境" },
    { cls = 1023,  name = "前夕绝版" },
    { cls = 1024,  name = "坐骑收集" },
    { cls = 1025,  name = "传家宝" },
    { cls = 1026,  name = "未实装" },
    { cls = 1027,  name = "无用占位符" },
    { cls = 1028,  name = "奥特兰克山谷" },
    { cls = 1029,  name = "甲虫的召唤" },
}
print(0.01)
-- 当前选中版本（Tab）
local currentVersionFilter = 1000  -- 0表示显示全部

----------------------------------------------------------------
-- 1) 主插件框体
----------------------------------------------------------------
local CupckoFrame = CreateFrame("Frame", "CupckoMainFrame", UIParent, "BackdropTemplate")
CupckoFrame:SetPoint("CENTER")
CupckoFrame:SetSize(800, 600)  -- 默认初始大小（可自行调整）
CupckoFrame:SetMovable(true)
CupckoFrame:EnableMouse(true)
CupckoFrame:RegisterForDrag("LeftButton")
CupckoFrame:SetScript("OnDragStart", CupckoFrame.StartMoving)
CupckoFrame:SetScript("OnDragStop", CupckoFrame.StopMovingOrSizing)
CupckoFrame:SetClampedToScreen(true)
--CupckoFrame:SetBackdropColor(1, 1, 1)
-- CupckoFrame:Hide()
print(0.02)
-- 允许缩放
CupckoFrame:SetResizable(true)
print(0.021)
CupckoFrame:SetResizeBounds(400, 300, 1200, 900)  -- 可根据需要改成更大或更小
print(0.022)
-- CupckoFrame:SetMaxResize(1200, 900)
-- 背景
print(0.03)
CupckoFrame:SetBackdrop({
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile     = true, tileSize = 32, edgeSize = 24,
    insets   = { left = 8, right = 8, top = 8, bottom = 8 }
})
CupckoFrame:Hide()
-- 允许通过 ESC 键关闭 CupckoFrame
tinsert(UISpecialFrames, "CupckoMainFrame")
print(0.1)
-- 标题
local title = CupckoFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
title:SetPoint("TOP", 0, -16)
title:SetText("cupcko坐骑收集")

-- 右上角关闭按钮
local closeButton = CreateFrame("Button", nil, CupckoFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -5, -5)
closeButton:SetFrameLevel(CupckoFrame:GetFrameLevel() + 10)  -- 确保关闭按钮位于顶层
-- 新增部分：左上角重置大小按钮
--local resetButton = CreateFrame("Button", nil, CupckoFrame, "UIPanelButtonTemplate")
--resetButton:SetSize(100, 24)
--resetButton:SetPoint("TOPLEFT", 10, -10) -- 相对于CupckoFrame的左上角，稍微内移
--resetButton:SetText("重置大小")
--resetButton:SetScript("OnClick", function()
--    CupckoFrame:SetSize(800, 600)
--    print("|cff00ff00[cupcko]|r 已将画布大小重置为默认值。")
--end)

-- 右下角拖拽手柄
local resizeGrip = CreateFrame("Frame", nil, CupckoFrame)
resizeGrip:SetSize(32, 32)
resizeGrip:SetPoint("BOTTOMRIGHT")
resizeGrip:EnableMouse(true)
print(0.2)
-- 给拖拽手柄加个简单的纹理，也可用 SizeGrabber
local rgTexture = resizeGrip:CreateTexture(nil, "BACKGROUND")
rgTexture:SetAllPoints()
rgTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

-- 按下时更换纹理
resizeGrip:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        CupckoFrame:StartSizing("BOTTOMRIGHT")
        rgTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    end
end)
-- 松开时停止缩放，并更新纹理 & 重新刷新布局
resizeGrip:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
        CupckoFrame:StopMovingOrSizing()
        rgTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        -- 调整完大小后，刷新布局
        RefreshMountList()
    end
end)
print(0.3)
----------------------------------------------------------------
-- 1.1) “滚动区域” + 内容容器
----------------------------------------------------------------
local scrollFrame = CreateFrame("ScrollFrame", "CupckoScrollFrame", CupckoFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 20, -60)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 60)


local contentFrame = CreateFrame("Frame", "CupckoScrollChild", scrollFrame)
contentFrame:SetSize(1, 1)
scrollFrame:SetScrollChild(contentFrame)

----------------------------------------------------------------
-- 2) 收集“新增坐骑信息”的表
----------------------------------------------------------------
local newMounts = {} -- [spellID] = { name=..., itemID=?, versionID=? }

----------------------------------------------------------------
-- 2.1) 手动创建Tab，并维护“选中”状态
----------------------------------------------------------------
local tabs = {}  -- 存储所有Tab按钮

-- 函数：设置哪个Tab被选中
local function SetSelectedTab(idx)
    for i, expInfo in ipairs(expansions) do
        local tab = tabs[i]
        if i == idx then
            tab:Disable()  -- 选中状态：禁用按钮以表示高亮
        else
            tab:Enable()
        end
    end
end

-- 当点击某个Tab时
local function OnTabClick(self)
    local idx = self:GetID()
    currentVersionFilter = expansions[idx].versionID
    SetSelectedTab(idx)
    print("当前选中 =>", currentVersionFilter)
    RefreshMountList()
end

-- 创建各个Tab按钮
for i, expInfo in ipairs(expansions) do
    local tab = CreateFrame("Button", "CupckoTab"..i, CupckoFrame, "UIPanelButtonTemplate")
    tab:SetID(i)
    tab:SetSize(120, 24)

    -- 这里随便设置一个纹理和按下效果，如果不想要可以注释掉
    tab:SetNormalTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Real")
    tab:SetPushedTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Real-Pressed")

    tab:SetText(expInfo.name)
    tab:SetScript("OnClick", OnTabClick)
    tabs[i] = tab

    -- 设置Tab按钮的位置（垂直排列在左上）
    if i == 1 then
        tab:SetPoint("TOPLEFT", CupckoFrame, "TOPLEFT", -120, 0)
    else
        tab:SetPoint("TOPLEFT", tabs[i-1], "BOTTOMLEFT", 0, -1)
    end
end

-- 默认选中第1个Tab(“总览”)
SetSelectedTab(1)

-- 根据 versionID 找到 expansions 里的下标 i，执行 SetSelectedTab(i) + RefreshMountList
local function GotoTabByVersionID(vID)
    for i, expInfo in ipairs(expansions) do
        if expInfo.versionID == vID then
            currentVersionFilter = vID
            SetSelectedTab(i)  -- 高亮/禁用对应Tab
            RefreshMountList()
            return
        end
    end
    print("没找到对应 versionID=", vID, "的Tab")
end

----------------------------------------------------------------
-- 3) 刷新坐骑列表 & 对比 externalMountData
--    并且在当前版本过滤下，根据 source 进行分类排布
----------------------------------------------------------------
function RefreshMountList()
    -- 1) 先清理旧内容
    for _, child in ipairs({contentFrame:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    -- 再清理所有子 Region（FontString, Texture 等）
    for _, region in ipairs({contentFrame:GetRegions()}) do
        region:Hide()
        region:ClearAllPoints()
    end

    -- 如果当前选择是总览，则执行总览逻辑
    if currentVersionFilter == 1000 then
      

        -- 统计完后，开始画总览
        local mountIDs = C_MountJournal.GetMountIDs()
        if not mountIDs then return end

        local versionStats = {}
        for _, expInfo in ipairs(expansions) do
            versionStats[expInfo.versionID] = { total = 0, owned = 0 }
        end
        
        -- 遍历坐骑统计
        for _, mID in ipairs(mountIDs) do
            local name, spellID, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mID)
            if name and spellID then
                local data = externalMountData[spellID]
                local mountVersion = data and data.versionID or 0

                if versionStats[mountVersion] then
                    versionStats[mountVersion].total = versionStats[mountVersion].total + 1
                    if isCollected then
                        versionStats[mountVersion].owned = versionStats[mountVersion].owned + 1
                    end
                end
            end
        end
        
        --------------------------------------------------------
        -- 让“总览”里的每个资料片进度块从左往右排，超出后换行
        --------------------------------------------------------
        -- 计算可用宽度
        local usableWidth = contentFrame:GetWidth()
        if usableWidth < 50 then
            usableWidth = CupckoFrame:GetWidth() - 60  -- 兼容在窗口初始化时 contentFrame 宽度尚未就绪
        end

        -- 这里你可以根据需要调整块的尺寸、间距
        local catWidth  = 140   -- 每个“资料片进度块”的宽度
        local catHeight = 50    -- 每个“资料片进度块”的高度
        local catSpacing = 10   -- 水平/垂直间隔

        -- 初始“光标”位置（相对于 contentFrame 的左上角）
        local xOff = 10
        local yOff = -10  -- 初始向下偏移



        for i, expInfo in ipairs(expansions) do
            local stats = versionStats[expInfo.versionID]
            if stats and stats.total > 0 then
                local percentage = (stats.owned / stats.total) * 100
                -- 若下一个 catWidth 超出 usableWidth，则换行
                if xOff + catWidth > usableWidth then
                    xOff = 10
                    yOff = yOff - (catHeight + catSpacing)
                end
                -----------------------------------------
                -- 创建一个 Button 代表此资料片进度
                -----------------------------------------
                local catFrame = CreateFrame("Button", nil, contentFrame, "BackdropTemplate")
                catFrame:SetSize(catWidth, catHeight)
                catFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", xOff, yOff)
                catFrame:EnableMouse(true)
                catFrame:RegisterForClicks("AnyUp")
                
                -- 给 catFrame 设置个浅色背景，调试用；实际可不需要
                -- catFrame:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
                -- catFrame:SetBackdropColor(0,0,0,0.8)

                -----------------------------------------
                -- 标题
                -----------------------------------------
                -- 点击 => 跳转到相应版本Tab
                catFrame:SetScript("OnClick", function()
                GotoTabByVersionID(expInfo.versionID)
                end)

                local tabName = catFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                tabName:SetPoint("TOPLEFT", catFrame, "TOPLEFT", 5, -5)
                tabName:SetText(expInfo.name)

                -----------------------------------------
                -- 进度条背景
                -----------------------------------------
                local progressBarBg = catFrame:CreateTexture(nil, "BACKGROUND")
                progressBarBg:SetSize(catWidth - 10, 16)  -- 宽度稍微留点边距
                progressBarBg:SetPoint("TOPLEFT", tabName, "BOTTOMLEFT", 0, -5)
                progressBarBg:SetColorTexture(0.2, 0.2, 0.2, 1)

                -----------------------------------------
                -- 进度条前景
                -----------------------------------------
                local progressBar = catFrame:CreateTexture(nil, "ARTWORK")
                progressBar:SetSize((catWidth - 10) * (percentage / 100), 16)
                progressBar:SetPoint("LEFT", progressBarBg, "LEFT", 0, 0)
                if percentage==100 then
                    progressBar:SetColorTexture(0.35, 0.66, 0.8, 0.7)
                else
                    progressBar:SetColorTexture(1-(0.8*percentage/100), 0.8*percentage/100, 0, 0.7)
                end
                -- print(percentage)
                -----------------------------------------
                -- 百分比文字
                -----------------------------------------
                -- local percentageText = catFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                -- percentageText:SetPoint("LEFT", progressBarBg, "RIGHT", 10, 0)
                -- percentageText:SetText(string.format("%.1f%%", percentage))
                local countText = catFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                countText:SetPoint("CENTER", progressBarBg, "CENTER", 0, 0)
                countText:SetText(string.format("%d/%d (%d%%)", stats.owned, stats.total,percentage))
                -----------------------------------------
                -- 新增：点击事件 => 跳转对应Tab
                -- 不管点击标题还是进度条，都算点在 catFrame 上
                -----------------------------------------
                catFrame:SetScript("OnClick", function()
                    GotoTabByVersionID(expInfo.versionID)
                end)

                -- 最后更新 yOff
                xOff = xOff + catWidth + catSpacing
            end
        end

        -- contentFrame 的高度要足够大，以容纳 yOff 的排布
        contentFrame:SetHeight(math.abs(yOff) + catHeight + 20)
        return
    end

    -- 非总览部分的布局调整
    if not C_MountJournal or not C_MountJournal.GetMountIDs then
        return
    end

    -- 获取所有坐骑ID
    local mountIDs = C_MountJournal.GetMountIDs()
    if not mountIDs then return end

    wipe(newMounts) -- 每次刷新前先清空 newMounts

    -- 按source分组坐骑
    local groupedMounts = {}
    for _, mID in ipairs(mountIDs) do
        local name, spellID, icon, _, _, _, _, _, _, _, isCollected =
            C_MountJournal.GetMountInfoByID(mID)
        if name and spellID then
            local data = externalMountData[spellID]
            local mountItemID  = data and data.itemID    or 0
            local mountVersion = data and data.versionID or 0
            local mountSource  = data and data.source    or 0

            -- 版本过滤 (1000=总览，显示全部; 非1000=只显示指定版本)
            if currentVersionFilter == 1000 or mountVersion == currentVersionFilter then
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

            -- 若 externalMountData[spellID] 不存在 => 说明是新增坐骑
            if not data then
                newMounts[spellID] = {
                    name      = name,
                    itemID    = 0,   -- 先默认0
                    versionID = 0,   -- 先默认0
                    source    = 0,   -- 先默认0
                }
            end
        end
    end

    -- 获取所有有坐骑的source信息
    local activeSources = {}
    for _, srcInfo in ipairs(sources) do
        if groupedMounts[srcInfo.cls] and #groupedMounts[srcInfo.cls] > 0 then
            table.insert(activeSources, srcInfo)
        end
    end

    -- 计算列数和列宽
    local usableWidth = contentFrame:GetWidth()
    if usableWidth < 50 then
        usableWidth = CupckoFrame:GetWidth() - 60  -- 兼容在窗口初始化时 contentFrame 宽度尚未就绪
    end

    local numColumns = math.floor(usableWidth / 300)
    if numColumns < 1 then numColumns = 1 end
    local columnWidth = usableWidth / numColumns

    -- 初始化列的位置
    local columns = {}
    for col = 1, numColumns do
        columns[col] = {
            x = (col - 1) * columnWidth + 10, -- 左边距10
            y = -10, -- 顶部偏移
        }
    end

    -- 分配源到列（每300像素增加一列）
    for i, srcInfo in ipairs(activeSources) do
        local columnIndex = math.floor((i - 1) / math.floor(#activeSources / numColumns + 0.5)) + 1
        if columnIndex > numColumns then
            columnIndex = numColumns
        end
        local col = columns[columnIndex]

        -- 创建源标题
        local header = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        header:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", col.x, col.y)
        header:SetText(srcInfo.name)
        header:SetWidth(columnWidth - 20) -- 预留边距
        header:SetJustifyH("LEFT")

        col.y = col.y - 25 -- 标题高度和间距

        -- 获取该source的所有坐骑
        local mountsThisSource = groupedMounts[srcInfo.cls]
        if mountsThisSource and #mountsThisSource > 0 then
            local mountIconSize = 30
            local mountSpacing = 6
            local currentX = col.x
            local currentY = col.y

            for _, mountData in ipairs(mountsThisSource) do
                -- 如果即将超出列宽，则换行
                if currentX + mountIconSize > col.x + columnWidth - 10 then
                    currentX = col.x
                    currentY = currentY - mountIconSize - mountSpacing
                end

                -- 创建按钮来显示坐骑
                local mountButton = CreateFrame("Button", nil, contentFrame, "BackdropTemplate")
                mountButton:SetSize(mountIconSize, mountIconSize)
                mountButton:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", currentX, currentY)
                mountButton:EnableMouse(true)
                mountButton:RegisterForClicks("AnyUp")
                -- 图标
                local iconTexture = mountButton:CreateTexture(nil, "ARTWORK")
                iconTexture:SetAllPoints()
                iconTexture:SetTexture(mountData.icon)

                -- 创建绿圈边框
                local greenBorder = mountButton:CreateTexture(nil, "BORDER")
                greenBorder:SetSize(mountIconSize + 4, mountIconSize + 4)  -- 略大于图标
                greenBorder:SetPoint("CENTER", iconTexture, "CENTER", 0, 0)
                greenBorder:SetColorTexture(0, 1, 0.2, 0.6)  -- 绿色
                greenBorder:Hide()  -- 默认隐藏

                -- 创建红圈边框
                local redBorder = mountButton:CreateTexture(nil, "BORDER")
                redBorder:SetSize(mountIconSize + 4, mountIconSize + 4)  -- 略大于图标
                redBorder:SetPoint("CENTER", iconTexture, "CENTER", 0, 0)
                redBorder:SetColorTexture(1, 0, 0.2, 0.6)    -- 红色
                redBorder:Hide()  -- 默认隐藏

                -- 根据是否收集，显示相应的边框
                if not mountData.isCollected then
                    redBorder:Show()
                    iconTexture:SetVertexColor(1, 0.5, 0.5, 1)
                else
                    greenBorder:Show()
                    iconTexture:SetVertexColor(1, 1, 1, 1)
                end


                -- 鼠标提示
                mountButton:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:ClearLines()
                    if mountData.itemID > 0 then
                        GameTooltip:SetItemByID(mountData.itemID)
                    else
                        GameTooltip:SetSpellByID(mountData.spellID)
                    end
                    GameTooltip:Show()
                end)
                mountButton:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)

                -- 点击事件
                mountButton:SetScript("OnClick", function(self, button)
                    if button == "RightButton" then
                        if mountData.isCollected then
                            -- 如果坐骑已被收集，召唤坐骑
                            C_MountJournal.SummonByID(mountData.mountID)
                        end

                    elseif button == "LeftButton" then
                        if IsShiftKeyDown() then
                            local mountLink = C_MountJournal.GetMountLink(mountData.spellID)
                            if mountData.itemID > 0 then
                                local itemName, itemLink = GetItemInfo(mountData.itemID)
                                if itemLink then
                                    ChatEdit_InsertLink(itemLink)
                                end
                            end
                            if mountLink then
                                ChatEdit_InsertLink(mountLink)
                            end
                        elseif IsControlKeyDown() then
                            if DressUpMount and type(DressUpMount)=="function" then
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

                -- 更新坐骑图标的位置
                currentX = currentX + mountIconSize + mountSpacing
            end

            -- 更新列的y坐标，留出额外空隙
            col.y = currentY - mountIconSize - mountSpacing
        end
    end

    -- 设置 contentFrame 的高度为所有列中最低的Y坐标
    local maxHeight = 0
    for _, col in ipairs(columns) do
        local height = math.abs(col.y) + 20
        if height > maxHeight then
            maxHeight = height
        end
    end
    contentFrame:SetHeight(maxHeight)
end
print(11)
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
    close:SetPoint("TOPRIGHT", -5, -5)

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
    table.insert(lines, "-- 差异SpellID => { itemID=?, versionID=?, source=? }")
    table.insert(lines, "{")

    -- 对 newMounts 的 key 进行排序
    local sortedKeys = {}
    for sID in pairs(newMounts) do
        table.insert(sortedKeys, sID)
    end
    table.sort(sortedKeys)

    for _, sID in ipairs(sortedKeys) do
        local info = newMounts[sID]
        table.insert(lines, string.format("  [%d] = { itemID=%d, versionID=%d, source=%d }, -- %s",
            sID, info.itemID or 0, info.versionID or 0, info.source or 0, info.name or ""))
    end

    table.insert(lines, "}")

    local diffText = table.concat(lines, "\n")
    editBox:SetText(diffText)
    editBox:HighlightText(0)

    diffFrame:Show()
end)
print(12)
----------------------------------------------------------------
-- 新增功能按钮：Scan Items
----------------------------------------------------------------
--local scanItemsButton = CreateFrame("Button", nil, CupckoFrame, "UIPanelButtonTemplate")
--scanItemsButton:SetSize(100, 24)
---- 放在 showDiffButton 右侧 10 像素，视你布局而定
--scanItemsButton:SetPoint("LEFT", showDiffButton, "RIGHT", 10, 0)
--scanItemsButton:SetText("Scan Items")
--scanItemsButton:SetScript("OnClick", function()
--    MyScanner.StartScan(CupckoFrame) -- 传入 CupckoFrame, 让扫描协程在其 OnUpdate 里跑
--end)

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
        CupckoFrame:SetFrameLevel(999)  -- 设置为较高的层级
    end
end

----------------------------------------------------------------
-- 6) 监听画布大小变化以动态调整布局
----------------------------------------------------------------
--CupckoFrame:SetScript("OnSizeChanged", function(self, width, height)
--    RefreshMountList()
--end)
