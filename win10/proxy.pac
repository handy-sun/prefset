function FindProxyForURL(url, host) {
    alert("Local IP: " + myIpAddress());
    var proxyLan = "PROXY 192.168.100.113:7984; SOCKS 192.168.100.113:7984; DIRECT";

    if (isPlainHostName(host)) {
        return "DIRECT";
    }

    if (shExpMatch(host, "*.local") ||
        shExpMatch(host, "localhost") ||
        isInNet(dnsResolve(host), "10.0.0.0", "255.0.0.0") ||
        isInNet(dnsResolve(host), "127.0.0.0", "255.255.255.0") || 
        isInNet(dnsResolve(host), "172.16.0.0",  "255.240.0.0") ||
        isInNet(dnsResolve(host), "192.168.0.0",  "255.255.0.0") ||
        isInNet(dnsResolve(host), "173.37.0.0",  "255.255.0.0")) {
        return "DIRECT";
    }

    if (shExpMatch(url, "*github*") ||
        shExpMatch(url, "*gitlab*") ||
        shExpMatch(url, "*google*") ||
        shExpMatch(url, "*stackoverflow*") ||
        shExpMatch(url, "*yfamily*") ||
        shExpMatch(url, "*yandex*") ) {
        return proxyLan;
    }

    if (shExpMatch(dnsResolve(host), "*google.com")) {
        return proxyLan; 
    }

    return "DIRECT";
}

