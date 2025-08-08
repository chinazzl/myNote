import java.util.*;
import java.util.concurrent.*;
import java.util.stream.Collectors;

public class ParallelTimeoutExample {

    private static final ExecutorService executor = Executors.newFixedThreadPool(10);
    private static final ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(1);

    public static void main(String[] args) {
        List<Integer> successList = new ArrayList<>();
        List<Integer> timeoutList = new ArrayList<>();

        List<CompletableFuture<Void>> futures = new ArrayList<>();

        for (int i = 0; i < 10; i++) {
            final int taskId = i;

            // 核心：任务执行 + 超时自动取消
            CompletableFuture<Integer> taskFuture = CompletableFuture.supplyAsync(() -> getData(taskId), executor);
            CompletableFuture<Integer> timeoutFuture = failAfter(5, TimeUnit.SECONDS);

            CompletableFuture<Integer> resultFuture = taskFuture.applyToEither(timeoutFuture, r -> r);

            CompletableFuture<Void> handledFuture = resultFuture.thenAccept(result -> {
                if (result != null) {
                    successList.add(result);
                }
            }).exceptionally(ex -> {
                timeoutList.add(taskId);
                System.err.println("任务 " + taskId + " 超时或异常: " + ex.getMessage());
                taskFuture.cancel(true); // 取消原任务
                return null;
            });

            futures.add(handledFuture);
        }

        // 等待所有任务完成
        CompletableFuture.allOf(futures.toArray(new CompletableFuture[0])).join();

        // 批量入库
        batchInsert(successList);

        // 超时任务处理
        handleTimeout(timeoutList);

        executor.shutdown();
        scheduler.shutdown();
    }

    // 模拟任务
    private static Integer getData(int id) {
        int sleep = ThreadLocalRandom.current().nextInt(1, 8);
        try {
            System.out.println(Thread.currentThread().getName() + " 开始任务 " + id + "，耗时 " + sleep + " 秒");
            TimeUnit.SECONDS.sleep(sleep);
            System.out.println(Thread.currentThread().getName() + " 完成任务 " + id);
        } catch (InterruptedException e) {
            System.out.println("任务 " + id + " 被取消");
            Thread.currentThread().interrupt();
        }
        return id;
    }

    // 批量入库
    private static void batchInsert(List<Integer> list) {
        System.out.println("✅ 成功任务入库: " + list.stream().filter(Objects::nonNull).collect(Collectors.toList()));
    }

    // 超时任务处理
    private static void handleTimeout(List<Integer> timeoutList) {
        System.out.println("⏰ 超时任务: " + timeoutList);
    }

    // 创建超时 Future
    private static <T> CompletableFuture<T> failAfter(long timeout, TimeUnit unit) {
        CompletableFuture<T> promise = new CompletableFuture<>();
        scheduler.schedule(() -> promise.completeExceptionally(new TimeoutException("超时 " + timeout + " " + unit)), timeout, unit);
        return promise;
    }
}
