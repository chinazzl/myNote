## JVM调优步骤

1. 监控GC的状态
   使用各种JVM工具，查看当前日志，分析当前JVM参数设置，并且分析当前堆内存快照和gc日志，根据实 
   际的各区域内存划分和GC执行时间，觉得是否进行优化；

2. 分析结果，判断是否需要优化
   如果各项参数设置合理，系统没有超时日志出现，GC频率不高，GC耗时不高，那么没有必要进行GC优 
   化；如果GC时间超过1-3秒，或者频繁GC，则必须优化；
   注：如果满足下面的指标，则一般不需要进行GC： 
     Minor GC执行时间不到50ms；
     Minor GC执行不频繁，约10秒一次；
     Full GC执行时间不到1s；

      Full GC执行频率不算频繁，不低于10分钟1次； 

3. 调整GC类型和内存分配
   如果内存分配过大或过小，或者采用的GC收集器比较慢，则应该优先调整这些参数，并且先找1台或几 
   台机器进行beta，然后比较优化过的机器和没有优化的机器的性能对比，并有针对性的做出最后选择；

4. 不断的分析和调整通过不断的试验和试错，分析并找到最合适的参数 

5. 全面应用参数
   如果找到了最合适的参数，则将这些参数应用到所有服务器，并进行后续跟踪。