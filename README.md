# Gold Bar

macOS 状态栏现货黄金价格显示工具，每 5 秒从 Swissquote 获取 XAU/USD 报价。

## 使用方法

```bash
# 编译
make

# 编译并运行
make run

# 打包为 .app（可拖入启动台/Applications）
make app
open StockBar.app

# 安装到系统路径
make install
```

## 功能

状态栏显示 `XAU $4227.50`，点击弹出菜单：

```
Bid:    $4227.xx
Ask:    $4229.xx
Spread: $2.xx
Updated: 14:58:32
─────────────────
立即刷新        ⌘R
─────────────────
退出            ⌘Q
```

- 每 5 秒自动刷新，网络异常显示 `XAU ⚠`
- 不占 Dock 位置，纯原生 Cocoa，无第三方依赖

## 环境要求

- macOS 15，Intel x64
- Xcode Command Line Tools（`xcode-select --install`）
