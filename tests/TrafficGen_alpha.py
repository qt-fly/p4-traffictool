from scapy import *

 ##class definitions
class Ethernet(Packet):
	name = 'ethernet'
	fields_desc = [
		BitField('dstAddr',0,48),
		BitField('srcAddr',0,48),
		BitField('srcAddr',0,48)
	]

class Ipv4(Packet):
	name = 'ipv4'
	fields_desc = [
		BitField('version',0,4),
		BitField('ihl',0,4),
		BitField('diffserv',0,8),
		BitField('totalLen',0,16),
		BitField('identification',0,16),
		BitField('flags',0,3),
		BitField('fragOffset',0,13),
		BitField('ttl',0,8),
		BitField('protocol',0,8),
		BitField('hdrChecksum',0,16),
		BitField('srcAddr',0,32),
		BitField('srcAddr',0,32)
	]

class Udp(Packet):
	name = 'udp'
	fields_desc = [
		BitField('srcPort',0,16),
		BitField('dstPort',0,16),
		BitField('hdr_length',0,16),
		BitField('hdr_length',0,16)
	]

class Q_meta(Packet):
	name = 'q_meta'
	fields_desc = [
		BitField('flow_id',0,16),
		BitField('_pad0',0,16),
		BitField('ingress_global_tstamp',0,48),
		BitField('_pad1',0,16),
		BitField('egress_global_tstamp',0,48),
		BitField('_spare_pad_bits',0,15),
		BitField('markbit',0,1),
		BitField('_pad2',0,13),
		BitField('enq_qdepth',0,19),
		BitField('_pad3',0,13),
		BitField('_pad3',0,13)
	]

class Snapshot(Packet):
	name = 'snapshot'
	fields_desc = [
		BitField('ingress_global_tstamp_hi_16',0,16),
		BitField('ingress_global_tstamp_lo_32',0,32),
		BitField('egress_global_tstamp_lo_32',0,32),
		BitField('enq_qdepth',0,32),
		BitField('deq_qdepth',0,32),
		BitField('_pad0',0,16),
		BitField('orig_egress_global_tstamp',0,48),
		BitField('_pad1',0,16),
		BitField('new_egress_global_tstamp',0,48),
		BitField('new_egress_global_tstamp',0,48)
	]


##bindings
bind_layers(Ethernet, Ipv4, etherType = 0x0800)
bind_layers(Ipv4, Udp, protocol = 0x11)
bind_layers(Udp, Q_meta, dstPort = 0x1e61)
bind_layers(Udp, Snapshot, dstPort = 0x22b8)
