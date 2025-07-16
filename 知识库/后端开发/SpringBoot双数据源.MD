# 1. application.yml 配置文件
spring:
  datasource:
    # 主数据源
    primary:
      driver-class-name: com.mysql.cj.jdbc.Driver
      url: jdbc:mysql://localhost:3306/primary_db?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Shanghai
      username: root
      password: password
      hikari:
        maximum-pool-size: 20
        minimum-idle: 5
        connection-timeout: 30000
        idle-timeout: 600000
        max-lifetime: 1800000
    
    # 第二个数据源
    secondary:
      driver-class-name: com.mysql.cj.jdbc.Driver
      url: jdbc:mysql://localhost:3306/secondary_db?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Shanghai
      username: root
      password: password
      hikari:
        maximum-pool-size: 20
        minimum-idle: 5
        connection-timeout: 30000
        idle-timeout: 600000
        max-lifetime: 1800000

# MyBatis配置
mybatis:
  mapper-locations: classpath:mapper/sqlMap/Mapper*.xml
  type-aliases-package: com.example.entity
  configuration:
    map-underscore-to-camel-case: true
    cache-enabled: true
    lazy-loading-enabled: true
    multiple-result-sets-enabled: true
    use-column-label: true
    use-generated-keys: false
    auto-mapping-behavior: partial
    auto-mapping-unknown-column-behavior: warning
    default-statement-timeout: 25
    default-fetch-size: 100
    safe-row-bounds-enabled: false
    local-cache-scope: session
    jdbc-type-for-null: other
    lazy-load-trigger-methods: equals,clone,hashCode,toString

# 2. 主数据源配置
@Configuration
@MapperScan(basePackages = "com.example.mapper.primary", sqlSessionTemplateRef = "primarySqlSessionTemplate")
public class PrimaryDataSourceConfig {
    
    @Primary
    @Bean(name = "primaryDataSource")
    @ConfigurationProperties(prefix = "spring.datasource.primary")
    public DataSource primaryDataSource() {
        return DataSourceBuilder.create().build();
    }
    
    @Primary
    @Bean(name = "primarySqlSessionFactory")
    public SqlSessionFactory primarySqlSessionFactory(@Qualifier("primaryDataSource") DataSource dataSource) 
            throws Exception {
        SqlSessionFactoryBean sessionFactory = new SqlSessionFactoryBean();
        sessionFactory.setDataSource(dataSource);
        sessionFactory.setMapperLocations(new PathMatchingResourcePatternResolver()
            .getResources("classpath:mapper/primary/*.xml"));
        
        // 设置MyBatis配置
        org.apache.ibatis.session.Configuration configuration = new org.apache.ibatis.session.Configuration();
        configuration.setMapUnderscoreToCamelCase(true);
        configuration.setCacheEnabled(true);
        configuration.setLazyLoadingEnabled(true);
        sessionFactory.setConfiguration(configuration);
        
        return sessionFactory.getObject();
    }
    
    @Primary
    @Bean(name = "primaryTransactionManager")
    public DataSourceTransactionManager primaryTransactionManager(@Qualifier("primaryDataSource") DataSource dataSource) {
        return new DataSourceTransactionManager(dataSource);
    }
    
    @Primary
    @Bean(name = "primarySqlSessionTemplate")
    public SqlSessionTemplate primarySqlSessionTemplate(@Qualifier("primarySqlSessionFactory") SqlSessionFactory sqlSessionFactory) {
        return new SqlSessionTemplate(sqlSessionFactory);
    }
}

# 3. 第二个数据源配置
@Configuration
@MapperScan(basePackages = "com.example.mapper.secondary", sqlSessionTemplateRef = "secondarySqlSessionTemplate")
public class SecondaryDataSourceConfig {
    
    @Bean(name = "secondaryDataSource")
    @ConfigurationProperties(prefix = "spring.datasource.secondary")
    public DataSource secondaryDataSource() {
        return DataSourceBuilder.create().build();
    }
    
    @Bean(name = "secondarySqlSessionFactory")
    public SqlSessionFactory secondarySqlSessionFactory(@Qualifier("secondaryDataSource") DataSource dataSource) 
            throws Exception {
        SqlSessionFactoryBean sessionFactory = new SqlSessionFactoryBean();
        sessionFactory.setDataSource(dataSource);
        sessionFactory.setMapperLocations(new PathMatchingResourcePatternResolver()
            .getResources("classpath:mapper/secondary/*.xml"));
        
        // 设置MyBatis配置
        org.apache.ibatis.session.Configuration configuration = new org.apache.ibatis.session.Configuration();
        configuration.setMapUnderscoreToCamelCase(true);
        configuration.setCacheEnabled(true);
        configuration.setLazyLoadingEnabled(true);
        sessionFactory.setConfiguration(configuration);
        
        return sessionFactory.getObject();
    }
    
