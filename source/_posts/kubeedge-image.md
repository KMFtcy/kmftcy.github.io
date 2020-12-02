---
title: kubeedge 两个重要组件镜像制作
date: 2020-12-01 20:26:45
tags:
description:
---

将 kubeedge 放入容器当中，这件事听起来就像在 container 里面使用 docker 一样有些错位。

可能有些人会说，这不就像是 kubernetes 一样，把组件容器化嘛,像是 apiserver、controller 都是以容器形式提供服务的。但是 kubeedge 组件的身份更像是 kubelet，以一个进程的身份调用接口、拉起容器，而不知道是什么原因 kubernetes 并没有把这个组件也同样给容器化了。

虽然 kubernetes 没有带这个头，但是这件事实际上是完全可行的，需要什么接口，就把什么接口挂进容器，需要什么程序，在容器里准备好就好了。今天进行了一下尝试，最终成功了，这里记录一下过程和一些可能踩坑的点。

### 镜像制作

官方实际上已经有自己的镜像了，但是这个镜像上次更新竟然是在一年前，几乎差了三个版本！实在是不敢用，更不敢直接投入到生产当中.如果翻翻源代码，可以找到官方自己使用的 dockerfile。
cloud 镜像 dockerfile:

```url
https://github.com/kubeedge/kubeedge/blob/master/build/cloud/Dockerfile
```

edge 镜像 dockerfile：

```url
https://github.com/kubeedge/kubeedge/blob/master/build/edge/Dockerfile
```

思路很简单啊，就是克隆一份代码完了以后自己编译一份。但是你在国内的话这个过程就很难受了，第一网络条件不好，每次克隆那个进度条都爬得要死要活的，第二是现在没有什么好的 arm 机器能用（Apple m1 除外），一般都是用树莓派一类的吧？这个要是用来编译，估计每次打镜像要像过节一样，一过好几天。既然这样那就自己编一份吧，看思路也不难呀，我们就本地下一份 release，然后每次编本地 COPY 一下就行。

举个例子，把下载好的 edgecore 或者 cloudcore 放在编译目录下：

```Dockerfile
ARG edgecore_path=edgecore

From ubuntu
COPY ${edgecore_path} /usr/local/bin
RUN apt update -y
RUN apt install iptables -y

ENTRYPOINT ["edgecore","--config","/etc/kubeedge/config/edgecore.yaml"]
```

几分钟就编好了，节约时间就是拯救生命。

### cloudcore 容器运行

cloudcore 容器运行出乎意料地简单，只要注意两点就可以了：

1. 把 10000、10001、10002 端口开放出来，这几个端口是 cloudcore 提供服务的。当然也可以自己指定，自己指定的开放对应端口就好了，都在 cloudcore.yaml 里面写得明明白白的。
2. 把本机 kubernetes 集群的 admin.conf——一般已经复制成~/.kube/config 了——挂到容器的~/.kube 目录下面。

完事，复制粘贴都没这么容易的。
这是我最终可以运行的 docker 命令:

```shell
docker run -d -v /etc/kubeedge/:/etc/kubeedge/ \
-v /root/.kube/:/root/.kube \
-p 10000:10000 \
-p 10001:10001 \
-p 10002:10002 \
${IMAGE_NAME}
```

### edgecore 容器运行

edgecore 容器的运行没有 cloudcore 那么顺利，遇到了不少问题，所幸还是解决了：

1. iptables 是 edgecore 必须用到的，这个软件同时还会使用一些其他的库，直接挂进去还不能直接用，索性直接 install 了。同时在容器当中，好像是需要特权模式才可以操作 iptables 的，因此在 docker run 的时候需要加上--privilege=true 选项。这个可能后续需要更多的研究，看看 edgecore 是操作了 iptables 还是仅仅获得一些 iptables 而已。
2. edgecore 是需要操作 docker 的，因此需要将机器上的 docker 套接字/var/run/docker.sock 挂载到我们的 edgecore 容器当中。

   ```shell
   docker run -v /var/run/docker.sock:/var/run/docker.sock
   ```

   （#TODO）我注意到在 edgecore.yaml 配置文件中，是可以选择挂载 dockershim.sock 来指定 gRPC 接口的。但是挂载本机的/var/run/dockershim.sock 进去以后运行 edgecore 发现一直在超时，暂时不知道原因。

   不过就算不挂载 dockershim 进入容器里面，edgecore 也是能正常使用的，并且顺利拉起了 kubeedge pause。

3. 运行的时候在 websock 组件一度遇到了 nil pointer 的奇怪报错：

   ```bash
   I1201 07:48:05.481873     336 websocket.go:51] Websocket start to connect Access
   panic: runtime error: invalid memory address or nil pointer dereference
   [signal SIGSEGV: segmentation violation code=0x1 addr=0x0 pc=0x2827dd4]
   goroutine 102 [running]:
   net.(*TCPListener).Addr(...)
   /root/.gvm/gos/go1.14/src/net/tcpsock.go:283
   github.com/kubeedge/kubeedge/edgemesh/pkg/proxy.Init()
   /root/codes/src/github.com/kubeedge/kubeedge/edgemesh/pkg/proxy/proxy.go:45 +0x54
   github.com/kubeedge/kubeedge/edgemesh/pkg.(*EdgeMesh).Start(0x40004605e8)
   /root/codes/src/github.com/kubeedge/kubeedge/edgemesh/pkg/module.go:51 +0x30
   created by github.com/kubeedge/beehive/pkg/core.StartModules
   /root/codes/src/github.com/kubeedge/kubeedge/vendor/github.com/kubeedge/beehive/pkg/core/core.go:23 +0x13c
   ```

   翻看了一下源代码，发现提示的那个 edgemesh 模块的 proxy.go 中的 init 方法读取到了 config 的一个配置：

   ```golang
   	proxier = &Proxier{
   	iptables:     iptInterface,
   	inboundRule:  "-p tcp -d " + config.Config.SubNet + " -i " + config.Config.ListenInterface + " -j " + meshChain,
   	outboundRule: "-p tcp -d " + config.Config.SubNet + " -o " + config.Config.ListenInterface + " -j " + meshChain,
   	dNatRule:     "-p tcp -j DNAT --to-destination " + config.Config.Listener.Addr().String(),
   }
   ```

   这个配置写在了 edgecore.yaml 的 edgeMesh 当中：

   ```yaml
   edgeMesh:
     enable: true
     lbStrategy: RoundRobin
     listenInterface: docker0
     listenPort: 40001
     subNet: 9.251.0.0/16
   ```

   显然启用 edgeMesh 需要读取本地的网卡，这个 mesh 不知道是什么时候开启的，应该是默认开启的，如果用 minconfig 生成最小配置文件反而没有这个选项了（v1.4.0）：

   ```shell
   edgecore --minconfig
   ```

   既然已经开启了那就用吧，把 network 换成 host 模式，就可以正常使用了。

如此这般以后，edgecore 就可以正常使用了。这里记录一下我最终可以运行的 docker 指令：

```shell
docker run -d -P \
--privileged=true \
--network=host \
-v /var/run/docker.sock:/var/var/run/docker.sock \
-v /var/lib/kubeedge:/var/lib/kubeedge \
-v /etc/kubeedge/:/etc/kubeedge \ #存放配置文件
${IMAGE_NAME}
```
