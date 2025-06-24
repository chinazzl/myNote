# SpringSecurity最新版本的AuthenticationManager如何声明

```java

// 方式1: 在SecurityFilterChain配置中声明（推荐）
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Autowired
    private UserDetailsService userDetailsService;

    @Autowired
    private PasswordEncoder passwordEncoder;

    /**
     * 方式1: 通过HttpSecurity获取AuthenticationManager
     * 这是Spring Security 6推荐的方式
     */
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/auth/**").permitAll()
                        .requestMatchers("/api/public/**").permitAll()
                        .anyRequest().authenticated()
                )
                .formLogin(form -> form
                        .loginPage("/login")
                        .permitAll()
                )
                .logout(logout -> logout.permitAll())
                .build();
    }

    /**
     * 方式1: 声明AuthenticationManager Bean
     * 使用AuthenticationConfiguration获取
     */
    @Bean
    public AuthenticationManager authenticationManager(
            AuthenticationConfiguration authConfig) throws Exception {
        return authConfig.getAuthenticationManager();
    }

    /**
     * 自定义UserDetailsService
     */
    @Bean
    public UserDetailsService userDetailsService() {
        return new CustomUserDetailsService();
    }

    /**
     * 密码编码器
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}

// 方式2: 手动构建AuthenticationManager
@Configuration
@EnableWebSecurity
public class ManualSecurityConfig {

    @Autowired
    private UserDetailsService userDetailsService;

    @Autowired
    private PasswordEncoder passwordEncoder;

    /**
     * 方式2: 手动构建AuthenticationManager
     * 当需要更细粒度控制时使用
     */
    @Bean
    public AuthenticationManager authenticationManager() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();
        authProvider.setUserDetailsService(userDetailsService);
        authProvider.setPasswordEncoder(passwordEncoder);

        ProviderManager providerManager = new ProviderManager(authProvider);
        providerManager.setEraseCredentialsAfterAuthentication(false);
        
        return providerManager;
    }

    /**
     * 多认证提供者的情况
     */
    @Bean
    public AuthenticationManager multiProviderAuthenticationManager() {
        // DAO认证提供者
        DaoAuthenticationProvider daoProvider = new DaoAuthenticationProvider();
        daoProvider.setUserDetailsService(userDetailsService);
        daoProvider.setPasswordEncoder(passwordEncoder);

        // LDAP认证提供者（示例）
        LdapAuthenticationProvider ldapProvider = createLdapProvider();

        // 自定义认证提供者
        CustomAuthenticationProvider customProvider = new CustomAuthenticationProvider();

        return new ProviderManager(Arrays.asList(
                daoProvider, 
                ldapProvider, 
                customProvider
        ));
    }

    private LdapAuthenticationProvider createLdapProvider() {
        // LDAP配置示例
        return new LdapAuthenticationProvider(
                new BindAuthenticator(createContextSource()),
                new DefaultLdapAuthoritiesPopulator(createContextSource(), "ou=groups")
        );
    }

    private LdapContextSource createContextSource() {
        LdapContextSource contextSource = new LdapContextSource();
        contextSource.setUrl("ldap://localhost:389");
        contextSource.setBase("dc=example,dc=com");
        contextSource.setUserDn("cn=admin,dc=example,dc=com");
        contextSource.setPassword("admin");
        return contextSource;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/auth/**").permitAll()
                        .anyRequest().authenticated()
                )
                .authenticationManager(authenticationManager()) // 使用自定义的AuthenticationManager
                .build();
    }
}

// 方式3: 在自定义过滤器中使用
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    @Override
    protected void doFilterInternal(HttpServletRequest request, 
                                  HttpServletResponse response, 
                                  FilterChain filterChain) throws ServletException, IOException {
        
        String token = extractTokenFromRequest(request);
        
        if (token != null && jwtTokenProvider.validateToken(token)) {
            try {
                // 创建认证对象
                UsernamePasswordAuthenticationToken authToken = 
                    jwtTokenProvider.getAuthentication(token);
                
                // 使用AuthenticationManager进行认证
                Authentication authentication = authenticationManager.authenticate(authToken);
                
                // 设置到安全上下文
                SecurityContextHolder.getContext().setAuthentication(authentication);
                
            } catch (AuthenticationException e) {
                SecurityContextHolder.clearContext();
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                return;
            }
        }
        
        filterChain.doFilter(request, response);
    }

    private String extractTokenFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (bearerToken != null && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }
}

// 方式4: 在Controller中直接使用
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    /**
     * 用户登录
     */
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest loginRequest) {
        try {
            // 创建认证令牌
            UsernamePasswordAuthenticationToken authToken = 
                new UsernamePasswordAuthenticationToken(
                    loginRequest.getUsername(), 
                    loginRequest.getPassword()
                );

            // 使用AuthenticationManager进行认证
            Authentication authentication = authenticationManager.authenticate(authToken);

            // 生成JWT令牌
            String jwtToken = jwtTokenProvider.generateToken(authentication);

            return ResponseEntity.ok(new JwtResponse(jwtToken));

        } catch (BadCredentialsException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new ApiResponse(false, "用户名或密码错误"));
        } catch (AuthenticationException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new ApiResponse(false, "认证失败"));
        }
    }

    /**
     * 修改密码
     */
    @PostMapping("/change-password")
    public ResponseEntity<?> changePassword(@RequestBody ChangePasswordRequest request) {
        try {
            // 验证旧密码
            UsernamePasswordAuthenticationToken authToken = 
                new UsernamePasswordAuthenticationToken(
                    request.getUsername(), 
                    request.getOldPassword()
                );

            authenticationManager.authenticate(authToken);

            // 旧密码验证通过，更新新密码
            // ... 密码更新逻辑

            return ResponseEntity.ok(new ApiResponse(true, "密码修改成功"));

        } catch (AuthenticationException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(new ApiResponse(false, "原密码错误"));
        }
    }
}

// 方式5: 自定义AuthenticationProvider
@Component
public class CustomAuthenticationProvider implements AuthenticationProvider {

    @Autowired
    private UserDetailsService userDetailsService;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    public Authentication authenticate(Authentication authentication) throws AuthenticationException {
        String username = authentication.getName();
        String password = authentication.getCredentials().toString();

        // 加载用户详情
        UserDetails userDetails = userDetailsService.loadUserByUsername(username);

        // 验证密码
        if (!passwordEncoder.matches(password, userDetails.getPassword())) {
            throw new BadCredentialsException("密码错误");
        }

        // 检查账户状态
        if (!userDetails.isAccountNonLocked()) {
            throw new AccountExpiredException("账户已锁定");
        }

        if (!userDetails.isEnabled()) {
            throw new DisabledException("账户已禁用");
        }

        // 返回认证成功的Authentication对象
        return new UsernamePasswordAuthenticationToken(
                userDetails, 
                password, 
                userDetails.getAuthorities()
        );
    }

    @Override
    public boolean supports(Class<?> authentication) {
        return UsernamePasswordAuthenticationToken.class.isAssignableFrom(authentication);
    }
}

// 自定义UserDetailsService实现
@Service
public class CustomUserDetailsService implements UserDetailsService {

    @Autowired
    private UserRepository userRepository;

    @Override
    @Transactional(readOnly = true)
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("用户不存在: " + username));

        return UserPrincipal.create(user);
    }
}

// UserPrincipal实现
public class UserPrincipal implements UserDetails {
    private Long id;
    private String username;
    private String password;
    private Collection<? extends GrantedAuthority> authorities;

    public UserPrincipal(Long id, String username, String password, 
                        Collection<? extends GrantedAuthority> authorities) {
        this.id = id;
        this.username = username;
        this.password = password;
        this.authorities = authorities;
    }

    public static UserPrincipal create(User user) {
        List<GrantedAuthority> authorities = user.getRoles().stream()
                .map(role -> new SimpleGrantedAuthority("ROLE_" + role.getName()))
                .collect(Collectors.toList());

        return new UserPrincipal(
                user.getId(),
                user.getUsername(),
                user.getPassword(),
                authorities
        );
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorities;
    }

    @Override
    public String getPassword() {
        return password;
    }

    @Override
    public String getUsername() {
        return username;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return true;
    }

    public Long getId() {
        return id;
    }
}

// DTO类
@Data
public class LoginRequest {
    private String username;
    private String password;
}

@Data
public class ChangePasswordRequest {
    private String username;
    private String oldPassword;
    private String newPassword;
}

@Data
@AllArgsConstructor
public class JwtResponse {
    private String token;
    private String type = "Bearer";
    
    public JwtResponse(String token) {
        this.token = token;
    }
}

@Data
@AllArgsConstructor
public class ApiResponse {
    private Boolean success;
    private String message;
}

```