    @Bean(name = "secondaryTransactionManager")
    public DataSourceTransactionManager secondaryTransactionManager(@Qualifier("secondaryDataSource") DataSource dataSource) {
        return new DataSourceTransactionManager(dataSource);
    }
    
    @Bean(name = "secondarySqlSessionTemplate")
    public SqlSessionTemplate secondarySqlSessionTemplate(@Qualifier("secondarySqlSessionFactory") SqlSessionFactory sqlSessionFactory) {
        return new SqlSessionTemplate(sqlSessionFactory);
    }
}

# 4. 实体类
// 主数据源实体
public class User {
    private Long id;
    private String username;
    private String email;
    private String status;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
    
    // 构造函数
    public User() {}
    
    public User(String username, String email, String status) {
        this.username = username;
        this.email = email;
        this.status = status;
        this.createTime = LocalDateTime.now();
        this.updateTime = LocalDateTime.now();
    }
    
    // getter和setter方法
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    
    public LocalDateTime getCreateTime() { return createTime; }
    public void setCreateTime(LocalDateTime createTime) { this.createTime = createTime; }
    
    public LocalDateTime getUpdateTime() { return updateTime; }
    public void setUpdateTime(LocalDateTime updateTime) { this.updateTime = updateTime; }
}

// 第二个数据源实体
public class UserInfo {
    private Long id;
    private String username;
    private String fullName;
    private String department;
    private String position;
    private LocalDateTime lastLogin;
    private String active;
    
    // 构造函数
    public UserInfo() {}
    
    // getter和setter方法
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    
    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }
    
    public String getDepartment() { return department; }
    public void setDepartment(String department) { this.department = department; }
    
    public String getPosition() { return position; }
    public void setPosition(String position) { this.position = position; }
    
    public LocalDateTime getLastLogin() { return lastLogin; }
    public void setLastLogin(LocalDateTime lastLogin) { this.lastLogin = lastLogin; }
    
    public String getActive() { return active; }
    public void setActive(String active) { this.active = active; }
}

# 5. Mapper接口
// 主数据源Mapper
@Mapper
public interface UserMapper {
    
    List<User> selectAll();
    
    User selectByUsername(String username);
    
    List<User> selectByStatus(String status);
    
    int insert(User user);
    
    int insertBatch(List<User> users);
    
    int updateByUsername(User user);
    
    int updateStatusByUsername(@Param("username") String username, @Param("status") String status);
    
    int deleteByUsername(String username);
    
    int deleteBatch(List<String> usernames);
}

// 第二个数据源Mapper
@Mapper
public interface UserInfoMapper {
    
    List<UserInfo> selectAll();
    
    UserInfo selectByUsername(String username);
    
    List<UserInfo> selectByDepartment(String department);
    
    List<UserInfo> selectActiveUsers(@Param("lastLoginAfter") LocalDateTime lastLoginAfter);
    
    List<UserInfo> selectByDepartmentAndActive(@Param("department") String department, 
                                               @Param("active") String active);
}

