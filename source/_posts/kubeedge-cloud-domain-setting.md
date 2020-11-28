---
title: kubeedge使用域名配置cloud地址
date: 2020-11-25 23:50:41
tags:
description: 在设置中代替ip，使用域名作为cloud地址配置。
---

kubeedge 的文档中，使用 keadm 进行 init 和 join 操作所对应的地址都是 ip 地址。但是实际使用当中，反倒不可能直接将 ip 地址暴露出来，而是 domain 的使用情况更多。但是文档中并没有介绍到使用域名作为地址的方法。

经过简单实验，发现域名的配置很简单。这里做简单的记录:

1. 生成证书
2. 将证书拷贝到各个节点的/etc/kubeedge 目录
3. 配置文件中记住配对对应的文件位置
4. 手动起 cloudcore 和 edgecore

TODO: 补充文件细节
