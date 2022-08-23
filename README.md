# AlfredTool
个人Alfred的工具合集



对于`Keyword`是输入`cmd xxx`后按enter才能触发.

 对于`XXX Filter`是输入时不停地调用脚本触发.



## Colors

颜色转换，参照[大神](https://github.com/TylerEich/Alfred-Extras)的代码和图标。去掉很多和本人使用不相关的代码，只保留个人习惯结果。

1. rgb

![image-20220330101911759](https://raw.githubusercontent.com/yingguqing/Other/master/images/typora/2022/03/upgit_30_1648606751_image-20220330101911759.png)

```
rgb 111,111,111
```


2. #

![image-20220330101947509](https://raw.githubusercontent.com/yingguqing/Other/master/images/typora/2022/03/upgit_30_1648606787_image-20220330101947509.png)

```
# 777777
```

3. 调起颜色选择工具选择颜色

![image-20220330102024242](https://raw.githubusercontent.com/yingguqing/Other/master/images/typora/2022/03/upgit_30_1648606824_image-20220330102024242.png)

## Timestamp

时间戳工具，可以把时间戳和北京时间互转。同时显示时间戳的秒和毫秒结果。

![image-20220330102104354](https://raw.githubusercontent.com/yingguqing/Other/master/images/typora/2022/03/upgit_30_1648606864_image-20220330102104354.png)

![image-20220330102132367](https://raw.githubusercontent.com/yingguqing/Other/master/images/typora/2022/03/upgit_30_1648606892_image-20220330102132367.png)

```
ts 1648545729
ts 2022-03-29 17:22:09
```

默认日期格式化样式：`YYYY-MM-dd HH:mm:ss`

1. 新增日期格式化样式

![image-20220330102156960](https://raw.githubusercontent.com/yingguqing/Other/master/images/typora/2022/03/upgit_30_1648606916_image-20220330102156960.png)

```
ts add YYYY-MM-dd HH:mm:ss
```

2. 删除日期格式化样式

![image-20220330102232094](https://raw.githubusercontent.com/yingguqing/Other/master/images/typora/2022/03/upgit_30_1648606971_image-20220330102232094.png)

```
ts remove YYYY-MM-dd HH:mm:ss
```



## QRCode

把输入内容生成二维码，同时显示出来

![image-20220330102317008](https://raw.githubusercontent.com/yingguqing/Other/master/images/typora/2022/03/upgit_30_1648606997_image-20220330102317008.png)

```
qr http://www.baidu.com
```



## Base64

1. Base64编码
2. Base64解码



## 其他工具

等待以后需要再扩展
