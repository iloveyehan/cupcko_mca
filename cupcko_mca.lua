-- cupcko+mca.lua
-- 作者: cupcko
-- 功能：
--   1) 读取外部数据 externalMountData(模拟.json -> lua)，形如：
--         externalMountData[spellID] = { itemID=xxxxx, version="地心之战", source="副本掉落" }
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
-- 你可以根据需要增删版本；"总览"表示"全部"
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
    --{ name = "收藏" },
}

-- 定义坐骑来源（source）列表
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
}
-- print(0.01)
-- 当前选中版本（Tab）；"总览"表示显示全部
local currentVersionFilter = "总览"

----------------------------------------------------------------
-- 1) 主插件框体
----------------------------------------------------------------
local CupckoFrame_MCA = CreateFrame("Frame", "CupckoMainFrame", UIParent, "BackdropTemplate")
CupckoFrame_MCA:SetPoint("CENTER")
CupckoFrame_MCA:SetSize(800, 600)  -- 默认初始大小（可自行调整）
CupckoFrame_MCA:SetMovable(true)
CupckoFrame_MCA:EnableMouse(true)
CupckoFrame_MCA:RegisterForDrag("LeftButton")
CupckoFrame_MCA:SetScript("OnDragStart", CupckoFrame_MCA.StartMoving)
CupckoFrame_MCA:SetScript("OnDragStop", CupckoFrame_MCA.StopMovingOrSizing)
CupckoFrame_MCA:SetClampedToScreen(true)
--CupckoFrame_MCA:SetBackdropColor(1, 1, 1)
-- CupckoFrame_MCA:Hide()
-- print(0.02)
-- 允许缩放
CupckoFrame_MCA:SetResizable(true)
-- print(0.021)
CupckoFrame_MCA:SetResizeBounds(400, 300, 1200, 900)  -- 可根据需要改成更大或更小
-- print(0.022)
-- CupckoFrame_MCA:SetMaxResize(1200, 900)
-- 背景
-- print(0.03)
CupckoFrame_MCA:SetBackdrop({
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile     = true, tileSize = 32, edgeSize = 24,
    insets   = { left = 8, right = 8, top = 8, bottom = 8 }
})
CupckoFrame_MCA:Hide()
-- 允许通过 ESC 键关闭 CupckoFrame_MCA
tinsert(UISpecialFrames, "CupckoMainFrame")
-- print(0.1)
-- 标题
local title = CupckoFrame_MCA:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
title:SetPoint("TOP", 0, -16)
title:SetText("坐骑收集")

-- 右上角关闭按钮
local closeButton = CreateFrame("Button", nil, CupckoFrame_MCA, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -5, -5)
closeButton:SetFrameLevel(CupckoFrame_MCA:GetFrameLevel() + 10)  -- 确保关闭按钮位于顶层
-- 新增部分：左上角重置大小按钮
--local resetButton = CreateFrame("Button", nil, CupckoFrame_MCA, "UIPanelButtonTemplate")
--resetButton:SetSize(100, 24)
--resetButton:SetPoint("TOPLEFT", 10, -10) -- 相对于CupckoFrame_MCA的左上角，稍微内移
--resetButton:SetText("重置大小")
--resetButton:SetScript("OnClick", function()
--    CupckoFrame_MCA:SetSize(800, 600)
--    print("|cff00ff00[cupcko]|r 已将画布大小重置为默认值。")
--end)

-- 右下角拖拽手柄
local resizeGrip = CreateFrame("Frame", nil, CupckoFrame_MCA)
resizeGrip:SetSize(32, 32)
resizeGrip:SetPoint("BOTTOMRIGHT")
resizeGrip:EnableMouse(true)
-- print(0.2)
-- 给拖拽手柄加个简单的纹理，也可用 SizeGrabber
local rgTexture = resizeGrip:CreateTexture(nil, "BACKGROUND")
rgTexture:SetAllPoints()
rgTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

-- 按下时更换纹理
resizeGrip:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        CupckoFrame_MCA:StartSizing("BOTTOMRIGHT")
        rgTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    end
