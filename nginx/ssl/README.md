# Nginx SSL Certificate Directory

**⚠️ 重要提醒：证书文件不应提交到Git仓库！**

## 🔒 证书文件说明

此目录应包含以下文件（运行时生成）：
- `server.key` - 私钥文件
- `server.crt` - 证书文件

## 🛠️ 生成证书

### 方法1: 使用Docker生成（推荐）
```bash
scripts\generate-ssl-docker.bat
```

### 方法2: 使用本地工具
```bash
scripts\generate-ssl-certs.bat
```

## 🚨 安全提醒

- ❌ **永远不要**将私钥文件提交到Git仓库
- ❌ **永远不要**在生产环境使用开发证书
- ✅ **总是**在每个环境中重新生成证书
- ✅ **总是**保护好私钥文件的安全

## 📂 文件结构
```
ssl/
├── README.md           # 本文件
├── server.key          # 私钥文件（不提交）
└── server.crt          # 证书文件（不提交）
```

## 📜 证书信息
- 主题: `CN=localhost`
- 有效期: 365天
- 密钥类型: RSA 2048位 