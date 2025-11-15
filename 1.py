#!/usr/bin/env python3
# fill_spell_item.py

import re
import argparse
import time
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
    opts.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                      "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36")
    service = Service(ChromeDriverManager().install())
    driver = webdriver.Chrome(service=service, options=opts)
    return driver

def fetch_item_ids_for_spell(spell_id: int, locale="cn", wait_seconds=8):
    driver = make_driver(headless=True)
    urls = []
    if locale == "cn":
        urls.append(f"https://www.wowhead.com/cn/spell={spell_id}")
        urls.append(f"https://m.wowhead.com/cn/spell={spell_id}")
    urls.append(f"https://www.wowhead.com/spell={spell_id}")
    urls.append(f"https://m.wowhead.com/spell={spell_id}")

    found = set()
    try:
        for url in urls:
            driver.get(url)
            try:
                WebDriverWait(driver, wait_seconds).until(
                    EC.presence_of_element_located((By.CSS_SELECTOR, "a[href*='/item=']"))
                )
                time.sleep(0.5)
            except Exception:
                pass
            html = driver.page_source
            ids = parse_item_ids_from_html(html)
            for i in ids:
                found.add(i)
            if found:
                break
    finally:
        driver.quit()
    return sorted(found)

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
    return sorted(ids)

def read_lua(filepath: str) -> str:
    with open(filepath, 'r', encoding='utf-8') as f:
        return f.read()

def write_lua(filepath: str, content: str):
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

def process_data(lua_content: str, locale="cn"):
    # 找所有 spell
    matches = RE_SPELL_LINE.finditer(lua_content)
    new_content = lua_content
    for m in matches:
        spell_id = int(m.group(1))
        body = m.group(2)  # 例如 " itemID=0, versionID=0, source=0 "
        # 查询 itemIDs
        print(f"查询 spell {spell_id} ...")
        item_ids = fetch_item_ids_for_spell(spell_id, locale=locale)
        print(f" -> 找到 itemIDs: {item_ids}")
        if item_ids:
            # 这里假设我们只填第一个 itemID
            new_item = item_ids[0]
            # 替换 itemID= old 值为新的
            def repl_item(match):
                return f"itemID={new_item}"
            new_body = RE_ITEM_PLACEHOLDER.sub(repl_item, body, count=1)
            # 构建新的条目字符串
            new_entry = f"[{spell_id}] = {{{new_body}}}"
            # 用原 match 替换
            old_entry = m.group(0)  # 包括方括号和 body
            new_content = new_content.replace(old_entry, new_entry)
        else:
            print(f" 没找到 itemID，跳过 spell {spell_id}")

    return new_content

def main():
    p = argparse.ArgumentParser()
    p.add_argument("lua_file", help="路径到 data.lua")
    p.add_argument("--locale", default="cn", help="Wowhead 本地化站点 (cn 或 en)")
    p.add_argument("--backup", action="store_true", help="备份原 lua 文件")
    args = p.parse_args()

    lua_text = read_lua(args.lua_file)
    if args.backup:
        write_lua(args.lua_file + ".bak", lua_text)
        print(f"备份已写: {args.lua_file}.bak")

    new_text = process_data(lua_text, locale=args.locale)
    write_lua(args.lua_file, new_text)
    print("已写回:", args.lua_file)

if __name__ == "__main__":
    main()
