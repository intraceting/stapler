### 创建根证书
```bash
$./make-cert.sh -c 1 -H < 证书路径 > -U < 常用名(域名) >  [ ... ]
```

### 签发下级证书
```bash
$./make-cert.sh -c 2 -H < 证书路径 > -L < 叶证书路径 > -U < 常用名(域名) > [ ... ]
```

### 吊销下级证书
```bash
$./make-cert.sh -c 3 -H < 证书路径 > -L < 叶证书路径 >  [ ... ]
```

### 更新吊销列表
```bash
$./make-cert.sh -c 4 -H < 证书路径 > 
```
