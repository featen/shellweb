# 用Shell脚本写HTTP服务器

如今想要部署一个HTTP服务器，可选择的项目可以填满整个太平洋，用什么语言写的都有，C，C++，Java，Golang...总之你能叫得出名字的语言都有无数的实现，有的性能好，有的开发起来糙快猛，有的扩展功能多，有的什么用都没有。

HTTP协议虽然在接入层逐渐开始被HTTP2和QUIC取代，但在内部服务中，HTTP/REST的服务数量还比其他RPC框架普及，比如gRPC和Thrift。2018年爆红的服务治理框架Istio，更是给HTTP协议带来了全套的服务治理能力。

说到服务治理，我用shell脚本写了一个HTTP服务器，文体两开花，弘扬脚本文化，希望大家多多支持。

云哥说，机会永远藏在人们抱怨的地方。人们抱怨的声音越大，你就去解决问题，抱怨越多，机会越大。所以没有困难，制造困难也要上。


---
## Shell 脚本怎么处理网络包

网络包被网卡收到之后，一般情况会经过网卡驱动写到内核数据区，再由Socket调用等方式发送到用户空间。发送也是类似的流程，只不过是反向而已。

为什么说一般情况呢，因为现在有不需要通过内核拷贝转发数据包的方式，比如DPDK。本人曾实现过自带用户态TCP/IP协议栈的网络工具，数据包处理性能非常惊人。如何高速的处理网络包是非常大个话题，eBPF/XDP也是很好的一个选择，有机会再慢慢摆，这里暂且提过不表。

虽然说Bash等Shell可以通过/dev/tcp/ip/port虚拟文件来建立连接，发送和接受数据包，但可以说Bash本身是没有提供监听端口的功能的。

所以用Shell脚本来实现HTTP服务器，还是需要借助一些别的socket服务工具来在用户态监听端口，再spawn脚本来处理HTTP协议的内容。子进程的0，1文件描述符，也就是标准输入和输出，会由socket服务工具复制到对应的文件描诉符。

这里我提供了两种配置来处理Socket服务部分，xinetd和systemd，配置文件都在socket目录里。


---
## 保持简单

脚本代码只有不到100行，没有任何花哨的语法，符合现代美学，完全不需要任何解释。

不过大家这么有缘，我再多说两句。看官来都来了，不妨再多搂几眼。

* localhost目录里面包含了一个完整的网站。
* localhost/pub里面是用markdown写的文章，md写起来就是爽。
* 访问路径后缀名是md的，会看本机有没有markdown解释器，如果没有就是直接按md显示的。
* 在pub里面增加了新的文章之后，需要手动修改index.html，这里是直接用html写的。


---
## 配置

* 修改脚本里的BASE_DIR
* 如果你的系统里面有markdown的解释器，修改脚本里的MARKDOWN_BIN
* nc -l 80 -e ./http.sh -m 5 -k

就像前面提到那样，你也可以用xinetd或者systemd来部署这个服务，注意BASE_DIR需要指定绝对路径。

* xinetd：
    - 需要在xinetd.conf修改server指向脚本的位置，然后执行`./xinetd -f xinetd.conf -d` 
* systemd：
    - 修改shellweb.socket里面的监听地址
    - shellweb@.service里的脚本路径
    - 拷贝上述两个文件到/lib/systemd/system/
    - 创建shellweb.socket软链接到/etc/systemd/system/sockets.target.wants/
* 可以试试直接执行本脚本： './http.sh /index.html'。

---
## 坐标：山景城

最近15年我在北京，温哥华，西雅图分别作了几年码农，现在湾区山景城从事微服务和服务治理相关的工作。

[https://github.com/featen](https://github.com/featen)


