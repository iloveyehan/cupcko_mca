#!/usr/bin/env python3
# fill_spell_item.py

import re
import argparse
import time
import os
import shutil
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
from bs4 import BeautifulSoup

# 解析 Lua 的正则
RE_SPELL_LINE = re.compile(r"\[(\d+)\]\s*=\s*{([^}]+)}")
RE_ITEM_PLACEHOLDER = re.compile(r"itemID\s*=\s*(\d+)")

# 用于解析 itemID 的正则
RE_ITEM_LINK = re.compile(r"/item=(\d+)")
RE_DATA_ITEM = re.compile(r"data-tooltip-item=['\"]?(\d+)['\"]?")

def make_driver(headless=True):
    opts = webdriver.ChromeOptions()
    if headless:
        opts.add_argument("--headless=new")
    opts.add_argument("--disable-gpu")
    opts.add_argument("--no-sandbox")
    opts.add_argument("--lang=en-US")
    # 模拟真实浏览器，防止被拦截
    opts.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                      "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36")
    
    # 增加连接超时设置
    opts.add_experimental_option("excludeSwitches", ["enable-automation"])
    opts.add_experimental_option('useAutomationExtension', False)
    
    service = Service(ChromeDriverManager().install())
    driver = webdriver.Chrome(service=service, options=opts)
    
    # 设置全局超时
    driver.set_page_load_timeout(30)
    return driver

# 修改：添加了URL重试机制
def fetch_item_ids_for_spell(driver, spell_id: int, locale="cn", wait_seconds=5):
    urls = []
    if locale == "cn":
        urls.append(f"https://www.wowhead.com/cn/spell={spell_id}")
        urls.append(f"https://m.wowhead.com/cn/spell={spell_id}")
    urls.append(f"https://www.wowhead.com/spell={spell_id}")
    urls.append(f"https://m.wowhead.com/spell={spell_id}")

    found = set()
    for url in urls:
        # 重试 2 次
        for attempt in range(2):
            try:
                driver.get(url)
                # 等待页面加载关键元素
                WebDriverWait(driver, wait_seconds).until(
                    EC.presence_of_element_located((By.CSS_SELECTOR, "a[href*='/item=']"))
                )
                
                html = driver.page_source
                ids = parse_item_ids_from_html(html)
                for i in ids:
                    found.add(i)
                
                if found:
                    return sorted(list(found)) # 找到数据就返回
                
                break # 如果没找到但没报错，尝试下一个URL
            except Exception as e:
                print(f"   ! 尝试 {url} 失败 ({attempt+1}/2): {e}")
                time.sleep(2) # 等待一下再重试
                continue

    return sorted(list(found))

def parse_item_ids_from_html(html: str):
    soup = BeautifulSoup(html, "html.parser")
    ids = set()
    # 链接
    for a in soup.find_all("a", href=True):
        m = RE_ITEM_LINK.search(a["href"])
        if m:
            ids.add(int(m.group(1)))
    # data-tooltip-item 属性
    for tag in soup.find_all(attrs=True):
        for v in tag.attrs.values():
            if isinstance(v, str):
                m2 = RE_DATA_ITEM.search(v)
                if m2:
                    ids.add(int(m2.group(1)))
    # script 里匹配
    for m3 in RE_ITEM_LINK.finditer(html):
        ids.add(int(m3.group(1)))
    return sorted(list(ids))

def read_lua(filepath: str) -> str:
    with open(filepath, 'r', encoding='utf-8') as f:
        return f.read()

def write_lua(filepath: str, content: str):
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

# 修改：分批处理和自动备份逻辑
def process_data(lua_content: str, output_path: str, locale="cn"):
    # 找所有 spell
    matches = list(RE_SPELL_LINE.finditer(lua_content))
    total = len(matches)
    print(f"找到 {total} 个需要处理的 Spell 条目。")
    
    current_content = lua_content
    
    # 初始化驱动
    driver = make_driver(headless=True)
    
    try:
        for index, m in enumerate(matches):
            spell_id = int(m.group(1))
            body = m.group(2)
            
            print(f"[{index+1}/{total}] 查询 spell {spell_id} ...")
            
            # 使用现有驱动查询
            try:
                item_ids = fetch_item_ids_for_spell(driver, spell_id, locale=locale)
            except Exception as e:
                print(f"   !! 处理 spell {spell_id} 时发生未捕获异常: {e}")
                continue # 跳过这一个，继续下一个
            
            if item_ids:
                print(f" -> 找到 itemIDs: {item_ids}")
                new_item = item_ids[0]
                # 替换 itemID= old 值为新的
                def repl_item(match):
                    return f"itemID={new_item}"
                
                new_body = RE_ITEM_PLACEHOLDER.sub(repl_item, body, count=1)
                new_entry = f"[{spell_id}] = {{{new_body}}}"
                
                # 用最新内容进行替换，防止多次替换旧内容导致逻辑错误
                old_entry = m.group(0)
                current_content = current_content.replace(old_entry, new_entry)
            else:
                print(f" -> 没找到 itemID，跳过 spell {spell_id}")

            # --- 优化点：每 3 个备份一次 ---
            if (index + 1) % 3 == 0 or (index + 1) == total:
                print("--- 执行周期性备份 ---")
                write_lua(output_path, current_content)
                
    finally:
        driver.quit()
        print("浏览器已关闭。")

    return current_content

def main():
    p = argparse.ArgumentParser()
    p.add_argument("lua_file", help="路径到 data.lua")
    p.add_argument("--locale", default="cn", help="Wowhead 本地化站点 (cn 或 en)")
    p.add_argument("--backup", action="store_true", help="在开始前备份原 lua 文件")
    args = p.parse_args()

    if not os.path.exists(args.lua_file):
        print(f"错误: 文件 {args.lua_file} 不存在")
        return

    lua_text = read_lua(args.lua_file)
    
    if args.backup:
        bak_file = args.lua_file + ".bak"
        shutil.copy2(args.lua_file, bak_file)
        print(f"初始备份已创建: {bak_file}")

    # 直接写入文件
    process_data(lua_text, args.lua_file, locale=args.locale)
    
    print("全部任务完成。")

if __name__ == "__main__":
    main()