end)
-- 松开时停止缩放，并更新纹理 & 重新刷新布局
resizeGrip:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
        CupckoFrame_MCA:StopMovingOrSizing()
        rgTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        -- 调整完大小后，刷新布局
        RefreshMountList()
    end
end)
-- print(0.3)
----------------------------------------------------------------
-- 1.1) “滚动区域” + 内容容器
----------------------------------------------------------------
local scrollFrame = CreateFrame("ScrollFrame", "CupckoScrollFrame", CupckoFrame_MCA, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 20, -60)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 60)


local contentFrame = CreateFrame("Frame", "CupckoScrollChild", scrollFrame)
contentFrame:SetSize(1, 1)
scrollFrame:SetScrollChild(contentFrame)

----------------------------------------------------------------
-- 2) 收集“新增坐骑信息”的表
----------------------------------------------------------------
local newMounts = {} -- [spellID] = { name=..., itemID=?, version=?, source=? }

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
    currentVersionFilter = expansions[idx].name
    SetSelectedTab(idx)
    -- print("当前选中 =>", currentVersionFilter)
    RefreshMountList()
end

-- 创建各个Tab按钮
for i, expInfo in ipairs(expansions) do
    local tab = CreateFrame("Button", "CupckoTab"..i, CupckoFrame_MCA, "UIPanelButtonTemplate")
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
        tab:SetPoint("TOPLEFT", CupckoFrame_MCA, "TOPLEFT", -120, 0)
    else
        tab:SetPoint("TOPLEFT", tabs[i-1], "BOTTOMLEFT", 0, -1)
    end
end

-- 默认选中第1个Tab(“总览”)
SetSelectedTab(1)

