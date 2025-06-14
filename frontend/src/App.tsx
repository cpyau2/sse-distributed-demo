import React, { useState, useEffect, useCallback, useRef } from 'react'
import axios from 'axios'
import { format } from 'date-fns'
import './App.css'

// 安全的日期格式化函數
const safeFormatDate = (dateString: string | undefined | null, formatString: string, fallback: string = '未知') => {
  if (!dateString) return fallback
  try {
    const date = new Date(dateString)
    if (isNaN(date.getTime())) return fallback
    return format(date, formatString)
  } catch (error) {
    console.warn('Date formatting error:', error)
    return fallback
  }
}

interface SseMessage {
  id: string
  type: string
  data: any
  timestamp: string
  source: string
  metadata?: Record<string, any>
}

interface ServerInstance {
  url: string
  name: string
  connected: boolean
  eventSource?: EventSource
  metrics?: InstanceMetrics
  error?: string
  connectionInfo?: ConnectionInfo
}

interface InstanceMetrics {
  instanceId: string
  instanceName: string
  uptime: number
  activeConnections: number
  totalMessagesSent: number
  messagesPerMinute: number
  memoryUsage: {
    max: number
    total: number
    used: number
    free: number
  }
}

interface ConnectionInfo {
  instanceId: string
  instanceName: string
  totalConnections: number
  clients: Array<{
    clientId: string
    connectedAt: string
    lastEventId: string
  }>
}

