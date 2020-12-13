---
title: viper
date: 2020-12-10 23:34:02
tags: [golang]
description:
---

viper 是 golang 中专门用于管理程序配置的第三方开源库。

有趣的是，viper 的作者就是 cobra 的作者，二者都是毒蛇的名字，"它们就是朋友"，作者这么说的。

这里总结一些使用 viper 的实践。

## 读取和设置配置

viper 可以 JSON、YAML、TOML, HCL, envfile 和 Java properties 配置文件。
通过以下语句可以设置配置文件路径和读取配置：

```golang
viper.SetConfigFile(ConfigFilePath)

if err := viper.ReadInConfig(); err != nil {
    panic(fmt.Errorf("Fatal error reading config file: %s", err))
}
```

也可以通过接口配置默认值：

```golang
viper.SetDefault("log.path", DEFAULT_LOG_PATH)
```

如果在程序过程中需要更改配置，也可以通过 Set 接口：

```golang
viper.Set("verbose", true) // same result as next line
viper.Set("loud", true)   // same result as prior line
```

## 获取配置

viper 提供了接口可以获取读取到的配置:

```golang
viper.Get("name") // this would be "steve"
```

但是使用 viper 的读取方式，不是每个组件都希望引入 viper 的情况下，就不是很合适。
一般来说，我们的项目会有 config 的 struct 供所有组件使用，而 viper 可以将读取到的配置解读到 struct 当中：

```golang
if err := viper.Unmarshal(&AppConfig); err != nil {
    panic(fmt.Errorf("Fatal error convert config file: %s", err))
}
```

## 和命令行参数的结合

命令行也可能传入配置，但是 viper 似乎并没有提供特别好的与命令行接入的接口。就连出自同一个作者之手的 cobra，也没有特别好的传入参数的方法，

官方提供了绑定 pflag 的方式，但是我还没有找到能和 cobra 很好结合的方法：

```golang
pflag.Int("flagname", 1234, "help message for flagname")

pflag.Parse()
viper.BindPFlags(pflag.CommandLine)

i := viper.GetInt("flagname") // retrieve values from viper instead of pflag
```

对于 cobra，现在最好的方式是使用 Set 接口进行设置，或者是共同读入一个 config struct。

## 监听配置变更

viper 一个感觉会相当有用的 feature，就是能动态读取配置文件的更改然后更新。

监控方式如下：

```golang
viper.WatchConfig()
viper.OnConfigChange(func(e fsnotify.Event) {
	fmt.Println("Config file changed:", e.Name)
})
```

注意，在 WatchConfig 以后设置的配置文件路径，都没有办法监控，所以要保证该方法在设置最后。
