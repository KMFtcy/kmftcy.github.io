---
title: logrus
date: 2020-12-10 23:33:44
tags: [golang]
description:
---

logrus 是 golang 一个用于日志方面的开源库，在第一次使用以后，我就喜欢上了它的小巧和实用性。专心将一件事做好，logrus 也富有 unix 的气息。
而且 logrus 的接口还完全与 golang 自带的 log 库兼容，使得不使用 logrus 的程序转移在 logrus 上也几乎是无痛的。

这里总结一些使用 logrus 中的实践

## 日志实例的初始化

1. 创建 logger 实例

logger 对象负责日志的输出,创建的时候，我们可以借用 golang 中的 sync.Once 对象，帮助我们完成单例对象的创建。

```golang
singleton := sync.Once
var logger *logrus.Logger

singleton.Do(func() {
    logger = logrus.New()
})
```

2. 多目标输出

输出日志的时候，我们往往有多个输出目标：既需要在命令行输出提示，也需要保存在日志文件当中。
logger 对象可以设置一个 writer，我们可以借助 io.MultiWriter 对象实现这个功能。

```golang
// create log file
logFilePath := path.Join(config.AppConfig.Log.Path, config.AppConfig.Log.FileName)
fileWriter, err := os.OpenFile(logFilePath, os.O_WRONLY|os.O_CREATE|os.O_APPEND, 0755)
if err != nil {
    logger.Panicln("Fatal error open log file: %s", err)
}
// set log output
mw := io.MultiWriter(os.Stdout, fileWriter)
logger.SetOutput(mw)
```

这样就能实现多个输出的日志输出了

## 日志格式的初始化

logrus 提供了一个接口,用于设定日志输出的格式:

```golang
func (formatter *logFormatter) Format(entry *logrus.Entry) ([]byte, error) {}
```

只要是实现了这个接口的对象，都可以作为格式整理的对象,返回的 byte 数组就是日志内容。

logrus.Entry 对象包含了必要的日志信息，这里是我习惯用的日志格式定义：

```golang
timestamp := time.Now().Local().Format("2006/01/02 15:04:05")
msg := fmt.Sprintf("%s [%s] %s\n", timestamp, strings.ToUpper(entry.Level.String()), entry.Message)
return []byte(msg), nil
```

## 日志等级

logrus 分为多个日志等级:

- trace
- info
- debug
- warnings
- error
- fatal
- panic

这几个等级的优先级按从上到下的顺序排列。这样带来的好处是：

1. 可以设定日志输出的等级，在生产环境中可以不用输出太多的日志信息，影响 error 的定位和发现。
2. 在查找日志信息的时候，可以缩小查找日志范围，也同样能更好定位和发现问题。

同样，logger 对象有正对这几个等级的不同输出方式：

```golang
logger.Traceln()
logger.Infoln()
logger.Debugln()
logger.Warnln()
logger.Errorln()
logger.Fatalln()
logger.Panicln()
```

其中，Fatalln() 和 Panicln() 方法会在日志输出完成以后使程序以 Fatal（os.exit()） 或者 Panic 的方式退出。

我们可以在程序中轻易调节 logger 的输出等级：

```golang
// Only log the warning severity or above.
log.SetLevel(log.WarnLevel)
```

等级调整好以后，低于设定等级的日志信息就不会输出了。