-- 根据版本名找到 expansions 里的下标 i，执行 SetSelectedTab(i) + RefreshMountList
local function GotoTabByVersion(vName)
    for i, expInfo in ipairs(expansions) do
        if expInfo.name == vName then
            currentVersionFilter = vName
            SetSelectedTab(i)  -- 高亮/禁用对应Tab
            RefreshMountList()
            return
        end
    end
    print("没找到对应版本=", vName, "的Tab")
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
    if currentVersionFilter == "总览" then


        -- 统计完后，开始画总览
        local mountIDs = C_MountJournal.GetMountIDs()
        if not mountIDs then return end

        local versionStats = {}
        for _, expInfo in ipairs(expansions) do
            versionStats[expInfo.name] = { total = 0, owned = 0 }
        end

        -- 遍历坐骑统计
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
        
        --------------------------------------------------------
        -- 让“总览”里的每个资料片进度块从左往右排，超出后换行
        --------------------------------------------------------
        -- 计算可用宽度
        local usableWidth = contentFrame:GetWidth()
        if usableWidth < 50 then
            usableWidth = CupckoFrame_MCA:GetWidth() - 60  -- 兼容在窗口初始化时 contentFrame 宽度尚未就绪
        end

        -- 这里你可以根据需要调整块的尺寸、间距
        local catWidth  = 140   -- 每个“资料片进度块”的宽度
        local catHeight = 50    -- 每个“资料片进度块”的高度
        local catSpacing = 10   -- 水平/垂直间隔

        -- 初始“光标”位置（相对于 contentFrame 的左上角）
        local xOff = 10
        local yOff = -10  -- 初始向下偏移



        for i, expInfo in ipairs(expansions) do
            local stats = versionStats[expInfo.name]
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
                GotoTabByVersion(expInfo.name)
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
                    GotoTabByVersion(expInfo.name)
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
            local mountItemID  = data and data.itemID  or 0
            local mountVersion = data and data.version or "未分类"
            local mountSource  = data and data.source  or "未分类"

            -- 版本过滤 ("总览"=显示全部; 其它=只显示指定版本)
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

            -- 若 externalMountData[spellID] 不存在 => 说明是新增坐骑
            if not data then
                newMounts[spellID] = {
                    name    = name,
                    itemID  = 0,            -- 先默认0
                    version = "未分类",     -- 先默认"未分类"
                    source  = "未分类",     -- 先默认"未分类"
                }
            end
        end
    end

    -- 获取所有有坐骑的source信息
    local activeSources = {}
    for _, srcName in ipairs(sources) do
        if groupedMounts[srcName] and #groupedMounts[srcName] > 0 then
            table.insert(activeSources, srcName)
        end
    end

    -- 计算列数和列宽
    local usableWidth = contentFrame:GetWidth()
    if usableWidth < 50 then
        usableWidth = CupckoFrame_MCA:GetWidth() - 60  -- 兼容在窗口初始化时 contentFrame 宽度尚未就绪
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
    for i, srcName in ipairs(activeSources) do
        local columnIndex = math.floor((i - 1) / math.floor(#activeSources / numColumns + 0.5)) + 1
        if columnIndex > numColumns then
            columnIndex = numColumns
        end
        local col = columns[columnIndex]

        -- 创建源标题
        local header = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        header:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", col.x, col.y)
        header:SetText(srcName)
        header:SetWidth(columnWidth - 20) -- 预留边距
        header:SetJustifyH("LEFT")

        col.y = col.y - 25 -- 标题高度和间距

        -- 获取该source的所有坐骑
        local mountsThisSource = groupedMounts[srcName]
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
                -- mountButton:SetScript("OnEnter", function(self)
                --     GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                --     GameTooltip:ClearLines()
                --     if mountData.itemID > 0 then
                --         GameTooltip:SetItemByID(mountData.itemID)
                --     else
                --         GameTooltip:SetSpellByID(mountData.spellID)
                --     end
                --     GameTooltip:Show()
                -- end)
                mountButton:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
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
-- print(11)
----------------------------------------------------------------
-- 4) “显示差异”按钮 + 弹出复制窗口
----------------------------------------------------------------
local showDiffButton = CreateFrame("Button", nil, CupckoFrame_MCA, "UIPanelButtonTemplate")
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
    table.insert(lines, "-- 差异SpellID => { itemID=?, version=\"?\", source=\"?\" }")
    table.insert(lines, "{")

    -- 对 newMounts 的 key 进行排序
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

    diffFrame:Show()
end)
-- print(12)
----------------------------------------------------------------
-- 新增功能按钮：Scan Items
----------------------------------------------------------------
--local scanItemsButton = CreateFrame("Button", nil, CupckoFrame_MCA, "UIPanelButtonTemplate")
--scanItemsButton:SetSize(100, 24)
---- 放在 showDiffButton 右侧 10 像素，视你布局而定
--scanItemsButton:SetPoint("LEFT", showDiffButton, "RIGHT", 10, 0)
--scanItemsButton:SetText("Scan Items")
--scanItemsButton:SetScript("OnClick", function()
--    MyScanner.StartScan(CupckoFrame_MCA) -- 传入 CupckoFrame_MCA, 让扫描协程在其 OnUpdate 里跑
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

CupckoFrame_MCA:SetScript("OnEvent", OnEvent)
CupckoFrame_MCA:RegisterEvent("ADDON_LOADED")
CupckoFrame_MCA:RegisterEvent("PLAYER_LOGIN")
CupckoFrame_MCA:RegisterEvent("COMPANION_UPDATE")
CupckoFrame_MCA:RegisterEvent("NEW_MOUNT_ADDED")

SLASH_CUPCKO_MCA1 = "/."
SlashCmdList["CUPCKO_MCA"] = function()
    if CupckoFrame_MCA:IsShown() then
        CupckoFrame_MCA:Hide()
    else
        RefreshMountList()
        CupckoFrame_MCA:Show()
        CupckoFrame_MCA:SetFrameLevel(999)  -- 设置为较高的层级
    end
end

----------------------------------------------------------------
-- 6) 监听画布大小变化以动态调整布局
----------------------------------------------------------------
--CupckoFrame_MCA:SetScript("OnSizeChanged", function(self, width, height)
--    RefreshMountList()
--end)