# 6. Mapper XML文件
-- 主数据源Mapper XML (mapper/primary/UserMapper.xml)
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.example.mapper.primary.UserMapper">
    
    <resultMap id="UserResultMap" type="com.example.entity.User">
        <id property="id" column="id"/>
        <result property="username" column="username"/>
        <result property="email" column="email"/>
        <result property="status" column="status"/>
        <result property="createTime" column="create_time"/>
        <result property="updateTime" column="update_time"/>
    </resultMap>
    
    <select id="selectAll" resultMap="UserResultMap">
        SELECT * FROM user ORDER BY id
    </select>
    
    <select id="selectByUsername" resultMap="UserResultMap">
        SELECT * FROM user WHERE username = #{username}
    </select>
    
    <select id="selectByStatus" resultMap="UserResultMap">
        SELECT * FROM user WHERE status = #{status}
    </select>
    
    <insert id="insert" parameterType="com.example.entity.User" useGeneratedKeys="true" keyProperty="id">
        INSERT INTO user (username, email, status, create_time, update_time)
        VALUES (#{username}, #{email}, #{status}, #{createTime}, #{updateTime})
    </insert>
    
    <insert id="insertBatch" parameterType="java.util.List">
        INSERT INTO user (username, email, status, create_time, update_time)
        VALUES
        <foreach collection="list" item="item" separator=",">
            (#{item.username}, #{item.email}, #{item.status}, #{item.createTime}, #{item.updateTime})
        </foreach>
    </insert>
    
    <update id="updateByUsername">
        UPDATE user SET 
            email = #{email},
            status = #{status},
            update_time = #{updateTime}
        WHERE username = #{username}
    </update>
    
    <update id="updateStatusByUsername">
        UPDATE user SET 
            status = #{status},
            update_time = NOW()
        WHERE username = #{username}
    </update>
    
    <delete id="deleteByUsername">
        DELETE FROM user WHERE username = #{username}
    </delete>
    
    <delete id="deleteBatch">
        DELETE FROM user WHERE username IN
        <foreach collection="list" item="username" open="(" close=")" separator=",">
            #{username}
        </foreach>
    </delete>
    
</mapper>

-- 第二个数据源Mapper XML (mapper/secondary/UserInfoMapper.xml)
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.example.mapper.secondary.UserInfoMapper">
    
    <resultMap id="UserInfoResultMap" type="com.example.entity.UserInfo">
        <id property="id" column="id"/>
        <result property="username" column="username"/>
        <result property="fullName" column="full_name"/>
        <result property="department" column="department"/>
        <result property="position" column="position"/>
        <result property="lastLogin" column="last_login"/>
        <result property="active" column="active"/>
    </resultMap>
    
    <select id="selectAll" resultMap="UserInfoResultMap">
        SELECT * FROM user_info ORDER BY id
    </select>
    
    <select id="selectByUsername" resultMap="UserInfoResultMap">
        SELECT * FROM user_info WHERE username = #{username}
    </select>
    
    <select id="selectByDepartment" resultMap="UserInfoResultMap">
        SELECT * FROM user_info WHERE department = #{department}
    </select>
    
    <select id="selectActiveUsers" resultMap="UserInfoResultMap">
        SELECT * FROM user_info 
        WHERE last_login > #{lastLoginAfter} 
        ORDER BY last_login DESC
    </select>
    
    <select id="selectByDepartmentAndActive" resultMap="UserInfoResultMap">
        SELECT * FROM user_info 
        WHERE department = #{department} AND active = #{active}
        ORDER BY last_login DESC
    </select>
    
</mapper>

# 7. 业务服务类
@Service
public class UserSyncService {
    
    @Autowired
    private UserMapper userMapper;
    
    @Autowired
    private UserInfoMapper userInfoMapper;
    
    /**
     * 根据部门同步用户数据
     */
    @Transactional(value = "primaryTransactionManager", rollbackFor = Exception.class)
    public void syncUsersByDepartment(String department) {
        // 从第二个数据源查询部门用户
        List<UserInfo> userInfoList = userInfoMapper.selectByDepartment(department);
        
        List<User> usersToInsert = new ArrayList<>();
        List<User> usersToUpdate = new ArrayList<>();
        
        for (UserInfo userInfo : userInfoList) {
            User existingUser = userMapper.selectByUsername(userInfo.getUsername());
            
            if (existingUser != null) {
                // 更新现有用户
                existingUser.setEmail(userInfo.getUsername() + "@company.com");
                existingUser.setStatus("active");
                existingUser.setUpdateTime(LocalDateTime.now());
                usersToUpdate.add(existingUser);
            } else {
                // 创建新用户
                User newUser = new User(
                    userInfo.getUsername(),
                    userInfo.getUsername() + "@company.com",
                    "active"
                );
                usersToInsert.add(newUser);
            }
        }
        
        // 批量插入新用户
        if (!usersToInsert.isEmpty()) {
            userMapper.insertBatch(usersToInsert);
        }
        
        // 批量更新用户
        for (User user : usersToUpdate) {
            userMapper.updateByUsername(user);
        }
    }
    
    /**
     * 根据活跃用户更新状态
     */
    @Transactional(value = "primaryTransactionManager", rollbackFor = Exception.class)
    public void updateActiveUserStatus() {
        LocalDateTime thirtyDaysAgo = LocalDateTime.now().minusDays(30);
        
        // 获取活跃用户
        List<UserInfo> activeUsers = userInfoMapper.selectActiveUsers(thirtyDaysAgo);
        
        // 更新活跃用户状态
        for (UserInfo userInfo : activeUsers) {
            userMapper.updateStatusByUsername(userInfo.getUsername(), "active");
        }
        
        // 获取所有用户并设置非活跃用户为inactive
        List<User> allUsers = userMapper.selectAll();
        Set<String> activeUsernames = activeUsers.stream()
            .map(UserInfo::getUsername)
            .collect(Collectors.toSet());
        
        for (User user : allUsers) {
            if (!activeUsernames.contains(user.getUsername())) {
                userMapper.updateStatusByUsername(user.getUsername(), "inactive");
            }
        }
    }
    
    /**
     * 清理过期用户
     */
    @Transactional(value = "primaryTransactionManager", rollbackFor = Exception.class)
    public void cleanupObsoleteUsers() {
        // 获取第二个数据源中的所有用户名
        List<UserInfo> allUserInfos = userInfoMapper.selectAll();
        Set<String> validUsernames = allUserInfos.stream()
            .map(UserInfo::getUsername)
            .collect(Collectors.toSet());
        
        // 获取主数据源中需要删除的用户
        List<User> allUsers = userMapper.selectAll();
        List<String> usernamesToDelete = allUsers.stream()
            .filter(user -> !validUsernames.contains(user.getUsername()))
            .map(User::getUsername)
            .collect(Collectors.toList());
        
        // 批量删除
        if (!usernamesToDelete.isEmpty()) {
            userMapper.deleteBatch(usernamesToDelete);
        }
    }
    
    /**
     * 根据第二个数据源的活跃状态同步数据
     */
    @Transactional(value = "primaryTransactionManager", rollbackFor = Exception.class)
    public void syncActiveUsersByDepartment(String department) {
        // 只同步活跃用户
        List<UserInfo> activeUserInfos = userInfoMapper.selectByDepartmentAndActive(department, "Y");
        
        List<User> usersToProcess = new ArrayList<>();
        
        for (UserInfo userInfo : activeUserInfos) {
            User existingUser = userMapper.selectByUsername(userInfo.getUsername());
            
            if (existingUser != null) {
                userMapper.updateStatusByUsername(userInfo.getUsername(), "active");
            } else {
                User newUser = new User(
                    userInfo.getUsername(),
                    userInfo.getUsername() + "@company.com",
                    "active"
                );
                usersToProcess.add(newUser);
            }
        }
        
        if (!usersToProcess.isEmpty()) {
            userMapper.insertBatch(usersToProcess);
        }
    }
}

# 8. 控制器
@RestController
@RequestMapping("/api/user-sync")
public class UserSyncController {
    
    @Autowired
    private UserSyncService userSyncService;
    
    @PostMapping("/sync-department")
    public ResponseEntity<String> syncUsersByDepartment(@RequestParam String department) {
        try {
            userSyncService.syncUsersByDepartment(department);
            return ResponseEntity.ok("部门用户同步成功");
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body("同步失败: " + e.getMessage());
        }
    }
    
    @PostMapping("/update-active")
    public ResponseEntity<String> updateActiveUserStatus() {
        try {
            userSyncService.updateActiveUserStatus();
            return ResponseEntity.ok("活跃用户状态更新成功");
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body("更新失败: " + e.getMessage());
        }
    }
    
    @DeleteMapping("/cleanup")
    public ResponseEntity<String> cleanupObsoleteUsers() {
        try {
            userSyncService.cleanupObsoleteUsers();
            return ResponseEntity.ok("过期用户清理成功");
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body("清理失败: " + e.getMessage());
        }
    }
    
    @PostMapping("/sync-active-department")
    public ResponseEntity<String> syncActiveUsersByDepartment(@RequestParam String department) {
        try {
            userSyncService.syncActiveUsersByDepartment(department);
            return ResponseEntity.ok("活跃用户同步成功");
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body("同步失败: " + e.getMessage());
        }
    }
}

# 9. 所需依赖 (pom.xml)
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
        <groupId>org.mybatis.spring.boot</groupId>
        <artifactId>mybatis-spring-boot-starter</artifactId>
        <version>2.3.0</version>
    </dependency>
    <dependency>
        <groupId>mysql</groupId>
        <artifactId>mysql-connector-java</artifactId>
        <scope>runtime</scope>
    </dependency>
    <dependency>
        <groupId>com.zaxxer</groupId>
        <artifactId>HikariCP</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-jdbc</artifactId>
    </dependency>
</dependencies>