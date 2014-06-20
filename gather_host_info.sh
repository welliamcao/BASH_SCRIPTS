#!/bin/bash
#@create by welliam.cao 303350019@qq.com 2014/06/20
EMAIL_FROM='xxxx@qq.com'
EMAIL_SMTP='smtp.qq.com'
EMAIL_PASSWD='xxx'
EMAIL_ACCOUT='xxxxx'
OUTPUT_FILE=/tmp/output.$$
#use for get system version and kernel information
get_host_info_soft(){
echo -e "==================== Host soft infomation =====================" >> ${OUTPUT_FILE}
echo -e "Host_name: $(hostname)" >> ${OUTPUT_FILE}
echo -e "Soft System: $(cat /etc/issue|sed -ne '1p')" >> ${OUTPUT_FILE}
echo -e "Linux kernel versions: $(uname -na|awk '{print$3}')" >> ${OUTPUT_FILE}
echo -e "Uptime:$(uptime |awk -F',' '{print$1}')" >> ${OUTPUT_FILE}
echo -e "\n" >> ${OUTPUT_FILE}
}
#use for get the network card information
get_host_info_net(){
echo -e "===================== Network infomation =====================" >> ${OUTPUT_FILE}
ifconfig |awk  'BEGIN{RS=""}/HWaddr/&&$7~/addr/{gsub(/:/,"-",$5);gsub(/inet/,"\tIP",$6);gsub(/:/,": ",$7);print$1"\t"$4":",$5"\n"$6,$7}' >> ${OUTPUT_FILE}
echo -e "\n" >> ${OUTPUT_FILE}
}
#use for get system accout information
get_host_info_accout(){
echo -e "====================== Accout infomation =====================" >> ${OUTPUT_FILE}
awk -F':' 'BEGIN{print"The accout who can login in the system:"}!/(nologin|shutdown|sync|halt)/{print$1"\t"$6}' /etc/passwd >> ${OUTPUT_FILE}
who|awk -F'[)( ]+' 'BEGIN{print"\nCurrent login user:"}/pts/{print$1"\t"$5}'  >> ${OUTPUT_FILE}
echo -e "\n" >> ${OUTPUT_FILE}
echo -e "Login failed IPAddress." >> ${OUTPUT_FILE}
ipinfo=($(awk 'BEGIN{ORS=" "}/Failed password/{a[$11]++}END{for(x in a)if(a[x]>3)print x}' /var/log/secure))
for ip in ${ipinfo[*]}
   do
    if [[ ${ip} != 192.168.*.*  ]] && [[ ${ip} != 172.16.*.*  ]] && [[ ${ip} != 10.*.*.*  ]]
       then
          ipzone=$(curl  -s --user-agent "[Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; TencentTraveler 4.0)]"  http://ip.qq.com/cgi-bin/searchip?searchip1=${ip}|grep '<p>'|iconv -f gb2312 -t utf-8|grep -oP '(?<=n>).*(?=</sp)'|sed 's/&nbsp;/ /g')
          echo "${ip}:  ${ipzone}"  >> ${OUTPUT_FILE}
       else
          echo "Local area network: ${ip}" >> ${OUTPUT_FILE}
    fi
done
echo -e "\n"
}

#use for get machine information.
get_host_info_hardware(){
if [[ $(rpm -qa|grep dmidecode|wc -l) -gt 0 ]]
  then
    echo -e "=================== Hardware infomation ===================" >> ${OUTPUT_FILE}
    echo  -e "-------------------- CPU INFOMATION -------------------" >> ${OUTPUT_FILE}
    awk -F':' '/model name/&&!a[$0]++{print"CPU model:"$2}' /proc/cpuinfo >> ${OUTPUT_FILE}
    echo -e "CPU physical number: $(grep 'physical id' /proc/cpuinfo|uniq |wc -l)" >> ${OUTPUT_FILE}
    echo -e "CPU core number: $(grep 'core id' /proc/cpuinfo | sort -u | wc -l)" >> ${OUTPUT_FILE}
    echo -e "CPU thread number: $(grep 'processor' /proc/cpuinfo | sort -u | wc -l)" >> ${OUTPUT_FILE}
    echo -e "Whether to support virtualization ?"  >> ${OUTPUT_FILE}
    if [[ $(grep -E "(vmx|svm)" /proc/cpuinfo |wc -l) -gt 0 ]] >> ${OUTPUT_FILE}
        then
            echo -e "Virtualization support." >> ${OUTPUT_FILE}
        else
            echo -e "Don't support Virtualization." >> ${OUTPUT_FILE}
    fi
    echo -e "-------------------- MEM INFOMATION -------------------" >> ${OUTPUT_FILE} 
    dmidecode |grep -A5  "Memory Device$" |awk  '$0~/Size: [0-9]+/{a[$2]++;sum+=$2}END{for(x in a)print a[x]" pieces of",x" MB memory";print "Total of "sum" MB"}' >> ${OUTPUT_FILE}
    free -m|awk 'NR==2{sum=$4+$6+$7;used=$3-$6-$7;print "Free_mem: " sum"M""\n""Used_mem: "used"M"}' >> ${OUTPUT_FILE}
    echo -e "\n" >> ${OUTPUT_FILE}
    echo -e "------------------- DISK INFOMATION - -----------------" >> ${OUTPUT_FILE}
    echo "Disk list:" >> ${OUTPUT_FILE}
    fdisk -l|awk -F',' '/Disk \/dev/{gsub(/Disk /,"",$1);print$1}' >> ${OUTPUT_FILE}
    echo -e "Partition of Disk:" >> ${OUTPUT_FILE}
    df -lh >> ${OUTPUT_FILE}
    echo -e "\n" >> ${OUTPUT_FILE}
    echo -e "------------------- MACHINE INFOMATION -----------------" >> ${OUTPUT_FILE}
    dmidecode | grep "Product Name" |awk -F':' 'NR==1{print"Machine model: "$2}'  >> ${OUTPUT_FILE}
    dmidecode | grep "Product Name" |awk -F':' 'NR==2{print"Machine serial number: "$2}' >> ${OUTPUT_FILE}
    echo -e "\n" >> ${OUTPUT_FILE}
   else
       echo "your need yum install dmidecode." 
fi
}

send_email(){
cat > sendEmail.py << END
#/usr/bin/python
# -*- coding=utf-8 -*-
import smtplib
from email.mime.text import MIMEText
import time,datetime

f = open("${OUTPUT_FILE}",'r')
mail_from = "${EMAIL_FROM}"
mail_to = ["${OPTARG}"]
contents = f.readlines()
mail_host = "${EMAIL_SMTP}"
mail_accout = "${EMAIL_ACCOUT}"
mail_passwd = "${EMAIL_PASSWD}"
f.close()
mail_body = ''
for str in contents:
    mail_body = mail_body  + str

#use for send email
def sendEmail(e_from,e_to,e_content):
    msg=MIMEText(e_content,_subtype='plain',_charset='utf-8')
    msg['Subject']="$(hostname)'s report-$(date +'%Y%m%d%H%M')."
    msg['From']= e_from
    msg['To']=';'.join(e_to)
    msg['date']=time.strftime('%Y %H:%M:%S %z')
    smtp=smtplib.SMTP()
    smtp.connect(mail_host)
    smtp.login(mail_accout,mail_passwd)
    smtp.sendmail(e_from,e_to,msg.as_string())
    smtp.quit()
sendEmail(mail_from,mail_to,mail_body)
END
#cat sendEmail.py
python sendEmail.py
rm -rf sendEmail.py
}

get_host_info(){
case ${OPTARG} in
    hardware)
       get_host_info_hardware
       cat ${OUTPUT_FILE}
     ;;
    soft)
       get_host_info_soft
       cat ${OUTPUT_FILE}
     ;;
    network)
       get_host_info_net
       cat ${OUTPUT_FILE}
     ;; 
    secure)
       get_host_info_accout
       cat ${OUTPUT_FILE}
     ;;
    all)
      get_host_info_hardware
      get_host_info_soft
      get_host_info_net
      get_host_info_accout
      cat ${OUTPUT_FILE}
     ;;
    *)
     usage
     exit 1
    ;;
esac


}

usage(){
echo -e "Uage:"
echo -e "  -c   network         Check the host network information."
echo -e "  -c   secure          Check the host secure information."
echo -e "  -c   hardware        Check the host hardware information."
echo -e "  -c   soft            Check the host soft information."
echo -e "  -c   all             Check the host all of information."
echo -e "  -e   EMAILADDRESS    Send host report to your email."
echo -e "Example:"
echo -e " 1 ${0} -c all "
echo -e " 2 ${0} -e 303350019@qq.com."
echo -e " 2 ${0} -c all -e 303350019@qq.com."
}
if [[ -z ${1} ]]
  then
     usage
  else
        while getopts ":c:e:" arg 
          do
            case $arg in
                c)
                   get_host_info
                   ;;
                e)
                   send_email
                   ;;
                *)
                usage
                exit 1
                ;;
            esac
     done
fi
rm -rf /tmp/output.$$