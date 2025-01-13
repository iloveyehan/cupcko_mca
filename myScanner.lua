-- myScanner.lua
local addonName, addonTable = ...

local M = {}

--====================================================================--
-- 1) 全局/内部表
--====================================================================--
-- mountID -> itemID  (阶段1得到)
local itemMountMap  = {}
-- mountSpellID -> { itemID=?, versionID=0 } (阶段2得到)
local scannedMounts = {}

-- 配置参数 (可根据需要调整)
local ITEM_MAX_ID    = 500000  -- 扫描物品ID范围上限
local SPELL_MAX_ID   = 500000  -- 扫描法术ID范围上限
local CHUNK_SIZE     = 300    -- 每帧(or每yield)处理多少个 item/spell
local SCAN_INTERVAL  = 0.01    -- 协程onUpdate的间隔

local scanCoroutine  -- 主协程
local progressFrame  -- 进度条Frame

-- 用于“先请求加载物品”的异步管理
local pendingItems = {}    -- [itemID] = true，表示已请求过但尚未收到
local loadedCount  = 0     -- 已经收到事件 (成功或不成功) 的个数

--====================================================================--
-- 2) 进度条UI
--====================================================================--
local function CreateProgressBar()
    local frame = CreateFrame("Frame", "ScanProgressFrame", UIParent, "BackdropTemplate")
    frame:SetSize(300, 40)
    frame:SetPoint("CENTER", 0, 200)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true, tileSize = 32, edgeSize = 32,
        insets   = { left=8, right=8, top=8, bottom=8 }
    })

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -5)
    title:SetText("扫描进度")

    local statusBar = CreateFrame("StatusBar", nil, frame, "BackdropTemplate")
    statusBar:SetSize(260, 14)
    statusBar:SetPoint("TOP", 0, -20)
    statusBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    statusBar:SetMinMaxValues(0, 1)
    statusBar:SetValue(0)

    local statusText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusText:SetPoint("CENTER")
    statusText:SetText("0%")

    -- 关闭按钮
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -3, -3)

    frame.statusBar  = statusBar
    frame.statusText = statusText

    return frame
end

--====================================================================--
-- 3) 事件监听框架: 用来接收 GET_ITEM_INFO_RECEIVED
--====================================================================--
local scanFrame = CreateFrame("Frame")
scanFrame:Hide()  -- 不用于显示UI，仅作事件载体

scanFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
scanFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "GET_ITEM_INFO_RECEIVED" then
        local itemID, success = ...
        if pendingItems[itemID] then
            -- 无论成功与否，都算“响应”了
            pendingItems[itemID] = nil
            loadedCount = loadedCount + 1

            if success then
                -- 现在可以安全调用 GetMountFromItem
                local mountID = C_MountJournal.GetMountFromItem(itemID)
                if mountID and mountID > 0 then
                    itemMountMap[mountID] = itemID
                end
            end
        end
    end
end)

--====================================================================--
-- 4) 阶段1：请求加载 itemID，并等待异步事件
--====================================================================--
-- 注意：这里依旧是用协程“假装”在扫描 itemID；但真正的 mountID 获取放到事件回调中做
--====================================================================--
local function ScanItems()
    local totalItems = ITEM_MAX_ID
    for itemID = 1, ITEM_MAX_ID do
        -- 调用 RequestLoadItemDataByID
        pendingItems[itemID] = true
        C_Item.RequestLoadItemDataByID(itemID)

        -- 更新进度条
        if progressFrame then
            local fraction = itemID / totalItems
            progressFrame.statusBar:SetValue(fraction)
            progressFrame.statusText:SetText(string.format("Item Scan: %.1f%%", fraction*100))
        end

        -- 每处理 CHUNK_SIZE 个，yield
        if (itemID % CHUNK_SIZE) == 0 then
            coroutine.yield("items")
        end
    end

    -- 所有 itemID 都已请求加载，但可能还没完全收到回调
    print("|cff00ff00[SCAN]|r 已对所有 itemID 请求加载, 等待事件回调...")

    -- 这里你可选择“等待一阵子” 或 直接进入下个阶段
    -- 简单做法：再yield若干次，给时间让事件回调填充 itemMountMap
    for i = 1, 10 do
        coroutine.yield("waiting")  
    end
end

