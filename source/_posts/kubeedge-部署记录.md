---
title: kubeedge 部署记录
date: 2020-11-22 21:37:41
tags:
---

## kubeedge 部署

### 使用 kubeadm 进行部署

> 几个值得注意的点：
>
> - 目前只支持 ubuntu 和 centos，并且不支持树莓派
> - 需要使用到 10000 和 10002 端口
> - kubeedge 分为云端和边端的部署

#### 准备工作

1. 在 Github release 中下载 keadm，目前仅需要下载这个组件就可以完成初始化流程。
2. 云端需要有一个可以使用的 kubernetes 集群。

#### 部署云端

1. 初始化云端设备 kubeedge 组件

```shell
keadm init --advertise-address="THE-EXPOSED-IP"(only work since 1.3 release)
```

默认情况下，使用的是本地的 ip。

在 1.3 之前的版本，还需要将初始化生成的证书手动拷贝到边端点上，目前最新版本已经更新到 1.5，实验所使用的是 1.4 版本，因此不需要执行这一步操作。

执行到这里，云端就已经初始化成功了，应该会看到有一个 cloudcore 进程正在节点中运行。

#### 部署边端

1. 执行命令，获取云端 token

```shell
keadm gettoken
```

输出一段 token，需要手动记住:

```shell
27a37ef16159f7d3be8fae95d588b79b3adaaf92727b72659eb89758c66ffda2.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1OTAyMTYwNzd9.JBj8LLYWXwbbvHKffJBpPd5CyxqapRQYDIXtFZErgYE
```

2. 执行命令，加入云端节点

```shell
keadm join --cloudcore-ipport=192.168.20.50:10000 --token=27a37ef16159f7d3be8fae95d588b79b3adaaf92727b72659eb89758c66ffda2.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1OTAyMTYwNzd9.JBj8LLYWXwbbvHKffJBpPd5CyxqapRQYDIXtFZErgYE
```

执行到这里，节点就已经顺利加入 kubeedge 中了，应该会看到有一个 edgecore 进程正在节点中运行。

### 手动部署

#### 准备工作

1. 从 GitHub release 上下载最新的 kubeedge 发行版和 keadm。注意只有 1.5 版本开始，kubeedge 的发行版的压缩包中才有 cloudcore，怀疑是负责人忘记放进去了。

   如果需要更老的版本，可以在网络好的环境运行：

```shell
keadm init
```

该命令会在当前目录下载好所有需要的压缩包和 yaml 文件。这时候下载的压缩包（从 aws 下载）就有完整的执行文件了。

2. 需要四个指定的 CRDs 的 yaml 文件，这个建议按上面说的方式下载。

#### 创建一些 CRDs

这几个 crd 是 kubeedge 使用的模型,需要预先加入 k8s 集群。显然是可以提前下载下来的。

```shell
kubectl apply -f https://raw.githubusercontent.com/kubeedge/kubeedge/master/build/crds/devices/devices_v1alpha2_device.yaml
kubectl apply -f https://raw.githubusercontent.com/kubeedge/kubeedge/master/build/crds/devices/devices_v1alpha2_devicemodel.yaml
kubectl apply -f https://raw.githubusercontent.com/kubeedge/kubeedge/master/build/crds/reliablesyncs/cluster_objectsync_v1alpha1.yaml
kubectl apply -f https://raw.githubusercontent.com/kubeedge/kubeedge/master/build/crds/reliablesyncs/objectsync_v1alpha1.yaml
```

#### 部署云端

1. 获得默认配置文件

```shell
cloudcore --minconfig > cloudcore.yaml
```

TODO: 具体的配置内容

2. 运行 cloudcore，建议后台运行并将输出重定向到 log 文件。

```shell
cloudcore --config cloudcore.yaml
```

#### 部署边端

1. 获得默认配置文件

```shell
edgecore --minconfig > edgecore.yaml
```

TODO: 具体的配置内容

2. 获得云端服务器的 token，该 token 已经被保存到 kubernetes 集群当中了。

```shell
kubectl get secret -nkubeedge tokensecret -o=jsonpath='{.data.tokendata}' | base64 -d
```

3. 将配置文件中的相关字段添加上 token

```shell
sed -i -e "s|token: .*|token: ${token}|g" edgecore.yaml
```

4. 运行边端进程

如果云端和边端为同一节点，则需要注明变量：

```shell
export CHECK_EDGECORE_ENVIRONMENT="false"
```

运行边端进程

```shell
edgecore --config edgecore.yaml
```
