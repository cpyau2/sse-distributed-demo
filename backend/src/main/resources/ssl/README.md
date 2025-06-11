# SSL Certificate Directory

**⚠️ 重要提醒：证书文件不应提交到Git仓库！**

## 🔒 证书文件说明

此目录应包含以下文件（运行时生成）：
- `keystore.p12` - Spring Boot PKCS12 Keystore文件

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

- ❌ **永远不要**将证书文件提交到Git仓库
- ❌ **永远不要**在生产环境使用开发证书
- ✅ **总是**在每个环境中重新生成证书
- ✅ **总是**使用强密码保护Keystore

## 📂 文件结构
```
ssl/
├── README.md           # 本文件
└── keystore.p12        # 生成的keystore文件（不提交）
```

证书密码: `changeit`（仅用于开发环境） 