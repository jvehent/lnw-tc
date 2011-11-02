rrd=/var/lib/htb_collect/packet_sent.rrd

rrdtool graph packets_sent-1hour.png -s -1h \
-w 600 -h 200 \
-t "Sent packets for the last hour on $(hostname)" \
"DEF:interactive=$rrd:100:AVERAGE" \
'AREA:interactive#ffe400:interactive:STACK' \
'GPRINT:interactive:MAX:\tmax = %6.2lf%Sbps' \
'GPRINT:interactive:LAST:\tlast = %6.2lf%Sbps' \
'GPRINT:interactive:AVERAGE:\tavg = %6.2lf%Sbps\n' \
"DEF:tcp_acks=$rrd:200:AVERAGE" \
'AREA:tcp_acks#b535ff:tcp_acks:STACK' \
'GPRINT:tcp_acks:MAX:\tmax = %6.2lf%Sbps' \
'GPRINT:tcp_acks:LAST:\tlast = %6.2lf%Sbps' \
'GPRINT:tcp_acks:AVERAGE:\tavg = %6.2lf%Sbps\n' \
"DEF:ssh=$rrd:300:AVERAGE" \
'AREA:ssh#1b7b16:ssh:STACK' \
'GPRINT:ssh:MAX:\t\tmax = %6.2lf%Sbps' \
'GPRINT:ssh:LAST:\tlast = %6.2lf%Sbps' \
'GPRINT:ssh:AVERAGE:\tavg = %6.2lf%Sbps\n' \
"DEF:http_s=$rrd:400:AVERAGE" \
'AREA:http_s#ff0000:http_s:STACK' \
'GPRINT:http_s:MAX:\tmax = %6.2lf%Sbps' \
'GPRINT:http_s:LAST:\tlast = %6.2lf%Sbps' \
'GPRINT:http_s:AVERAGE:\tavg = %6.2lf%Sbps\n' \
"DEF:default=$rrd:999:AVERAGE" \
'AREA:default#bcdd94:default:STACK' \
'GPRINT:default:MAX:\tmax = %6.2lf%Sbps' \
'GPRINT:default:LAST:\tlast = %6.2lf%Sbps' \
'GPRINT:default:AVERAGE:\tavg = %6.2lf%Sbps\n'
