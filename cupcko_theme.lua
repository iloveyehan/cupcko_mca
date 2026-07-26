-- cupcko_theme.lua
-- 现代化「深色金边」主题：集中配色与 UI 组件工厂
-- 供 cupcko_mca.lua 与 myScanner.lua 共用

local addonName, addonTable = ...

local Theme = {}
addonTable.Theme = Theme

----------------------------------------------------------------
-- 配色
----------------------------------------------------------------
Theme.colors = {
    bg          = { 0.13, 0.14, 0.17, 0.96 },  -- 柔和深蓝灰，通透不压抑
    panel       = { 0.16, 0.17, 0.20, 0.98 },
    panelDark   = { 0.10, 0.11, 0.14, 1.00 },  -- 按下/凹陷
    canvas      = { 0.11, 0.12, 0.15, 1.00 },  -- 内容画布
    hover       = { 0.22, 0.23, 0.28, 1.00 },  -- 悬浮
    border      = { 0.34, 0.31, 0.25, 1.00 },  -- 淡金灰外框（柔和）
    borderInner = { 0.24, 0.24, 0.28, 0.55 },  -- 内层淡灰细边（清爽通透）
    accent      = { 0.72, 0.64, 0.47, 1.00 },  -- 柔和香槟金（降饱和护眼）
    accentDim   = { 0.42, 0.38, 0.28, 1.00 },  -- 暗金
    text        = { 0.88, 0.87, 0.82, 1.00 },  -- 柔和米白
    textDim      = { 0.58, 0.57, 0.54, 1.00 },  -- 柔和灰
    success     = { 0.28, 0.74, 0.40, 1.00 },  -- 绿框（已收集）
    warn        = { 0.82, 0.68, 0.32, 1.00 },
    danger      = { 0.80, 0.34, 0.34, 1.00 },  -- 红框（未收集）
}

local C = Theme.colors
local WHITE = "Interface\\Buttons\\WHITE8x8"

----------------------------------------------------------------
-- 工具
----------------------------------------------------------------
-- 给一个 frame 应用扁平深色面板（含细边）
-- opts: { bg=, border=, edgeSize=, insets= }
function Theme.ApplyPanel(frame, opts)
    opts = opts or {}
    frame:SetBackdrop({
        bgFile   = WHITE,
        edgeFile = WHITE,
        tile     = false,
        edgeSize = opts.edgeSize or 1,
        insets   = opts.insets or { left = 0, right = 0, top = 0, bottom = 0 },
    })
    local bg = opts.bg or C.panel
    local bd = opts.border or C.border
    frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
    frame:SetBackdropBorderColor(bd[1], bd[2], bd[3], bd[4])
    return frame
end

-- 扁平按钮（含 hover/pressed 状态）
function Theme.CreateButton(parent, text, w, h)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    if w and h then b:SetSize(w, h) end
    Theme.ApplyPanel(b, { bg = C.panel, border = C.border })
    b:SetNormalFontObject("GameFontNormal")
    b:SetHighlightFontObject("GameFontHighlight")
    b:SetDisabledFontObject("GameFontDisable")
    if text then b:SetText(text) end
    b:EnableMouse(true)
    b:RegisterForClicks("AnyUp")

    local function paint(bg, bd)
        b:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
        b:SetBackdropBorderColor(bd[1], bd[2], bd[3], bd[4])
    end
    b:SetScript("OnEnter", function() paint(C.hover, C.accent) end)
    b:SetScript("OnLeave", function() paint(C.panel, C.border) end)
    b:SetScript("OnMouseDown", function(_, btn)
        if btn == "LeftButton" then paint(C.panelDark, C.accentDim) end
    end)
    b:SetScript("OnMouseUp", function(_, btn)
        if btn == "LeftButton" then paint(C.hover, C.accent) end
    end)
    -- 文字浅金色
    local fs = b:GetFontString()
    if fs then fs:SetTextColor(C.text[1], C.text[2], C.text[3], C.text[4]) end
    b._paint = paint
    return b
end

