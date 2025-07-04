```java
// 1. 外部数据源配置类
@Configuration
public class ExternalDataSourceConfig {
    
    @Bean(name = "externalDataSource")
    @ConfigurationProperties(prefix = "external.datasource")
    public DataSource externalDataSource() {
        return DataSourceBuilder.create().build();
    }
    
    @Bean(name = "externalJdbcTemplate")
    public JdbcTemplate externalJdbcTemplate(@Qualifier("externalDataSource") DataSource dataSource) {
        return new JdbcTemplate(dataSource);
    }
}

---

// 2. 配置文件 application.yml (添加外部数据源配置)
# 主数据源保持不变
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/main_db
    username: main_user
    password: main_password
    driver-class-name: com.mysql.cj.jdbc.Driver

# 外部数据源配置
external:
  datasource:
    url: jdbc:mysql://external-host:3306/external_db
    username: external_user
    password: external_password
    driver-class-name: com.mysql.cj.jdbc.Driver
    hikari:
      maximum-pool-size: 5
      minimum-idle: 2
      connection-timeout: 30000
      idle-timeout: 600000

# 定时任务配置
task:
  external-sync:
    enabled: true
    cron: "0 */10 * * * ?"  # 每10分钟执行一次
    batch-size: 1000  # 批处理大小

---

// 3. 本地数据库实体类 (用于存储同步的数据)
@Entity
@Table(name = "sync_data")
public class SyncData {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "external_id")
    private String externalId;
    
    @Column(name = "name")
    private String name;
    
    @Column(name = "status")
    private String status;
    
    @Column(name = "data_content", columnDefinition = "TEXT")
    private String dataContent;
    
    @Column(name = "source_table")
    private String sourceTable;
    
    @Column(name = "external_updated_time")
    private LocalDateTime externalUpdatedTime;
    
    @Column(name = "sync_time")
    private LocalDateTime syncTime;
    
    @Column(name = "created_time")
    private LocalDateTime createdTime;
    
    @Column(name = "updated_time")
    private LocalDateTime updatedTime;
    
    // 构造函数
    public SyncData() {
        this.syncTime = LocalDateTime.now();
        this.createdTime = LocalDateTime.now();
        this.updatedTime = LocalDateTime.now();
    }
    
    public SyncData(String externalId, String name, String status, String sourceTable) {
        this();
        this.externalId = externalId;
        this.name = name;
        this.status = status;
        this.sourceTable = sourceTable;
    }
    
    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    
    public String getExternalId() { return externalId; }
    public void setExternalId(String externalId) { this.externalId = externalId; }
    
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    
    public String getDataContent() { return dataContent; }
    public void setDataContent(String dataContent) { this.dataContent = dataContent; }
    
    public String getSourceTable() { return sourceTable; }
    public void setSourceTable(String sourceTable) { this.sourceTable = sourceTable; }
    
    public LocalDateTime getExternalUpdatedTime() { return externalUpdatedTime; }
    public void setExternalUpdatedTime(LocalDateTime externalUpdatedTime) { this.externalUpdatedTime = externalUpdatedTime; }
    
    public LocalDateTime getSyncTime() { return syncTime; }
    public void setSyncTime(LocalDateTime syncTime) { this.syncTime = syncTime; }
    
    public LocalDateTime getCreatedTime() { return createdTime; }
    public void setCreatedTime(LocalDateTime createdTime) { this.createdTime = createdTime; }
    
    public LocalDateTime getUpdatedTime() { return updatedTime; }
    public void setUpdatedTime(LocalDateTime updatedTime) { this.updatedTime = updatedTime; }
}

---

// 4. 本地数据库Repository
@Repository
public interface SyncDataRepository extends JpaRepository<SyncData, Long> {
    
    /**
     * 根据外部ID查找数据
     */
    Optional<SyncData> findByExternalId(String externalId);
    
    /**
     * 根据外部ID和来源表查找数据
     */
    Optional<SyncData> findByExternalIdAndSourceTable(String externalId, String sourceTable);
    
    /**
     * 批量查找外部ID
     */
    @Query("SELECT s.externalId FROM SyncData s WHERE s.externalId IN :externalIds AND s.sourceTable = :sourceTable")
    List<String> findExistingExternalIds(@Param("externalIds") List<String> externalIds, 
                                        @Param("sourceTable") String sourceTable);
    
    /**
     * 获取最后同步时间
     */
    @Query("SELECT MAX(s.syncTime) FROM SyncData s WHERE s.sourceTable = :sourceTable")
    LocalDateTime findLastSyncTimeBySourceTable(@Param("sourceTable") String sourceTable);
    
    /**
     * 统计同步数据
     */
    long countBySourceTable(String sourceTable);
}

---

// 5. 外部数据查询服务
@Service
@Slf4j
public class ExternalDataQueryService {
    
    @Qualifier("externalJdbcTemplate")
    private final JdbcTemplate externalJdbcTemplate;
    
    public ExternalDataQueryService(@Qualifier("externalJdbcTemplate") JdbcTemplate externalJdbcTemplate) {
        this.externalJdbcTemplate = externalJdbcTemplate;
    }
    
    /**
     * 查询外部数据库的增量数据
     */
    public List<Map<String, Object>> queryIncrementalData(String tableName, LocalDateTime lastSyncTime) {
        String sql = String.format(
            "SELECT * FROM %s WHERE updated_time > ? ORDER BY updated_time ASC", 
            tableName);
        
        try {
            log.info("查询外部数据库增量数据 - 表: {}, 时间: {}", tableName, lastSyncTime);
            List<Map<String, Object>> results = externalJdbcTemplate.queryForList(
                sql, Timestamp.valueOf(lastSyncTime));
            log.info("查询到 {} 条增量数据", results.size());
            return results;
        } catch (Exception e) {
            log.error("查询外部数据库失败 - 表: {}", tableName, e);
            throw new RuntimeException("查询外部数据库失败", e);
        }
    }
    
    /**
     * 查询特定条件的数据
     */
    public List<Map<String, Object>> queryDataWithCondition(String tableName, String condition, Object... params) {
        String sql = String.format("SELECT * FROM %s WHERE %s", tableName, condition);
        
        try {
            log.debug("执行查询 - SQL: {}", sql);
            return externalJdbcTemplate.queryForList(sql, params);
        } catch (Exception e) {
            log.error("查询外部数据库失败 - SQL: {}", sql, e);
            throw new RuntimeException("查询外部数据库失败", e);
        }
    }
    
    /**
     * 获取表的总记录数
     */
    public int getTableCount(String tableName) {
        String sql = String.format("SELECT COUNT(*) FROM %s", tableName);
        try {
            return externalJdbcTemplate.queryForObject(sql, Integer.class);
        } catch (Exception e) {
            log.error("获取表记录数失败 - 表: {}", tableName, e);
            return 0;
        }
    }
    
    /**
     * 测试连接
     */
    public boolean testConnection() {
        try {
            externalJdbcTemplate.queryForObject("SELECT 1", Integer.class);
            return true;
        } catch (Exception e) {
            log.error("外部数据库连接测试失败", e);
            return false;
        }
    }
}

---

// 6. 数据同步服务
@Service
@Slf4j
@Transactional
public class DataSyncService {
    
    private final ExternalDataQueryService externalQueryService;
    private final SyncDataRepository syncDataRepository;
    private final ObjectMapper objectMapper;
    
    @Value("${task.external-sync.batch-size:1000}")
    private int batchSize;
    
    public DataSyncService(ExternalDataQueryService externalQueryService,
                          SyncDataRepository syncDataRepository,
                          ObjectMapper objectMapper) {
        this.externalQueryService = externalQueryService;
        this.syncDataRepository = syncDataRepository;
        this.objectMapper = objectMapper;
    }
    
    /**
     * 同步指定表的数据
     */
    public SyncResult syncTableData(String tableName) {
        SyncResult result = new SyncResult(tableName);
        
        try {
            // 获取最后同步时间
            LocalDateTime lastSyncTime = getLastSyncTime(tableName);
            log.info("开始同步表 {} 的数据，上次同步时间: {}", tableName, lastSyncTime);
            
            // 查询增量数据
            List<Map<String, Object>> externalData = externalQueryService.queryIncrementalData(tableName, lastSyncTime);
            
            if (externalData.isEmpty()) {
                log.info("表 {} 没有新的数据需要同步", tableName);
                return result;
            }
            
            // 分批处理数据
            List<List<Map<String, Object>>> batches = createBatches(externalData, batchSize);
            
            for (List<Map<String, Object>> batch : batches) {
                processBatch(batch, tableName, result);
            }
            
            log.info("表 {} 同步完成 - 新增: {}, 更新: {}, 失败: {}", 
                    tableName, result.getInsertCount(), result.getUpdateCount(), result.getErrorCount());
            
        } catch (Exception e) {
            log.error("同步表 {} 数据失败", tableName, e);
            result.addError("同步失败: " + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * 处理批次数据
     */
    private void processBatch(List<Map<String, Object>> batch, String tableName, SyncResult result) {
        // 获取批次中所有的外部ID
        List<String> externalIds = batch.stream()
            .map(data -> String.valueOf(data.get("id")))
            .collect(Collectors.toList());
        
        // 查询已存在的数据
        List<String> existingIds = syncDataRepository.findExistingExternalIds(externalIds, tableName);
        Set<String> existingIdSet = new HashSet<>(existingIds);
        
        List<SyncData> toSave = new ArrayList<>();
        
        for (Map<String, Object> externalRow : batch) {
            try {
                String externalId = String.valueOf(externalRow.get("id"));
                
                SyncData syncData;
                if (existingIdSet.contains(externalId)) {
                    // 更新现有数据
                    Optional<SyncData> existingOpt = syncDataRepository.findByExternalIdAndSourceTable(externalId, tableName);
                    if (existingOpt.isPresent()) {
                        syncData = existingOpt.get();
                        updateSyncDataFromExternal(syncData, externalRow);
                        result.incrementUpdate();
                    } else {
                        continue; // 跳过找不到的数据
                    }
                } else {
                    // 创建新数据
                    syncData = createSyncDataFromExternal(externalRow, tableName);
                    result.incrementInsert();
                }
                
                toSave.add(syncData);
                
            } catch (Exception e) {
                log.error("处理数据失败 - 外部ID: {}", externalRow.get("id"), e);
                result.addError("处理数据失败: " + e.getMessage());
            }
        }
        
        // 批量保存
        if (!toSave.isEmpty()) {
            syncDataRepository.saveAll(toSave);
        }
    }
    
    /**
     * 从外部数据创建SyncData
     */
    private SyncData createSyncDataFromExternal(Map<String, Object> externalRow, String tableName) throws Exception {
        SyncData syncData = new SyncData();
        syncData.setExternalId(String.valueOf(externalRow.get("id")));
        syncData.setName(String.valueOf(externalRow.get("name")));
        syncData.setStatus(String.valueOf(externalRow.get("status")));
        syncData.setSourceTable(tableName);
        
        // 将整行数据转为JSON存储
        syncData.setDataContent(objectMapper.writeValueAsString(externalRow));
        
        // 设置外部更新时间
        Object updatedTime = externalRow.get("updated_time");
        if (updatedTime instanceof Timestamp) {
            syncData.setExternalUpdatedTime(((Timestamp) updatedTime).toLocalDateTime());
        }
        
        return syncData;
    }
    
    /**
     * 更新SyncData
     */
    private void updateSyncDataFromExternal(SyncData syncData, Map<String, Object> externalRow) throws Exception {
        syncData.setName(String.valueOf(externalRow.get("name")));
        syncData.setStatus(String.valueOf(externalRow.get("status")));
        syncData.setDataContent(objectMapper.writeValueAsString(externalRow));
        syncData.setSyncTime(LocalDateTime.now());
        syncData.setUpdatedTime(LocalDateTime.now());
        
        // 更新外部更新时间
        Object updatedTime = externalRow.get("updated_time");
        if (updatedTime instanceof Timestamp) {
            syncData.setExternalUpdatedTime(((Timestamp) updatedTime).toLocalDateTime());
        }
    }
    
    /**
     * 获取最后同步时间
     */
    private LocalDateTime getLastSyncTime(String tableName) {
        LocalDateTime lastSyncTime = syncDataRepository.findLastSyncTimeBySourceTable(tableName);
        if (lastSyncTime == null) {
            // 如果没有同步记录，返回24小时前
            lastSyncTime = LocalDateTime.now().minusHours(24);
        }
        return lastSyncTime;
    }
    
    /**
     * 创建批次
     */
    private <T> List<List<T>> createBatches(List<T> list, int batchSize) {
        List<List<T>> batches = new ArrayList<>();
        for (int i = 0; i < list.size(); i += batchSize) {
            int end = Math.min(list.size(), i + batchSize);
            batches.add(list.subList(i, end));
        }
        return batches;
    }
    
    /**
     * 获取同步统计信息
     */
    public Map<String, Object> getSyncStats(String tableName) {
        Map<String, Object> stats = new HashMap<>();
        stats.put("tableName", tableName);
        stats.put("localCount", syncDataRepository.countBySourceTable(tableName));
        stats.put("lastSyncTime", getLastSyncTime(tableName));
        
        try {
            stats.put("externalCount", externalQueryService.getTableCount(tableName));
        } catch (Exception e) {
            stats.put("externalCount", "查询失败");
        }
        
        return stats;
    }
}

---

// 7. 同步结果类
public class SyncResult {
    private String tableName;
    private int insertCount = 0;
    private int updateCount = 0;
    private int errorCount = 0;
    private List<String> errors = new ArrayList<>();
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    
    public SyncResult(String tableName) {
        this.tableName = tableName;
        this.startTime = LocalDateTime.now();
    }
    
    public void finish() {
        this.endTime = LocalDateTime.now();
    }
    
    public void incrementInsert() { insertCount++; }
    public void incrementUpdate() { updateCount++; }
    public void addError(String error) { 
        errors.add(error); 
        errorCount++; 
    }
    
    // Getters
    public String getTableName() { return tableName; }
    public int getInsertCount() { return insertCount; }
    public int getUpdateCount() { return updateCount; }
    public int getErrorCount() { return errorCount; }
    public List<String> getErrors() { return errors; }
    public LocalDateTime getStartTime() { return startTime; }
    public LocalDateTime getEndTime() { return endTime; }
    
    public long getDurationMs() {
        if (endTime != null) {
            return ChronoUnit.MILLIS.between(startTime, endTime);
        }
        return 0;
    }
}

---

// 8. 定时任务执行器
@Component
@Slf4j
public class ExternalDataSyncTask {
    
    private final DataSyncService dataSyncService;
    private final ExternalDataQueryService externalQueryService;
    
    @Value("${task.external-sync.enabled:true}")
    private boolean taskEnabled;
    
    // 配置需要同步的表名列表
    @Value("${task.external-sync.tables:external_table1,external_table2}")
    private List<String> tablesToSync;
    
    public ExternalDataSyncTask(DataSyncService dataSyncService,
                               ExternalDataQueryService externalQueryService) {
        this.dataSyncService = dataSyncService;
        this.externalQueryService = externalQueryService;
    }
    
    /**
     * 定时同步任务
     */
    @Scheduled(cron = "${task.external-sync.cron:0 */10 * * * ?}")
    public void executeSync() {
        if (!taskEnabled) {
            log.debug("外部数据同步任务已禁用");
            return;
        }
        
        String taskId = UUID.randomUUID().toString().substring(0, 8);
        log.info("开始执行外部数据同步任务, TaskId: {}", taskId);
        
        // 首先测试连接
        if (!externalQueryService.testConnection()) {
            log.error("外部数据库连接失败，跳过同步任务, TaskId: {}", taskId);
            return;
        }
        
        long startTime = System.currentTimeMillis();
        List<SyncResult> results = new ArrayList<>();
        
        try {
            // 遍历所有需要同步的表
            for (String tableName : tablesToSync) {
                try {
                    log.info("开始同步表: {}, TaskId: {}", tableName, taskId);
                    SyncResult result = dataSyncService.syncTableData(tableName.trim());
                    result.finish();
                    results.add(result);
                    
                    log.info("表 {} 同步完成 - 新增: {}, 更新: {}, 失败: {}, 耗时: {}ms", 
                            tableName, result.getInsertCount(), result.getUpdateCount(), 
                            result.getErrorCount(), result.getDurationMs());
                    
                } catch (Exception e) {
                    log.error("同步表 {} 失败, TaskId: {}", tableName, taskId, e);
                    SyncResult errorResult = new SyncResult(tableName);
                    errorResult.addError("同步失败: " + e.getMessage());
                    errorResult.finish();
                    results.add(errorResult);
                }
            }
            
            // 汇总结果
            long endTime = System.currentTimeMillis();
            int totalInsert = results.stream().mapToInt(SyncResult::getInsertCount).sum();
            int totalUpdate = results.stream().mapToInt(SyncResult::getUpdateCount).sum();
            int totalError = results.stream().mapToInt(SyncResult::getErrorCount).sum();
            
            log.info("外部数据同步任务完成, TaskId: {}, 总计 - 新增: {}, 更新: {}, 失败: {}, 总耗时: {}ms", 
                    taskId, totalInsert, totalUpdate, totalError, endTime - startTime);
            
        } catch (Exception e) {
            log.error("外部数据同步任务执行失败, TaskId: {}", taskId, e);
        }
    }
    
    /**
     * 手动执行同步
     */
    public List<SyncResult> manualSync() {
        log.info("手动触发外部数据同步");
        List<SyncResult> results = new ArrayList<>();
        
        for (String tableName : tablesToSync) {
            try {
                SyncResult result = dataSyncService.syncTableData(tableName.trim());
                result.finish();
                results.add(result);
            } catch (Exception e) {
                log.error("手动同步表 {} 失败", tableName, e);
                SyncResult errorResult = new SyncResult(tableName);
                errorResult.addError("同步失败: " + e.getMessage());
                errorResult.finish();
                results.add(errorResult);
            }
        }
        
        return results;
    }
    
    /**
     * 获取同步状态
     */
    public Map<String, Object> getSyncStatus() {
        Map<String, Object> status = new HashMap<>();
        status.put("enabled", taskEnabled);
        status.put("tables", tablesToSync);
        status.put("connectionOk", externalQueryService.testConnection());
        
        List<Map<String, Object>> tableStats = new ArrayList<>();
        for (String tableName : tablesToSync) {
            try {
                Map<String, Object> stats = dataSyncService.getSyncStats(tableName.trim());
                tableStats.add(stats);
            } catch (Exception e) {
                Map<String, Object> errorStats = new HashMap<>();
                errorStats.put("tableName", tableName);
                errorStats.put("error", "获取统计失败: " + e.getMessage());
                tableStats.add(errorStats);
            }
        }
        status.put("tableStats", tableStats);
        
        return status;
    }
}

---

// 9. 控制器接口
@RestController
@RequestMapping("/api/sync")
@Slf4j
public class DataSyncController {
    
    private final ExternalDataSyncTask syncTask;
    
    public DataSyncController(ExternalDataSyncTask syncTask) {
        this.syncTask = syncTask;
    }
    
    /**
     * 获取同步状态
     */
    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getSyncStatus() {
        try {
            Map<String, Object> status = syncTask.getSyncStatus();
            return ResponseEntity.ok(status);
        } catch (Exception e) {
            log.error("获取同步状态失败", e);
            return ResponseEntity.status(500)
                    .body(Map.of("error", "获取状态失败: " + e.getMessage()));
        }
    }
    
    /**
     * 手动触发同步
     */
    @PostMapping("/manual")
    public ResponseEntity<Map<String, Object>> manualSync() {
        try {
            List<SyncResult> results = syncTask.manualSync();
            
            Map<String, Object> response = new HashMap<>();
            response.put("results", results);
            response.put("message", "同步完成");
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("手动同步失败", e);
            return ResponseEntity.status(500)
                    .body(Map.of("error", "同步失败: " + e.getMessage()));
        }
    }
}

---

// 10. 建表SQL
/*
CREATE TABLE sync_data (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    external_id VARCHAR(100) NOT NULL,
    name VARCHAR(200),
    status VARCHAR(50),
    data_content TEXT COMMENT '完整的外部数据JSON',
    source_table VARCHAR(100) NOT NULL COMMENT '来源表名',
    external_updated_time TIMESTAMP COMMENT '外部数据更新时间',
    sync_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '同步时间',
    created_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_external_id_source (external_id, source_table),
    INDEX idx_source_table (source_table),
    INDEX idx_sync_time (sync_time),
    INDEX idx_external_updated_time (external_updated_time)
);
*/
```