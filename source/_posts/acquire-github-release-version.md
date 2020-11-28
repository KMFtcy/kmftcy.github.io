---
title: 如何获取Github上最新的release版本
date: 2020-11-25 23:43:43
tags:
description: 一般下载 github 上的 release 文件的时候，我们都希望能拿到最新的版本。本文介绍一个通过curl获得release的最新版本的方法。
---

一般下载 github 上的 release 文件的时候，我们都希望能拿到最新的版本，这个事情用脚本去做好像就不是特别的方便。
在 cdr/code-server 提供的安装脚本上，我找到一个非常好用的通用解决方案,原来 GitHub 已经提供了这样的 api 接口,只需要去请求就可以获得版本信息。

以 code-server 为例，获取最新版本只需要三句 shell 脚本：

```shell
version="$(curl -fsSLI -o /dev/null -w "%{url_effective}" https://github.com/cdr/code-server/releases/latest)"
version="${version#https://github.com/cdr/code-server/releases/tag/}"
version="${version#v}"
```

对于其他项目，只需要替换“cdr/code-server”中的项目名即可，例如替换为“kubeedge/kubeedge”。
有了版本号，就可以按照 release 出来的命名规则进行指定版本的下载了。例如对于 code-server，命名规则为：

```shell
https://github.com/cdr/code-server/releases/download/v$version/code-server_${version}_$ARCH.deb
```

下载命令为：

```shell
curl -fOL https://github.com/cdr/code-server/releases/download/v$version/code-server_${version}_$ARCH.deb
```