-- 顶栏：金色标题 + 底部分隔线
function Theme.CreateHeader(parent, titleText)
    local header = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    header:SetHeight(36)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    Theme.ApplyPanel(header, { bg = C.panelDark, border = C.panelDark })

    local sep = header:CreateTexture(nil, "OVERLAY")
    sep:SetHeight(1)
    sep:SetPoint("BOTTOMLEFT", 8, 0)
    sep:SetPoint("BOTTOMRIGHT", -8, 0)
    sep:SetColorTexture(0.26, 0.25, 0.22, 0.85)  -- 淡金灰分隔线，不抢眼
    header.sep = sep

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", 16, 1)
    title:SetText(titleText)
    title:SetTextColor(C.accent[1], C.accent[2], C.accent[3], C.accent[4])
    header.title = title
    return header
end

-- 关闭按钮：扁平金边 ✕
function Theme.CreateCloseButton(parent)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(24, 24)
    Theme.ApplyPanel(b, { bg = C.panel, border = C.border })
    b:EnableMouse(true)
    b:RegisterForClicks("AnyUp")
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    fs:SetPoint("CENTER", 0, 0)
    fs:SetText("✕")
    fs:SetTextColor(C.text[1], C.text[2], C.text[3], C.text[4])
    b:SetScript("OnEnter", function()
        b:SetBackdropColor(C.danger[1], C.danger[2], C.danger[3], 0.85)
        b:SetBackdropBorderColor(C.danger[1], C.danger[2], C.danger[3], 1)
        fs:SetTextColor(1, 1, 1, 1)
    end)
    b:SetScript("OnLeave", function()
        b:SetBackdropColor(C.panel[1], C.panel[2], C.panel[3], C.panel[4])
        b:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], C.border[4])
        fs:SetTextColor(C.text[1], C.text[2], C.text[3], C.text[4])
    end)
    b:SetScript("OnClick", function() parent:Hide() end)
    return b
end

-- 调整大小手柄（右下角）
function Theme.CreateResizeGrip(parent, onResizeStop)
    local grip = CreateFrame("Frame", nil, parent)
    grip:SetSize(18, 18)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip:EnableMouse(true)
    -- 三条对角线模拟把手
    for i = 0, 2 do
        local line = grip:CreateTexture(nil, "OVERLAY")
        line:SetSize(10 - i * 2, 2)
        line:SetPoint("BOTTOMRIGHT", -2 - i * 2, 2 + i * 2)
        line:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.5)
    end
    grip:SetScript("OnMouseDown", function(_, btn)
        if btn == "LeftButton" then parent:StartSizing("BOTTOMRIGHT") end
    end)
    grip:SetScript("OnMouseUp", function(_, btn)
        if btn == "LeftButton" then
            parent:StopMovingOrSizing()
            if onResizeStop then onResizeStop() end
        end
    end)
    grip:SetScript("OnEnter", function()
        for i = 0, 2 do
            local line = select(i + 1, grip:GetRegions())
            if line then line:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1) end
        end
    end)
    grip:SetScript("OnLeave", function()
        for i = 0, 2 do
            local line = select(i + 1, grip:GetRegions())
            if line then line:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.5) end
        end
    end)
    return grip
end

