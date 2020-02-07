module net

pub const (
	Ip4Len = 4
	Ip6Len = 16
)

pub struct Ip {
pub:
	octets []byte
}

pub struct IpAddr {
pub:
	ip   Ip
	port int
}

pub fn new_ip4(a, b, c, d byte) Ip {
	return Ip{
		octets: [a, b, c, d]
	}
}

fn new_ip4_from_c(s_addr int) Ip {
	return new_ip4((s_addr>>0) & 255, (s_addr>>8) & 255, (s_addr>>16) & 255, (s_addr>>24) & 255)
}

pub fn (i Ip) str() string {
	if i.octets.len == Ip4Len {
		return int(i.octets[0]).str() + '.' + int(i.octets[1]).str() + '.' + int(i.octets[2]).str() + '.' + int(i.octets[3]).str()
	}
	if i.octets.len == Ip6Len && i.has_v4_prefix() {
		return '::ffff:' + int(i.octets[12]).str() + '.' + int(i.octets[13]).str() + '.' + int(i.octets[14]).str() + '.' + int(i.octets[15]).str()
	}
	if i.octets.len == Ip6Len {
		mut res := iphex((u16(i.octets[0])<<8) | i.octets[1])
		for n := 2; n < i.octets.len; n += 2 {
			res += ':' + iphex((u16(i.octets[n])<<8) | i.octets[n + 1])
		}
		return res
	}
	return '<invalid ip>'
}

fn iphex(n u16) string {
	// TODO: free?
	hex := malloc(5) // ffff\0
	count := C.sprintf(charptr(hex), '%x', n)
	return tos(hex, count)
}

// TODO: consider using an optional here
pub fn (i Ip) to4() Ip {
	if i.octets.len == Ip4Len {
		return i
	}
	if i.octets.len == Ip6Len && i.has_v4_prefix() {
		return Ip{
			octets: i.octets[12..16]
		}
	}
	// TODO: return an error
	return i
}

// TODO: consider using an optional here
pub fn (i Ip) to6() Ip {
	if i.octets.len == Ip6Len {
		return i
	}
	if i.octets.len != Ip4Len {
		// TODO: return an error
		return i
	}
	mut res := Ip{
		octets: [0].repeat(16)
	}
	res.octets[10] = 0xff
	res.octets[11] = 0xff
	res.octets[12] = i.octets[0]
	res.octets[13] = i.octets[1]
	res.octets[14] = i.octets[2]
	res.octets[15] = i.octets[3]
	return res
}

pub fn (i Ip) has_v4_prefix() bool {
	if i.octets.len != Ip6Len {
		return false
	}
	for n := 0; n < 10; n++ {
		if i.octets[n] != 0x0 {
			return false
		}
	}
	if i.octets[10] != 0xff || i.octets[11] != 0xff {
		return false
	}
	return true
}

fn new_ip4_addr_from_c(s_addr int, sin_port int) IpAddr {
	return IpAddr{
		ip: new_ip4_from_c(s_addr)
		port: C.ntohs(sin_port)
	}
}

pub fn (i IpAddr) str() string {
	if i.ip.octets.len == Ip6Len {
		return '[' + i.ip.str() + ']:' + i.port.str()
	}
	return i.ip.str() + ':' + i.port.str()
}
