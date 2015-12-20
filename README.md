# CarNodeMCU
这是一个基于NodeMCU智能小车的代码.
NodeMCU使用lua作为编程语言。
我在淘宝上买了一辆DoitCar。发现官方例子中没有做协议粘包，
只是用每个字节表示行为。
因此，我将其做了修改。包的格式为
MsgSize:2 Byte。表示消息类型ID和消息内容的大小之和。
MsgID:1 Byte。表示消息类型ID
Buffer:表示具体的消息内容
所以，整个包的大小为2+1+Buffer的字节数。