----------------------------------------------------------------
-- 侧栏药丸 Tab
----------------------------------------------------------------
function Theme.CreateTab(parent, text, w, h)
    local tab = CreateFrame("Button", nil, parent, "BackdropTemplate")
    tab:SetSize(w or 118, h or 26)
    tab:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    tab:SetBackdropColor(0, 0, 0, 0)
    tab:SetBackdropBorderColor(0, 0, 0, 0)
    tab:EnableMouse(true)
    tab:RegisterForClicks("AnyUp")
    tab:SetNormalFontObject("GameFontNormal")
    local fs = tab:GetFontString()
    if fs then
        fs:SetJustifyH("LEFT")
        fs:SetPoint("LEFT", 12, 0)
    end
    tab:SetText(text or "")

    -- 左侧金色高亮条（选中时显示）
    local bar = tab:CreateTexture(nil, "OVERLAY")
    bar:SetSize(3, (h or 26) - 8)
    bar:SetPoint("LEFT", 3, 0)
    bar:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
    bar:Hide()

    local function refresh()
        if tab.selected then
            tab:SetBackdropColor(C.hover[1], C.hover[2], C.hover[3], 1)
            tab:SetBackdropBorderColor(C.accentDim[1], C.accentDim[2], C.accentDim[3], 0.7)
            if fs then fs:SetTextColor(C.accent[1], C.accent[2], C.accent[3], C.accent[4]) end
            bar:Show()
        else
            tab:SetBackdropColor(0, 0, 0, 0)
            tab:SetBackdropBorderColor(0, 0, 0, 0)
            if fs then fs:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3], C.textDim[4]) end
            bar:Hide()
        end
    end
    function tab:SetSelected(sel)
        tab.selected = sel
        refresh()
    end
    tab:SetScript("OnEnter", function()
        if not tab.selected then
            tab:SetBackdropColor(C.hover[1], C.hover[2], C.hover[3], 0.6)
            if fs then fs:SetTextColor(C.text[1], C.text[2], C.text[3], C.text[4]) end
        end
    end)
    tab:SetScript("OnLeave", function()
        if not tab.selected then refresh() end
    end)
    refresh()
    return tab
end

----------------------------------------------------------------
-- 自定义滚动区（细金色滑块 + 鼠标滚轮）
-- 返回 container, scroll, content, slider
----------------------------------------------------------------
function Theme.CreateScrollArea(parent)
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    local scroll = CreateFrame("ScrollFrame", nil, container, "BackdropTemplate")
    -- 右侧留 10px 给滑块
    scroll:SetPoint("TOPLEFT", container, "TOPLEFT", 2, -2)
    scroll:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -12, 2)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)

    local slider = CreateFrame("Slider", nil, container, "BackdropTemplate")
    slider:SetOrientation("VERTICAL")
    slider:SetWidth(6)
    slider:SetPoint("TOPRIGHT", container, "TOPRIGHT", -4, -2)
    slider:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -4, 2)
    slider:SetBackdrop({ bgFile = WHITE })
    slider:SetBackdropColor(0, 0, 0, 0.30)
    slider:SetThumbTexture(WHITE)
    local thumb = slider:GetThumbTexture()
    thumb:SetSize(6, 40)
    -- 中性灰滑块，清爽不抢眼
    thumb:SetColorTexture(0.55, 0.55, 0.60, 0.85)
    slider:SetMinMaxValues(0, 1)
    slider:SetValue(0)
    slider:SetValueStep(1)

    slider:SetScript("OnValueChanged", function(_, val)
        scroll:SetVerticalScroll(val)
    end)
    scroll:SetScript("OnScrollRangeChanged", function(_, xrange, yrange)
        if yrange and yrange > 0 then
            slider:SetMinMaxValues(0, yrange)
            slider:Show()
        else
            slider:Hide()
        end
    end)

    -- 鼠标滚轮（子按钮未启用 wheel 时，事件落到此 frame）
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(_, delta)
        local mn, mx = slider:GetMinMaxValues()
        local v = slider:GetValue()
        if delta > 0 then
            v = math.max(mn, v - 48)
        else
            v = math.min(mx, v + 48)
        end
        slider:SetValue(v)
    end)

    -- 内容宽度同步（保证布局可用宽度正确）
    container.UpdateContentSize = function()
        content:SetWidth(math.max(scroll:GetWidth() - 4, 1))
    end
    scroll:SetScript("OnSizeChanged", function()
        container:UpdateContentSize()
    end)
    container:UpdateContentSize()

    return container, scroll, content, slider
end

