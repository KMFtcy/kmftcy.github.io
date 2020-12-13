---
title: cobra
date: 2020-12-10 23:33:54
tags: [golang]
description:
---

cobra 是 golang 一个用于构建命令行程序的开源库，它提供了对于构建命令行程序非常多的便利特性。例如命令行参数、子命令、自动生成帮助文档等。
最近刚好在编写一个命令行程序，总结一些使用过程中的实践。

## 创建一个命令实例。

```golang
cmd := &cobra.Command{
    Use:   "test",
    Short: "Print the version number of cobrademo",
    Long:  `All software has versions. This is cobrademo's`,
    Run: func(cmd *cobra.Command, args []string) {
        run()
    },
}

func run(){
    fmt.Println("Running")
}
```

一个命令实例是指被使用的命令行程序，当使用命令"ls"的时候，是在使用 ls 这个命令行程序， 当使用命令"ls | grep target"的时候，就使用了 ls 和 grep 两个命令行程序。

创建的过程中有若干个比较重要的参数：

1. Use

Use 指的是使用该命令行程序的入口命令，当编译的程序为 hello.out，使用例子中的命令行程序的入口就是

```shell
hello.out test
```

如果不特别指定 Use 属性的话，那么默认的入口就是编译程序本身

```shell
hello.out
```

1. Run

Run 属性指定了程序运行的时候运行的函数入口,传入的接口实例要实现以下接口：

```golang
func(cmd *cobra.Command, args []string) {
}
```

其中\*cobra.Command 是指命令实例本身，args 是指传入该命令行程序的参数。

3. Short

命令行程序的短说明,当使用-h 的时候可以看到该说明和参数的相关说明。

4. Long

命令行程序的长说明。

## 定义参数

调用 cmd 实例提供的接口来传入命令行程序的参数和承接的变量。

```golang
cmd.Flags().StringVarP(&config.ConfigFilePath, "config", "c", config.DEFAULT_CONFIG_PATH, "path to config file")
```

除了 StringVarP,还有 Bool、Float、Time 等参数类型,可以很方便地接受参数。

不仅如此，还能给参数配置：

1. 长短选项，例如"-c","--config";
2. 配置默认值。
3. 配置帮助说明。

## 添加子命令

在使用命令行程序的时候，还可能会调用一些子命令，这些命令和参数不一样，会带来不同的行为。
例如以下几个调用：

```shell
kubectl create
kubectl apply
kubectl get
```

添加子命令之前，我们需要提前创建一个命令行实例，注意该实例一定要实现指定 Use 属性。

```golang
testCmd := &cobra.Command{
    Use:   "version",
    Short: "Print the version number of cobrademo",
    Long:  `All software has versions. This is cobrademo's`,
    Run: func(cmd *cobra.Command, args []string) {
        fmt.Println(config.ConfigFilePath)
    },
}
```

在这之后，将该实例添加进我们命令行程序的管辖。

```golang
cmd.AddCommand(testCmd)
```

调用的时候指定子程序就好了

```shell
hello.out version
```

## 定义帮助文档

帮助文档在定义好程序和参数的时候就会自动生成好了，这也是 cobra 一个让人喜爱的特性。