--====================================================================--
-- 5) 阶段2：扫描 mountSpellID => mountID
--====================================================================--
local function ScanMountSpells()
    for mountSpellID = 1, SPELL_MAX_ID do
        local mountID = C_MountJournal.GetMountFromSpell(mountSpellID)
        if mountID then
            local itemID = itemMountMap[mountID]
            if itemID then
                scannedMounts[mountSpellID] = { itemID = itemID, versionID=0 }
            end
        end

        -- 更新进度条
        if progressFrame then
            local fraction = mountSpellID / SPELL_MAX_ID
            progressFrame.statusBar:SetValue(fraction)
            progressFrame.statusText:SetText(string.format("Spell Scan: %.1f%%", fraction*100))
        end

        if (mountSpellID % CHUNK_SIZE) == 0 then
            coroutine.yield("spells")
        end
    end
end

--====================================================================--
-- 6) 最终展示 scannedMounts
--====================================================================--
local function ShowScanResults()
    local frame = CreateFrame("Frame", "CupckoScanFrame", UIParent, "BackdropTemplate")
    frame:SetSize(400, 300)
    frame:SetPoint("CENTER")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true, tileSize = 32, edgeSize = 32,
        insets   = { left=8, right=8, top=8, bottom=8 }
    })

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -3, -3)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 15, -15)
    scroll:SetPoint("BOTTOMRIGHT", -35, 15)

    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(330)
    editBox:SetAutoFocus(false)
    scroll:SetScrollChild(editBox)

    local lines = {}
    table.insert(lines, "-- scannedMounts (mountSpellID => { itemID=?, versionID=0 })")
    table.insert(lines, "{")
    for spellID, data in pairs(scannedMounts) do
        table.insert(lines, string.format("  [%d] = { itemID=%d, versionID=0 },", spellID, data.itemID))
    end
    table.insert(lines, "}")

    local resultText = table.concat(lines, "\n")
    editBox:SetText(resultText)
    editBox:HighlightText(0)
    frame:Show()
end

--====================================================================--
-- 7) 主协程: 先ScanItems -> 再ScanMountSpells -> 最后ShowScanResults
--====================================================================--
local function MainScanCoroutine()
    print("|cff00ff00[SCAN]|r 开始请求加载 itemID ...")
    if progressFrame then
        progressFrame.statusBar:SetValue(0)
        progressFrame.statusText:SetText("Item Scan: 0%")
    end
    ScanItems()

    print("|cff00ff00[SCAN]|r 开始扫描 mountSpellID ...")
    if progressFrame then
        progressFrame.statusBar:SetValue(0)
        progressFrame.statusText:SetText("Spell Scan: 0%")
    end
    ScanMountSpells()

    print("|cff00ff00[SCAN]|r 扫描完成. 即将展示结果 ...")
    -- 隐藏进度条
    if progressFrame then
        progressFrame:Hide()
    end
    ShowScanResults()
end

--====================================================================--
-- 8) OnUpdate: 分帧 resume 协程
--====================================================================--
local function OnUpdateHandler(self, elapsed)
    self.lastUpdate = (self.lastUpdate or 0) + elapsed
    if self.lastUpdate < SCAN_INTERVAL then
        return
    end
    self.lastUpdate = 0

    if scanCoroutine and coroutine.status(scanCoroutine) ~= "dead" then
        local ok, ret = coroutine.resume(scanCoroutine)
        if not ok then
            print("|cffff0000[SCAN ERROR]|r", ret)
            scanCoroutine = nil
            self:SetScript("OnUpdate", nil)
            if progressFrame then
                progressFrame:Hide()
            end
        end
    else
        self:SetScript("OnUpdate", nil)
        scanCoroutine = nil
        if progressFrame then
            progressFrame:Hide()
        end
    end
end

--====================================================================--
-- 9) 对外暴露: StartScan()
--====================================================================--
function M.StartScan(parentFrame)
    wipe(itemMountMap)
    wipe(scannedMounts)
    wipe(pendingItems)
    scanCoroutine = nil

    -- 若没创建进度条则创建
    if not progressFrame then
        progressFrame = CreateProgressBar()
    else
        progressFrame:Show()
        progressFrame.statusBar:SetValue(0)
        progressFrame.statusText:SetText("Ready...")
    end

    -- 启动协程
    scanCoroutine = coroutine.create(MainScanCoroutine)
    parentFrame:SetScript("OnUpdate", OnUpdateHandler)

    -- 显示并注册事件Frame
    scanFrame:Show()
end

-- 如果你想在外部查看 scannedMounts
function M.GetScannedMounts()
    return scannedMounts
end

addonTable.MyScanner = M
