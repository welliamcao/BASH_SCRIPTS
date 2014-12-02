###SHELL写的一些脚本
* gather_host_info.sh  用来收集服务器信息，并且可以发送邮件
* sshMonitor  以linux守护进程的方式，将ssh连续三次登入失败的IP，拒绝掉。
 
## gather_host_info.sh使用方法
* chmod +x gather_host_info.sh  
* ./gather_host_info.sh 

## sshMonitor使用方法
* chmod +x sshMonitor
* cp sshMonitor /etc/init.d/
* service sshMonitor {start|stop|restart} 