const App: React.FC = () => {
  // 根據當前協議動態選擇端口
  const isHttps = window.location.protocol === 'https:'
  const baseProtocol = isHttps ? 'https' : 'http'
  const ports = isHttps ? [8443, 8444, 8445] : [8080, 8081, 8082]
  
  const [servers, setServers] = useState<ServerInstance[]>([
    { url: `${baseProtocol}://localhost:${ports[0]}`, name: 'Instance 1', connected: false },
    { url: `${baseProtocol}://localhost:${ports[1]}`, name: 'Instance 2', connected: false },
    { url: `${baseProtocol}://localhost:${ports[2]}`, name: 'Instance 3', connected: false },
  ])
  
  const [messages, setMessages] = useState<SseMessage[]>([])
  const [broadcastMessage, setBroadcastMessage] = useState('')
  const [selectedServer, setSelectedServer] = useState(0)
  const [autoScroll, setAutoScroll] = useState(true)
  const [showMetrics, setShowMetrics] = useState(false)
  const [showConnections, setShowConnections] = useState(false)
  const [autoRefresh, setAutoRefresh] = useState(true)
  const [directMessageTarget, setDirectMessageTarget] = useState('')
  const [directMessageContent, setDirectMessageContent] = useState('')
  const messagesEndRef = useRef<HTMLDivElement>(null)
  
  const clientId = useRef(`client-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`)

  // 新增：自动分配实例的状态
  const [isAutoAssigning, setIsAutoAssigning] = useState(false)
  
  // 新增：服务器模式状态 ('auto' | 'manual')
  const [serverMode, setServerMode] = useState<'auto' | 'manual'>('manual')
  
  // 新增：自动分配的服务器实例
  const [autoAssignedServer, setAutoAssignedServer] = useState<ServerInstance | null>(null)

  const scrollToBottom = () => {
    if (autoScroll && messagesEndRef.current) {
      messagesEndRef.current.scrollIntoView({ behavior: 'smooth' })
    }
  }

  useEffect(() => {
    scrollToBottom()
  }, [messages])

  const connectToServer = useCallback((serverIndex: number) => {
    const server = servers[serverIndex]
    
    // 更嚴格的連接關閉邏輯
    if (server.eventSource) {
      console.log(`Closing existing connection to ${server.name}`)
      server.eventSource.close()
      // 等待一段時間確保連接完全關閉
      setTimeout(() => {
        createNewConnection(serverIndex)
      }, 100)
    } else {
      createNewConnection(serverIndex)
    }
  }, [servers])

  const createNewConnection = (serverIndex: number) => {
    const server = servers[serverIndex]
    console.log(`Creating new connection to ${server.name}`)
    
    const eventSource = new EventSource(
      `${server.url}/api/sse/stream?clientId=${clientId.current}`
    )

    // 添加連接狀態日誌
    eventSource.onopen = () => {
      console.log(`✅ Successfully connected to ${server.name}`)
      setServers(prev => {
        const updated = [...prev]
        updated[serverIndex] = { 
          ...updated[serverIndex], 
          connected: true, 
          eventSource,
          error: undefined
        }
        return updated
      })
      fetchMetrics(serverIndex)
      fetchConnectionInfo(serverIndex)
    }

    eventSource.onerror = (error) => {
      console.error(`❌ Error with ${server.name}:`, error)
      setServers(prev => {
        const updated = [...prev]
        updated[serverIndex] = { 
          ...updated[serverIndex], 
          connected: false,
          error: 'Connection failed'
        }
        return updated
      })
    }

    // Handle different event types with source logging
    const handleEvent = (event: MessageEvent) => {
      try {
        const message: SseMessage = JSON.parse(event.data)
        console.log(`📨 Message from ${message.source}:`, message)
        
        // 添加去重邏輯：檢查是否已經有相同ID的訊息
        setMessages(prev => {
          const isDuplicate = prev.some(existingMsg => existingMsg.id === message.id)
          if (isDuplicate) {
            console.log(`🔄 Duplicate message detected, skipping: ${message.id}`)
            return prev
          }
          return [...prev.slice(-99), message]
        })
      } catch (error) {
        console.error('Error parsing message:', error)
      }
    }

    eventSource.addEventListener('CONNECTION', handleEvent)
    eventSource.addEventListener('MESSAGE', handleEvent)
    eventSource.addEventListener('HEARTBEAT', handleEvent)
    eventSource.addEventListener('DIRECT', handleEvent)

    setServers(prev => {
      const updated = [...prev]
      updated[serverIndex] = { ...updated[serverIndex], eventSource }
      return updated
    })
  }

  const disconnectFromServer = useCallback((serverIndex: number) => {
    const server = servers[serverIndex]
    if (server.eventSource) {
      server.eventSource.close()
      setServers(prev => {
        const updated = [...prev]
        updated[serverIndex] = { 
          ...updated[serverIndex], 
          connected: false, 
          eventSource: undefined,
          metrics: undefined,
          connectionInfo: undefined
        }
        return updated
      })
    }
  }, [servers])

  const fetchMetrics = async (serverIndex: number) => {
    try {
      const response = await axios.get<InstanceMetrics>(
        `${servers[serverIndex].url}/api/sse/metrics`
      )
      setServers(prev => {
        const updated = [...prev]
        updated[serverIndex] = { 
          ...updated[serverIndex], 
          metrics: response.data 
        }
        return updated
      })
    } catch (error) {
      console.error('Error fetching metrics:', error)
    }
  }

  const fetchConnectionInfo = async (serverIndex: number) => {
    try {
      const response = await axios.get<ConnectionInfo>(
        `${servers[serverIndex].url}/api/sse/connections`
      )
      setServers(prev => {
        const updated = [...prev]
        updated[serverIndex] = { 
          ...updated[serverIndex], 
          connectionInfo: response.data 
        }
        return updated
      })
    } catch (error) {
      console.error('Error fetching connection info:', error)
    }
  }

  const fetchAllMetrics = () => {
    if (serverMode === 'manual') {
      servers.forEach((server, index) => {
        if (server.connected) {
          fetchMetrics(index)
          fetchConnectionInfo(index)
        }
      })
    } else if (serverMode === 'auto' && autoAssignedServer?.connected) {
      fetchAutoAssignedMetrics()
      fetchAutoAssignedConnectionInfo()
    }
  }

  // 新增：随机选择服务器实例
  const getRandomServerInstance = () => {
    const randomIndex = Math.floor(Math.random() * servers.length)
    const selectedServer = servers[randomIndex]
    
    return {
      ...selectedServer,
      name: `Auto Assigned - ${selectedServer.name}`,
      connected: false,
      eventSource: undefined,
      metrics: undefined,
      connectionInfo: undefined,
      error: undefined
    }
  }

  // 新增：切换服务器模式
  const switchServerMode = (newMode: 'auto' | 'manual') => {
    if (newMode === serverMode) return
    
    console.log(`🔄 切换服务器模式: ${serverMode} -> ${newMode}`)
    
    // 断开所有现有连接
    if (serverMode === 'manual') {
      servers.forEach((server, index) => {
        if (server.connected) {
          disconnectFromServer(index)
        }
      })
    } else if (serverMode === 'auto' && autoAssignedServer?.connected) {
      // 断开自动分配的连接
      if (autoAssignedServer.eventSource) {
        autoAssignedServer.eventSource.close()
      }
    }
    
    setServerMode(newMode)
    
    // 如果切换到auto模式，随机选择一个服务器
    if (newMode === 'auto') {
      const randomServer = getRandomServerInstance()
      setAutoAssignedServer(randomServer)
      console.log(`🎯 随机选择服务器: ${randomServer.name}`)
    } else {
      setAutoAssignedServer(null)
    }
  }

  // 新增：自动分配实例功能 (for auto mode)
  const autoAssignInstance = async () => {
    if (isAutoAssigning || serverMode !== 'auto' || !autoAssignedServer) return
    
    setIsAutoAssigning(true)
    
    try {
      console.log('🔍 开始连接自动分配的实例...')
      console.log(`🔗 连接URL: ${autoAssignedServer.url}`)
      
      // 跳过健康检查，直接创建SSE连接
      // 健康检查在HTTPS环境下可能有CORS问题，我们直接尝试SSE连接
      
      // 创建SSE连接
      const eventSource = new EventSource(
        `${autoAssignedServer.url}/api/sse/stream?clientId=${clientId.current}`
      )

      // 添加超时机制
      const connectionTimeout = setTimeout(() => {
        if (!autoAssignedServer?.connected) {
          eventSource.close()
          console.error('❌ 连接超时')
          setAutoAssignedServer(prev => prev ? {
            ...prev,
            error: '连接超时'
          } : null)
          setIsAutoAssigning(false)
        }
      }, 10000) // 10秒超时

      eventSource.onopen = () => {
        clearTimeout(connectionTimeout)
        console.log(`✅ 成功连接到自动分配的服务器: ${autoAssignedServer?.name}`)
        setAutoAssignedServer(prev => prev ? {
          ...prev,
          connected: true,
          eventSource,
          error: undefined
        } : null)
        
        // 获取指标信息
        fetchAutoAssignedMetrics()
        fetchAutoAssignedConnectionInfo()
        setIsAutoAssigning(false)
      }

      eventSource.onerror = (error) => {
        clearTimeout(connectionTimeout)
        console.error(`❌ 自动分配服务器连接错误:`, error)
        setAutoAssignedServer(prev => prev ? {
          ...prev,
          connected: false,
          error: 'Connection failed'
        } : null)
        setIsAutoAssigning(false)
      }

      // Handle different event types
      const handleEvent = (event: MessageEvent) => {
        try {
          const message: SseMessage = JSON.parse(event.data)
          console.log(`📨 来自自动分配服务器的消息:`, message)
          
          setMessages(prev => {
            const isDuplicate = prev.some(existingMsg => existingMsg.id === message.id)
            if (isDuplicate) {
              console.log(`🔄 重复消息已跳过: ${message.id}`)
              return prev
            }
            return [...prev.slice(-99), message]
          })
        } catch (error) {
          console.error('解析消息错误:', error)
        }
      }

      eventSource.addEventListener('CONNECTION', handleEvent)
      eventSource.addEventListener('MESSAGE', handleEvent)
      eventSource.addEventListener('HEARTBEAT', handleEvent)
      eventSource.addEventListener('DIRECT', handleEvent)

      // 在这里不设置setIsAutoAssigning(false)，因为onopen或onerror会处理
      setAutoAssignedServer(prev => prev ? {
        ...prev,
        eventSource
      } : null)
      
      console.log('🔄 正在等待连接响应...')
      
    } catch (error) {
      console.error('❌ 自动分配实例连接失败:', error)
      setAutoAssignedServer(prev => prev ? {
        ...prev,
        error: error instanceof Error ? error.message : '未知错误'
      } : null)
      alert('自动分配实例连接失败')
      setIsAutoAssigning(false)
    }
  }

  // 新增：断开自动分配的连接
  const disconnectAutoAssignedServer = () => {
    if (autoAssignedServer?.eventSource) {
      autoAssignedServer.eventSource.close()
      setAutoAssignedServer(prev => prev ? {
        ...prev,
        connected: false,
        eventSource: undefined,
        metrics: undefined,
        connectionInfo: undefined
      } : null)
      console.log('🔌 自动分配服务器连接已断开')
    }
  }

  // 新增：获取自动分配服务器的指标
  const fetchAutoAssignedMetrics = async () => {
    if (!autoAssignedServer) return
    
    try {
      const response = await axios.get<InstanceMetrics>(
        `${autoAssignedServer.url}/api/sse/metrics`
      )
      setAutoAssignedServer(prev => prev ? {
        ...prev,
        metrics: response.data
      } : null)
    } catch (error) {
      console.error('获取自动分配服务器指标失败:', error)
    }
  }

  // 新增：获取自动分配服务器的连接信息
  const fetchAutoAssignedConnectionInfo = async () => {
    if (!autoAssignedServer) return
    
    try {
      const response = await axios.get<ConnectionInfo>(
        `${autoAssignedServer.url}/api/sse/connections`
      )
      setAutoAssignedServer(prev => prev ? {
        ...prev,
        connectionInfo: response.data
      } : null)
    } catch (error) {
      console.error('获取自动分配服务器连接信息失败:', error)
    }
  }
  
  // 计算服务器得分（用于选择最优服务器）
  // 注意：这个函数在当前版本中暂时不使用，但保留为将来扩展功能
  // const calculateServerScore = (metrics: InstanceMetrics) => {
  //   if (!metrics) return 0
  //   
  //   // 计算得分，优先选择：
  //   // 1. 连接数少的服务器（负载低）
  //   // 2. 内存使用率低的服务器
  //   // 3. 运行时间长的服务器（稳定性好）
  //   
  //   const connectionScore = Math.max(0, 100 - metrics.activeConnections * 10) // 连接数越少分数越高
  //   const memoryScore = Math.max(0, 100 - (metrics.memoryUsage.used / metrics.memoryUsage.total) * 100) // 内存使用率越低分数越高
  //   const uptimeScore = Math.min(50, metrics.uptime / (1000 * 60 * 60)) // 运行时间得分，最高50分
  //   
  //   return connectionScore + memoryScore + uptimeScore
  // }

  const sendBroadcast = async () => {
    if (!broadcastMessage.trim()) return

    try {
      let targetUrl: string
      
      if (serverMode === 'manual') {
        targetUrl = servers[selectedServer].url
      } else if (serverMode === 'auto' && autoAssignedServer) {
        targetUrl = autoAssignedServer.url
      } else {
        alert('請先連接到服務器實例')
        return
      }

      await axios.post(
        `${targetUrl}/api/sse/broadcast`,
        { 
          type: 'MESSAGE',
          data: {
            text: broadcastMessage,
            sender: clientId.current,
            timestamp: new Date().toISOString()
          }
        }
      )
      setBroadcastMessage('')
    } catch (error) {
      console.error('Error broadcasting message:', error)
      alert('Failed to send message. Is the server connected?')
    }
  }

  const sendDirectMessage = async (targetClientId?: string) => {
    const target = targetClientId || directMessageTarget
    const message = targetClientId ? 
      prompt('Enter message to send directly to this client:') : 
      directMessageContent

    if (!target || !message) {
      alert('Please specify both target client ID and message')
      return
    }

    try {
      let targetUrl: string
      
      if (serverMode === 'manual') {
        targetUrl = servers[selectedServer].url
      } else if (serverMode === 'auto' && autoAssignedServer) {
        targetUrl = autoAssignedServer.url
      } else {
        alert('請先連接到服務器實例')
        return
      }

      await axios.post(
        `${targetUrl}/api/sse/broadcast/${target}`,
        { 
          type: 'DIRECT',
          data: {
            text: message,
            sender: clientId.current,
            timestamp: new Date().toISOString()
          }
        }
      )
      
      // Clear form if using the input fields
      if (!targetClientId) {
        setDirectMessageTarget('')
        setDirectMessageContent('')
      }
      
      alert('Direct message sent successfully!')
    } catch (error) {
      console.error('Error sending direct message:', error)
      alert('Failed to send direct message')
    }
  }

  const clearMessages = () => {
    setMessages([])
  }

  useEffect(() => {
    // Auto-refresh metrics every 10 seconds (only if enabled)
    if (autoRefresh) {
      const interval = setInterval(fetchAllMetrics, 10000)
      return () => clearInterval(interval)
    }
  }, [servers, autoRefresh])

  const formatUptime = (ms: number) => {
    const seconds = Math.floor(ms / 1000)
    const minutes = Math.floor(seconds / 60)
    const hours = Math.floor(minutes / 60)
    const days = Math.floor(hours / 24)
    
    if (days > 0) return `${days}d ${hours % 24}h`
    if (hours > 0) return `${hours}h ${minutes % 60}m`
    if (minutes > 0) return `${minutes}m ${seconds % 60}s`
    return `${seconds}s`
  }

  const getMessageColor = (type: string) => {
    switch (type) {
      case 'CONNECTION': return '#4CAF50'
      case 'MESSAGE': return '#2196F3'
      case 'HEARTBEAT': return '#FF9800'
      case 'DIRECT': return '#9C27B0'
      default: return '#757575'
    }
  }

  return (
    <div className="app">
      <header className="app-header">
        <h1>SSE 分散式部署研究平台</h1>
        <div className="client-info">
          <div>Client ID: <code>{clientId.current}</code></div>
          <div>協議模式: <code>{isHttps ? 'HTTPS' : 'HTTP'}</code> | 後端端口: <code>{ports.join(', ')}</code></div>
        </div>
      </header>

      <div className="main-content">
        <section className="servers-section">
          <div className="section-header">
            <h2>伺服器實例</h2>
            <div className="header-controls">
              <select 
                value={serverMode} 
                onChange={(e) => switchServerMode(e.target.value as 'auto' | 'manual')}
                className="server-mode-select"
              >
                <option value="manual">手動選擇實例</option>
                <option value="auto">自動分配實例</option>
              </select>
              
              <button onClick={() => setShowMetrics(!showMetrics)}>
                {showMetrics ? '隱藏' : '顯示'}詳細指標
              </button>
              <button onClick={() => setShowConnections(!showConnections)}>
                {showConnections ? '隱藏' : '顯示'}連接資訊
              </button>
              <button onClick={() => setAutoRefresh(!autoRefresh)}>
                {autoRefresh ? '🔄 停止自動刷新' : '▶️ 開始自動刷新'}
              </button>
            </div>
          </div>
          
          <div className="servers-grid">
            {serverMode === 'manual' ? (
              // 手動模式：顯示所有服務器實例
              servers.map((server, index) => (
                <div key={index} className={`server-card ${server.connected ? 'connected' : ''}`}>
                  <div className="server-header">
                    <h3>{server.name}</h3>
                    <span className={`status ${server.connected ? 'online' : 'offline'}`}>
                      {server.connected ? '● 線上' : '○ 離線'}
                    </span>
                  </div>
                  
                  <div className="server-info">
                    <p><strong>URL:</strong> {server.url}</p>
                    {server.error && (
                      <p className="error-message">{server.error}</p>
                    )}
                    
                    {showMetrics && server.metrics && (
                      <div className="metrics">
                        <p><strong>實例 ID:</strong> {server.metrics.instanceName}</p>
                        <p><strong>運行時間:</strong> {formatUptime(server.metrics.uptime)}</p>
                        <p><strong>活躍連接:</strong> {server.metrics.activeConnections}</p>
                        <p><strong>總訊息數:</strong> {server.metrics.totalMessagesSent}</p>
                        <p><strong>訊息速率:</strong> {server.metrics.messagesPerMinute.toFixed(2)}/分鐘</p>
                        <p><strong>記憶體:</strong> {server.metrics.memoryUsage.used}MB / {server.metrics.memoryUsage.total}MB</p>
                      </div>
                    )}
                    
                    {showConnections && server.connectionInfo && (
                      <div className="connection-info">
                        <h4>連接的客戶端 ({server.connectionInfo.totalConnections})</h4>
                        <div className="client-list">
                          {server.connectionInfo.clients.map((client, idx) => (
                            <div key={idx} className="client-item">
                              <p>
                                <strong>ID:</strong> {client.clientId}
                                {client.clientId === clientId.current && ' (You)'}
                              </p>
                              <p><strong>連接時間:</strong> {safeFormatDate(client.connectedAt, 'HH:mm:ss')}</p>
                              {client.clientId !== clientId.current && (
                                <button 
                                  onClick={() => sendDirectMessage(client.clientId)}
                                  className="direct-msg-btn"
                                >
                                  發送私訊
                                </button>
                              )}
                            </div>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                  
                  <div className="server-actions">
                    <button
                      onClick={() => server.connected ? disconnectFromServer(index) : connectToServer(index)}
                      className={server.connected ? 'disconnect-btn' : 'connect-btn'}
                    >
                      {server.connected ? '斷開連接' : '連接'}
                    </button>
                    {server.connected && (
                      <button onClick={() => {
                        fetchMetrics(index)
                        fetchConnectionInfo(index)
                      }} className="refresh-btn">
                        刷新資訊
                      </button>
                    )}
                  </div>
                </div>
              ))
            ) : (
              // 自動模式：只顯示自動分配的服務器實例
              autoAssignedServer && (
                <div className={`server-card auto-assigned ${autoAssignedServer.connected ? 'connected' : ''}`}>
                  <div className="server-header">
                    <h3>{autoAssignedServer.name}</h3>
                    <span className={`status ${autoAssignedServer.connected ? 'online' : 'offline'}`}>
                      {autoAssignedServer.connected ? '● 線上' : '○ 離線'}
                    </span>
                  </div>
                  
                  <div className="server-info">
                    <p><strong>URL:</strong> {autoAssignedServer.url}</p>
                    <p><strong>模式:</strong> 🎯 自動分配</p>
                    {autoAssignedServer.error && (
                      <p className="error-message">{autoAssignedServer.error}</p>
                    )}
                    
                    {showMetrics && autoAssignedServer.metrics && (
                      <div className="metrics">
                        <p><strong>實例 ID:</strong> {autoAssignedServer.metrics.instanceName}</p>
                        <p><strong>運行時間:</strong> {formatUptime(autoAssignedServer.metrics.uptime)}</p>
                        <p><strong>活躍連接:</strong> {autoAssignedServer.metrics.activeConnections}</p>
                        <p><strong>總訊息數:</strong> {autoAssignedServer.metrics.totalMessagesSent}</p>
                        <p><strong>訊息速率:</strong> {autoAssignedServer.metrics.messagesPerMinute.toFixed(2)}/分鐘</p>
                        <p><strong>記憶體:</strong> {autoAssignedServer.metrics.memoryUsage.used}MB / {autoAssignedServer.metrics.memoryUsage.total}MB</p>
                      </div>
                    )}
                    
                    {showConnections && autoAssignedServer.connectionInfo && (
                      <div className="connection-info">
                        <h4>連接的客戶端 ({autoAssignedServer.connectionInfo.totalConnections})</h4>
                        <div className="client-list">
                          {autoAssignedServer.connectionInfo.clients.map((client, idx) => (
                            <div key={idx} className="client-item">
                              <p>
                                <strong>ID:</strong> {client.clientId}
                                {client.clientId === clientId.current && ' (You)'}
                              </p>
                              <p><strong>連接時間:</strong> {safeFormatDate(client.connectedAt, 'HH:mm:ss')}</p>
                              {client.clientId !== clientId.current && (
                                <button 
                                  onClick={() => sendDirectMessage(client.clientId)}
                                  className="direct-msg-btn"
                                >
                                  發送私訊
                                </button>
                              )}
                            </div>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                  
                  <div className="server-actions">
                    <button
                      onClick={() => autoAssignedServer.connected ? disconnectAutoAssignedServer() : autoAssignInstance()}
                      className={autoAssignedServer.connected ? 'disconnect-btn' : 'connect-btn'}
                      disabled={isAutoAssigning}
                    >
                      {isAutoAssigning ? '連接中...' : 
                       autoAssignedServer.connected ? '斷開連接' : '連接'}
                    </button>
                    {autoAssignedServer.connected && (
                      <button onClick={() => {
                        fetchAutoAssignedMetrics()
                        fetchAutoAssignedConnectionInfo()
                      }} className="refresh-btn">
                        刷新資訊
                      </button>
                    )}
                  </div>
                </div>
              )
            )}
          </div>
        </section>

        <section className="broadcast-section">
          <h2>訊息控制</h2>
          
          {/* 廣播訊息 */}
          <div className="message-control-group">
            <h3>廣播訊息</h3>
            <div className="broadcast-controls">
              <select 
                value={selectedServer} 
                onChange={(e) => setSelectedServer(Number(e.target.value))}
                className="server-select"
              >
                {servers.map((server, index) => (
                  <option key={index} value={index} disabled={!server.connected}>
                    {server.name} {!server.connected && '(離線)'}
                  </option>
                ))}
              </select>
              
              <input
                type="text"
                value={broadcastMessage}
                onChange={(e) => setBroadcastMessage(e.target.value)}
                placeholder="輸入要廣播的訊息..."
                onKeyPress={(e) => e.key === 'Enter' && sendBroadcast()}
                className="message-input"
              />
              
              <button onClick={sendBroadcast} className="send-btn">
                發送廣播
              </button>
            </div>
          </div>
          
          {/* 點對點訊息 */}
          <div className="message-control-group">
            <h3>點對點訊息</h3>
            <div className="direct-message-controls">
              <input
                type="text"
                value={directMessageTarget}
                onChange={(e) => setDirectMessageTarget(e.target.value)}
                placeholder="目標客戶端 ID..."
                className="target-input"
              />
              
              <input
                type="text"
                value={directMessageContent}
                onChange={(e) => setDirectMessageContent(e.target.value)}
                placeholder="輸入私人訊息..."
                onKeyPress={(e) => e.key === 'Enter' && sendDirectMessage()}
                className="message-input"
              />
              
              <button onClick={() => sendDirectMessage()} className="send-btn direct">
                發送私訊
              </button>
            </div>
          </div>
        </section>

        <section className="messages-section">
          <div className="section-header">
            <h2>訊息記錄 ({messages.length})</h2>
            <div className="message-controls">
              <label>
                <input
                  type="checkbox"
                  checked={autoScroll}
                  onChange={(e) => setAutoScroll(e.target.checked)}
                />
                自動捲動
              </label>
              <button onClick={clearMessages} className="clear-btn">
                清除訊息
              </button>
            </div>
          </div>
          
          <div className="messages-container">
            {messages.map((msg, index) => (
              <div 
                key={index} 
                className={`message ${msg.type === 'DIRECT' ? 'direct-message' : ''}`}
                style={{ borderLeftColor: getMessageColor(msg.type) }}
              >
                <div className="message-header">
                  <span className="message-type" style={{ color: getMessageColor(msg.type) }}>
                    [{msg.type}]
                  </span>
                  <span className="message-source">來源: {msg.source}</span>
                  <span className="message-time">
                    {safeFormatDate(msg.timestamp, 'HH:mm:ss.SSS', '未知時間')}
                  </span>
                </div>
                <div className="message-content">
                  {typeof msg.data === 'object' ? (
                    <pre>{JSON.stringify(msg.data, null, 2)}</pre>
                  ) : (
                    <p>{msg.data}</p>
                  )}
                </div>
                {msg.metadata && (
                  <div className="message-metadata">
                    <small>Metadata: {JSON.stringify(msg.metadata)}</small>
                  </div>
                )}
              </div>
            ))}
            <div ref={messagesEndRef} />
          </div>
        </section>
      </div>
    </div>
  )
}

export default App