----------------------------------------------------------------
-- StatusBar（进度条）
----------------------------------------------------------------
function Theme.CreateStatusBar(parent, w, h)
    local bar = CreateFrame("StatusBar", nil, parent, "BackdropTemplate")
    bar:SetSize(w, h)
    bar:SetStatusBarTexture(WHITE)
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(0)
    -- 无外框，空槽用很暗的底，降低与填充色的对比，不刺眼
    bar:SetBackdrop({ bgFile = WHITE, edgeFile = nil, edgeSize = 0 })
    bar:SetBackdropColor(0.05, 0.05, 0.07, 1)
    return bar
end

----------------------------------------------------------------
-- 坐骑图标按钮
-- 用法: b:SetCollected(bool); b:SetHover(bool)
----------------------------------------------------------------
function Theme.CreateIconButton(parent, size)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(size, size)
    -- 用纯色底作为彩色框（红/绿），图标居中略小露出 2px 边框
    b:SetBackdrop({ bgFile = WHITE, edgeFile = nil, edgeSize = 0 })
    b:EnableMouse(true)
    b:RegisterForClicks("AnyUp")

    local tex = b:CreateTexture(nil, "ARTWORK")
    tex:SetSize(size - 4, size - 4)
    tex:SetPoint("CENTER")
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)  -- 裁掉图标透明边
    b.icon = tex

    -- 悬浮高亮层
    local hl = b:CreateTexture(nil, "OVERLAY")
    hl:SetAllPoints(tex)
    hl:SetColorTexture(1, 1, 1, 0.14)
    hl:Hide()
    b.hl = hl

    function b:SetCollected(collected)
        b.collected = collected
        if collected then
            b.icon:SetVertexColor(1, 1, 1, 1)
            b:SetBackdropColor(C.success[1], C.success[2], C.success[3], 0.92)  -- 绿框
        else
            b.icon:SetVertexColor(0.45, 0.45, 0.45, 0.92)
            b:SetBackdropColor(C.danger[1], C.danger[2], C.danger[3], 0.92)     -- 红框
        end
    end

    b._baseLevel = b:GetFrameLevel()
    function b:SetHover(hovered)
        if hovered then
            b:SetFrameLevel(b._baseLevel + 10)
            hl:Show()
            if b.collected then
                b:SetBackdropColor(C.success[1], C.success[2], C.success[3], 1)
            else
                b:SetBackdropColor(C.danger[1], C.danger[2], C.danger[3], 1)
            end
        else
            b:SetFrameLevel(b._baseLevel)
            hl:Hide()
            b:SetCollected(b.collected)  -- 复位边框颜色
        end
    end
    return b
end

-- 总览卡片：扁平面板 + 标题 + 进度条 + 计数
-- 返回 card (Button), statusBar, nameText, countText
function Theme.CreateCard(parent, w, h)
    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:SetSize(w, h)
    Theme.ApplyPanel(card, { bg = C.panel, border = C.borderInner })
    card:EnableMouse(true)
    card:RegisterForClicks("AnyUp")

    local nameText = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOPLEFT", 8, -5)
    nameText:SetJustifyH("LEFT")
    nameText:SetTextColor(C.text[1], C.text[2], C.text[3], C.text[4])

    local bar = Theme.CreateStatusBar(card, w - 16, 12)
    bar:SetPoint("BOTTOMLEFT", 8, 6)

    local countText = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    countText:SetPoint("CENTER")
    -- 柔和近白 + 描边阴影，保证叠在彩色进度条上仍清晰不刺眼
    countText:SetTextColor(0.96, 0.96, 0.93, 0.95)
    countText:SetShadowColor(0, 0, 0, 0.9)
    countText:SetShadowOffset(1, -1)

    card:SetScript("OnEnter", function()
        card:SetBackdropColor(C.hover[1], C.hover[2], C.hover[3], 1)
        card:SetBackdropBorderColor(C.borderInner[1], C.borderInner[2], C.borderInner[3], 1)
    end)
    card:SetScript("OnLeave", function()
        card:SetBackdropColor(C.panel[1], C.panel[2], C.panel[3], C.panel[4])
        card:SetBackdropBorderColor(C.borderInner[1], C.borderInner[2], C.borderInner[3], C.borderInner[4])
    end)
    return card, bar, nameText, countText
end

return Theme
