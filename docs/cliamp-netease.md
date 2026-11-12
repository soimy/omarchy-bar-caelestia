# cliamp × 网易云音乐 接入说明

本机（Omarchy / Hyprland）把 cliamp 接进网易云音乐的完整方案与踩坑记录。
**本文不含任何密钥**：API 凭据由 ncm-cli 自行加密存放在
`~/.config/ncm-cli/credentials.enc.json`（0600）。

## 两条腿，别混淆

| 路径 | 认证方式 | 能做什么 | 用得到 API key 吗 |
|---|---|---|---|
| cliamp 原生 `netease` provider | 浏览器 cookie（`cookies_from`） | 在 cliamp 里浏览歌单/红心/排行榜、`Ctrl+F` 搜索、播放 | ❌ 不读 appId/privateKey |
| ncm-cli 桥接插件 | 开放平台 appId + privateKey | 官方 API 搜索，结果排进 cliamp 播放 | ✅ |

> cliamp 的 `[netease]` 段只认 `enabled` / `cookies_from` / `user_id` 三个键，
> 官方开放平台的 appId/privateKey 进不了这条路径——这是架构限制，不是配置问题。

## 已落地的内容

### 1. ncm-cli（官方开放平台）

```bash
npm install -g @music163/ncm-cli
ncm-cli config set appId <AppId>
ncm-cli config set privateKey <PrivateKey>
ncm-cli config set player mpv
ncm-cli login --background      # 输出一个 163cn.tv 短链，手机网易云 App 里确认
ncm-cli login --check           # → "已登录实名账号"
```

- 命令树分静态 + 动态两部分：`search` / `playlist` / `user` 等**登录后**才注册，
  未登录时执行会报 `unknown command 'search'`。参数一律以 `ncm-cli <cmd> --help` 为准。
- `play` 需要成对的 `--encrypted-id`（32 位 hex，API 用）与 `--original-id`（明文数字，唤起客户端用）。

### 2. cliamp 原生 NetEase provider

```toml
# ~/.config/cliamp/config.toml
[netease]
enabled = true
cookies_from = "chrome+gnomekeyring"
```

**关键坑：`+gnomekeyring` 不能省。**
yt-dlp 靠 `XDG_CURRENT_DESKTOP` 猜桌面环境来决定用哪个密钥环，而它不认识
`Hyprland`，会退化成 `BASICTEXT`，于是：

```
[debug] detected desktop environment: OTHER
[debug] Chosen keyring: BASICTEXT
WARNING: cannot decrypt v11 cookies: no key found
Extracted 0 cookies from chrome (370 could not be decrypted)
```

显式写 `chrome+gnomekeyring` 后：

```
[debug] Chosen keyring: GNOMEKEYRING
Extracted 365 cookies from chrome
```

另外 yt-dlp 需要 `secretstorage` 才能读 gnome-keyring；系统 python 是
PEP 668 管控的，因此装在用户目录（`~/.local/lib/python3.14/site-packages`）：

```bash
python3 -m pip install --user --break-system-packages --no-deps secretstorage jeepney
```

启动与切换：

```bash
cliamp --provider netease      # 本次直接进网易云
# 或在 TUI 里按 M 打开 NetEase provider
```

默认 provider 仍是 `radio`；想让 cliamp 开机直进网易云，在 config.toml 顶层加
`provider = "netease"`。

### 3. 桥接插件：ncm-cli → cliamp

- 插件：`~/.config/cliamp/plugins/ncm.lua`
- 快捷脚本：`~/.local/bin/ncmq`

```bash
ncmq search "关键词"        # 官方 API 搜索，带网易云链接，标注不可播放项
ncmq play   "关键词"        # 搜索结果排进 cliamp 队列并开播
ncmq tui                   # ncm-cli 自带 TUI 播放器
```

播放路径：`歌曲页 URL → cliamp.queue.add → yt-dlp 解析成音频流`。
插件权限为 `control`（改队列）+ `exec`（仅白名单里的 `ncm-cli`），
信任指纹记录在 `plugins/.trust.json`；**改动插件文件后哈希变化，需要重新
`cliamp plugins trust ncm`**。

**第二个坑：`cliamp.sleep()` 会阻塞插件 Lua VM。**
exec 的 `on_stdout` / `on_exit` 回调在此期间无法投递，所以「起进程 + 空转等待」
的同步写法必然超时。正确做法是命令立即返回，全部解析/入队逻辑放进 `on_exit`，
等待用 `cliamp.timer.after()` 做非阻塞重试。

## 验证方式

```bash
ncm-cli login --check                    # 登录态
ncmq search "关键词"                      # 官方 API 通路
cliamp status --json                     # 播放状态
tmux new -d -s t 'cliamp --provider netease' && tmux capture-pane -pt t   # 看 provider 是否列出歌单
```

排障看两处日志：

```bash
tail -f ~/.config/cliamp/plugins.log     # 插件的 exec/解析/入队
tail -f ~/.config/cliamp/cliamp.log      # cliamp 本体
```

## 已知限制

- 仅 cliamp 原生 provider 能在 cliamp 内**浏览歌单**，且依赖浏览器登录态；
  桥接插件只能「搜索 → 排队播放」。
- 桥接播放依赖 yt-dlp 解析歌曲页：VIP / 独家版权曲目可能失败，受账号、地区、
  版权约束。搜索结果的 `visible=false` 会被插件直接过滤。
- ncm-cli 走官方开放平台，与 cliamp 的 cookie 会话是两套独立凭据，互不共享。
- 只有一条 cliamp 实例能持有 `~/.config/cliamp/cliamp.sock`；改 `config.toml`
  前先退出 cliamp，否则退出时会用内存里的配置回写覆盖。

## 回滚

```bash
rm ~/.config/cliamp/plugins/ncm.lua ~/.local/bin/ncmq
# 从 config.toml 删掉 [netease] 与 [plugins] 两段（备份见 config.toml.bak.*）
npm uninstall -g @music163/ncm-cli && rm -rf ~/.config/ncm-cli
```
