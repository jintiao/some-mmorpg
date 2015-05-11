# 前言

学习[skynet](https://github.com/cloudwu/skynet)时撸出来的简单服务器，欢迎吐槽。

完成度很低，已实现功能有：
* 登陆
* 角色创建
* 地图内移动
* 攻击
* aoi

# 编译及安装

## 编译依赖

### 3rd/openssl 
程序中用到了openssl中的crypto库，请将crypto编译成**静态库**。 [参考文档](https://wiki.openssl.org/index.php/Compilation_and_Installation)。  
对于64linux系统，可尝试用命令 "./Configure linux-x86_64 no-shared -fPIC; make"进行编译。   
如果编译出错，请自行google解决。

### 3rd/skynet
[参考文档](https://github.com/cloudwu/skynet)。

## 安装
1. 先安装redis
2. 执行 tool/setup/setup 脚本，它会在项目根目录下创建一个var目录，创建好数据库需要的文件和管理脚本。

## 运行
1. 运行 var/redis-start 脚本，启动好对应的数据库实例。
2. 运行 server/run 脚本，启动服务器程序。

# 客户端

供测试用的客户端在 client 目录通过命令 “lua client.lua”或者脚本 “./run” 运行。

client.lua 接受用户名、密码作为命令行参数 “lua client.lua username password”，如果留空，则由程序自动生成一个用户名，保存在本地 anonymous 文件中。

client.lua 会自动完成登陆相关的流程，然后等待用户输入。

用户输入以回车结束，输入内容将打包发送至服务器。
输入的格式为 “命令 参数”，全部命令请参考 common/proto/game_proto.lua 文件中的 game_proto.c2s

一个常见的client命令流程是这样的：

```lua
cd client
./run
character_create character = { name = “hello”, race = “human”, class = “warrior” }
character_list
character_pick id = 4
map_ready
move pos = { x = 123, z = 321 }
combat target = 7
```

# 其他

详细说明请移步 [wiki](https://github.com/jintiao/some-mmorpg/wiki)
