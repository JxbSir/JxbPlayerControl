# JxbPlayerControl
A Mp3 Player Control. Support ServerUrl & LocolFile

#Code
``` object-c
JxbPlayer* jxb = [[JxbPlayer alloc] initWithMainColor:[UIColor redColor] frame:CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width, 100)];

jxb.itemUrl = @"http://stream.51voa.com/201506/se-health-south-korea-mers-15jun15.mp3";
    
[self.view addSubview:jxb];
```     

#For Example
![](https://raw.githubusercontent.com/JxbSir/JxbPlayerControl/master/screenshot.gif)
